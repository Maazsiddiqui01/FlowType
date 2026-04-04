from __future__ import annotations

import argparse
import logging
import threading
import time
from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys

from flowtype.audio import AudioRecorder
from flowtype.cleanup import TextCleaner
from flowtype.config import AppConfig, load_config, load_config_data, save_config_data
from flowtype.logger import configure_logging
from flowtype.output import OutputDelivery
from flowtype.pipeline import DictationPipeline
from flowtype.startup import build_launch_command, sync_launch_at_login
from flowtype.transcriber import Transcriber

try:
    from flowtype.ui.app import run_ui_mode
except ImportError:
    run_ui_mode = None
from flowtype.tray import TrayController


@dataclass(slots=True)
class RuntimeComponents:
    recorder: AudioRecorder
    transcriber: Transcriber
    cleaner: TextCleaner
    output: OutputDelivery


class FlowTypeRuntime:
    def __init__(self, config: AppConfig, logger: logging.Logger) -> None:
        self.config = config
        self.logger = logger
        self.tray = TrayController(
            config_path=config.config_path,
            log_path=config.general.log_file,
            open_settings_callback=self.open_settings,
            quit_callback=self.stop,
            logger=logger.getChild("tray"),
        )
        self._lock = threading.RLock()
        self._stop_event = threading.Event()
        self._config_mtime_ns = self._read_config_mtime()
        self._watcher_thread: threading.Thread | None = None
        self._pipeline_active = False
        self._onboarding_prompted = False
        self.components = build_components(config, logger)
        self.pipeline = self._build_pipeline(config, self.components)
        self.tray.bind_pipeline(self.pipeline)

    def run(self) -> int:
        self.tray.run(on_ready=self._on_tray_ready)
        return 0

    def stop(self) -> None:
        self._stop_event.set()
        with self._lock:
            pipeline = self.pipeline
            self.pipeline = None
            self._pipeline_active = False
        if pipeline is not None:
            pipeline.stop()

    def open_settings(self) -> None:
        launch_ui_process(self.config.config_path, settings=True)

    def _on_tray_ready(self) -> None:
        with self._lock:
            pipeline = self.pipeline
        if pipeline is not None and not self._pipeline_active:
            pipeline.start()
            self._pipeline_active = True
        sync_launch_at_login(self.config)
        start_background_warmup(self.components.transcriber, self.logger, self.config.config_path)
        self._start_config_watcher()
        if self._needs_onboarding() and not self._onboarding_prompted:
            self._onboarding_prompted = True
            self.open_settings()
        self.tray.set_status("ready", "Ready")

    def _start_config_watcher(self) -> None:
        t = self._watcher_thread
        if t is not None and t.is_alive():
            return
        self._watcher_thread = threading.Thread(
            target=self._watch_config_loop,
            name="config-watcher",
            daemon=True,
        )
        self._watcher_thread.start()

    def _watch_config_loop(self) -> None:
        while not self._stop_event.wait(1.0):
            current_mtime = self._read_config_mtime()
            if current_mtime and current_mtime != self._config_mtime_ns:
                try:
                    self.reload_config()
                except Exception as exc:
                    self.logger.exception("Config reload failed: %s", exc)

    def reload_config(self) -> None:
        self.logger.info("Detected config change; reloading FlowType runtime")
        new_config = load_config(self.config.config_path)
        configure_logging(new_config.general)
        log_runtime_config(new_config, self.logger)
        new_components = build_components(new_config, self.logger)
        new_pipeline = self._build_pipeline(new_config, new_components)
        sync_launch_at_login(new_config)

        with self._lock:
            old_pipeline = self.pipeline
            should_start = self._pipeline_active
            self.config = new_config
            self.components = new_components
            self.pipeline = new_pipeline
            self._config_mtime_ns = self._read_config_mtime()
            self.tray.update_paths(new_config.config_path, new_config.general.log_file)
            self.tray.bind_pipeline(new_pipeline)

        if old_pipeline is not None:
            old_pipeline.stop()

        if should_start:
            new_pipeline.start()
            self.tray.set_status("ready", "Settings reloaded")

        start_background_warmup(new_components.transcriber, self.logger, new_config.config_path)

    def _build_pipeline(self, config: AppConfig, components: RuntimeComponents) -> DictationPipeline:
        return DictationPipeline(
            config=config,
            recorder=components.recorder,
            transcriber=components.transcriber,
            cleaner=components.cleaner,
            output=components.output,
            status_callback=self.tray.set_status,
            logger=self.logger.getChild("pipeline"),
        )

    def _needs_onboarding(self) -> bool:
        return self.config.cleanup.provider != "none" and not self.config.cleanup.api_key

    def _read_config_mtime(self) -> int:
        try:
            return self.config.config_path.stat().st_mtime_ns
        except FileNotFoundError:
            return 0


def cli(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="FlowType desktop dictation app")
    parser.add_argument("--config", help="Path to config.toml")
    parser.add_argument("--no-tray", action="store_true", help="Run in console mode")
    parser.add_argument("--settings", action="store_true", help="Open the FlowType desktop shell")
    parser.add_argument("--background", action="store_true", help="Start hidden in the tray")
    parser.add_argument(
        "--warmup-only",
        action="store_true",
        help="Load the Faster-Whisper model and then exit",
    )
    args = parser.parse_args(argv)

    if args.settings:
        if run_ui_mode is None:
            logger = logging.getLogger("flowtype")
            logger.error("UI mode is unavailable; --settings cannot open the desktop shell.")
            return 1

    config = load_config(args.config)
    logger = configure_logging(config.general)
    logger.info("FlowType starting")
    log_runtime_config(config, logger)

    components = build_components(config, logger)
    transcriber = components.transcriber

    if args.warmup_only:
        transcriber.warm_up()
        _apply_transcriber_runtime_fallbacks(transcriber, logger, config.config_path)
        logger.info(
            "Warm-up finished using device=%s compute_type=%s",
            transcriber.used_device or "unknown",
            transcriber.used_compute_type or "unknown",
        )
        return 0

    if args.no_tray or run_ui_mode is None:
        return run_console_mode(config, logger)

    activation_message = "settings" if args.settings else ("background" if args.background else "show")
    return run_ui_mode(
        config,
        logger,
        components,
        lambda: start_background_warmup(transcriber, logger, config.config_path),
        start_hidden=bool(args.background and not args.settings),
        activation_message=activation_message,
    )


def build_components(config: AppConfig, logger: logging.Logger) -> RuntimeComponents:
    return RuntimeComponents(
        recorder=AudioRecorder(config.audio, logger=logger.getChild("audio")),
        transcriber=Transcriber(config.transcription, logger=logger.getChild("transcriber")),
        cleaner=TextCleaner(config.cleanup, logger=logger.getChild("cleanup")),
        output=OutputDelivery(config.output, logger=logger.getChild("output")),
    )


def run_console_mode(config: AppConfig, logger: logging.Logger) -> int:
    components = build_components(config, logger)
    pipeline = DictationPipeline(
        config=config,
        recorder=components.recorder,
        transcriber=components.transcriber,
        cleaner=components.cleaner,
        output=components.output,
        status_callback=lambda status, detail: logger.info("Status changed: %s | %s", status, detail),
        logger=logger.getChild("pipeline"),
    )

    if config.cleanup.provider != "none" and not config.cleanup.api_key:
        launch_ui_process(config.config_path, settings=True)

    start_background_warmup(components.transcriber, logger, config.config_path)
    pipeline.start()
    logger.info("Console mode started; press Ctrl+C to exit")
    try:
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received; shutting down")
    finally:
        pipeline.stop()
    return 0


def log_runtime_config(config: AppConfig, logger: logging.Logger) -> None:
    logger.info("Config path: %s", config.config_path)
    logger.info("Log file: %s", config.general.log_file)
    logger.info("Model cache: %s", config.transcription.model_cache_dir)
    logger.info("Cleanup provider: %s", config.cleanup.provider)
    logger.info("Paste mode: %s", config.output.paste_method)
    if config.cleanup.provider != "none" and not config.cleanup.api_key:
        logger.warning(
            "No cleanup API key configured for provider %s; raw transcripts will be delivered",
            config.cleanup.provider,
        )
    if config.output.paste_method == "clipboard_only":
        logger.warning("Paste mode is clipboard_only; FlowType will not press Ctrl+V automatically")


def start_background_warmup(transcriber: Transcriber, logger: logging.Logger, config_path: Path) -> None:
    def warm_up() -> None:
        try:
            transcriber.warm_up()
            _apply_transcriber_runtime_fallbacks(transcriber, logger, config_path)
            logger.info(
                "Transcriber warm-up finished using device=%s compute_type=%s",
                transcriber.used_device or "unknown",
                transcriber.used_compute_type or "unknown",
            )
        except Exception as exc:
            logger.warning("Transcriber warm-up failed: %s", exc)

    thread = threading.Thread(target=warm_up, name="transcriber-warmup", daemon=True)
    thread.start()


def _apply_transcriber_runtime_fallbacks(transcriber: Transcriber, logger: logging.Logger, config_path: Path) -> None:
    notice = getattr(transcriber, "consume_runtime_notice", lambda: "")()
    if notice:
        logger.warning(notice)

    consume = getattr(transcriber, "consume_persist_cpu_requested", None)
    if consume is None or not consume():
        return

    try:
        loaded_path, data = load_config_data(config_path)
        data.setdefault("transcription", {})
        if str(data["transcription"].get("device", "auto")).strip().lower() == "auto":
            data["transcription"]["device"] = "cpu"
            data["transcription"]["compute_type"] = "int8"
            save_config_data(loaded_path, data)
            logger.warning("Persisted CPU transcription fallback after warm-up inference failure")
    except Exception as exc:
        logger.exception("Failed to persist CPU fallback after warm-up: %s", exc)


def build_ui_launch_command(config_path: Path, *, settings: bool = False, background: bool = False) -> list[str]:
    command = build_launch_command(config_path, background=background)
    if settings:
        command.insert(-2, "--settings")
    return command


def launch_ui_process(config_path: Path, *, settings: bool = False, background: bool = False) -> None:
    subprocess.Popen(build_ui_launch_command(config_path, settings=settings, background=background), close_fds=True)
