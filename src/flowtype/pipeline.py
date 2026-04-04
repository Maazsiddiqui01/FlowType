from __future__ import annotations

import importlib
import logging
import threading
import time
from dataclasses import dataclass
from typing import Callable

from flowtype.audio import AudioRecorder, CapturedAudio
from flowtype.cleanup import CleanupResult, TextCleaner
from flowtype.config import AppConfig, load_config_data, save_config_data
from flowtype.output import OutputDelivery
from flowtype.transcriber import Transcriber
from flowtype.shortcuts import ShortcutManager, normalize_hotkey_token, parse_hotkey
from flowtype.windows import ForegroundWindowSnapshot, snapshot_foreground_window

@dataclass(slots=True)
class PipelineMetrics:
    recording_seconds: float = 0.0
    transcription_seconds: float = 0.0
    cleanup_seconds: float = 0.0
    delivery_seconds: float = 0.0


@dataclass(slots=True, frozen=True)
class DictationResult:
    raw_text: str
    final_text: str
    used_fallback: bool
    copied: bool
    pasted: bool
    delivery_state: str
    delivery_note: str
    target_title: str
    mode_name: str
    provider: str
    model: str


StatusCallback = Callable[[str, str], None]
AudioLevelCallback = Callable[[float], None]
ResultCallback = Callable[[DictationResult], None]
NotificationCallback = Callable[[str, str], None]


class DictationPipeline:
    def __init__(
        self,
        config: AppConfig,
        recorder: AudioRecorder,
        transcriber: Transcriber,
        cleaner: TextCleaner,
        output: OutputDelivery,
        status_callback: StatusCallback | None = None,
        audio_level_callback: AudioLevelCallback | None = None,
        result_callback: ResultCallback | None = None,
        notification_callback: NotificationCallback | None = None,
        logger: logging.Logger | None = None,
    ) -> None:
        self.config = config
        self.recorder = recorder
        self.transcriber = transcriber
        self.cleaner = cleaner
        self.output = output
        self.status_callback = status_callback
        self.audio_level_callback = audio_level_callback
        self.result_callback = result_callback
        self.notification_callback = notification_callback
        self.logger = logger or logging.getLogger("flowtype.pipeline")
        self._state_lock = threading.RLock()
        self._shortcut_manager: ShortcutManager | None = None
        self._processing_thread: threading.Thread | None = None
        self._status = "starting"
        self._last_final_text = ""
        self._last_delivery_target: ForegroundWindowSnapshot | None = None
        self._pending_delivery_target: ForegroundWindowSnapshot | None = None
        self._cancel_requested = False

    @property
    def status(self) -> str:
        with self._state_lock:
            return self._status

    def start(self) -> None:
        self._set_status("ready", "FlowType Ready")
        self._shortcut_manager = ShortcutManager(logger=self.logger.getChild("shortcuts"))
        
        if self.config.shortcuts.hold_to_talk:
            self._shortcut_manager.register_hold(
                self.config.shortcuts.hold_to_talk,
                on_press=self._handle_hold_press,
                on_release=self._handle_hold_release,
            )
            
        if self.config.shortcuts.toggle_recording:
            self._shortcut_manager.register_action(
                self.config.shortcuts.toggle_recording,
                on_trigger=self._handle_toggle,
            )
            
        if self.config.shortcuts.cancel_recording:
            self._shortcut_manager.register_action(
                self.config.shortcuts.cancel_recording,
                on_trigger=self._handle_cancel,
            )
            
        if self.config.shortcuts.repaste_last:
            self._shortcut_manager.register_action(
                self.config.shortcuts.repaste_last,
                on_trigger=self._handle_repaste_last,
            )
            
        self._shortcut_manager.start()
        self.logger.info("Shortcut listener started")

    def start_recording(self) -> None:
        self._handle_hold_press()

    def finish_recording(self) -> None:
        self._handle_hold_release()

    def toggle_recording(self) -> None:
        self._handle_toggle()

    def cancel_recording(self) -> None:
        self._handle_cancel()

    def repaste_last(self) -> None:
        self._handle_repaste_last()

    def stop(self) -> None:
        if self._shortcut_manager is not None:
            self._shortcut_manager.stop()
            self._shortcut_manager = None
        self._pending_delivery_target = None

        if self.recorder.is_recording():
            try:
                self.recorder.stop()
            except Exception:
                pass

        t = self._processing_thread
        if t is not None and t.is_alive():
            t.join(timeout=2.0)

        self._set_status("stopped", "FlowType stopped")

    def _handle_hold_press(self) -> None:
        with self._state_lock:
            if self._status in {"recording", "transcribing", "cleaning", "pasting"}:
                self.logger.info("Ignoring record trigger while busy | status=%s", self._status)
                self._notify("Still processing the previous dictation.", "info")
                return

            self._cancel_requested = False
            try:
                self.recorder.audio_level_callback = self.audio_level_callback
                self._pending_delivery_target = snapshot_foreground_window()
                self.recorder.start()
            except Exception as exc:
                self.logger.exception("Failed to start recording: %s", exc)
                self._set_status("error", "Could not start recording. Check microphone access.")
                return

            self._set_status("recording", "Recording...")
            self.logger.info("Recording started")

    def _handle_hold_release(self) -> None:
        with self._state_lock:
            if self._status != "recording":
                return

            try:
                self.recorder.audio_level_callback = None
                captured_audio = self.recorder.stop()
            except Exception as exc:
                self.logger.exception("Failed to stop recording: %s", exc)
                self._set_status("error", "Could not finish recording. Check the log.")
                return
            
            if self._cancel_requested:
                self.logger.info("Recording cancelled, discarding audio")
                self._pending_delivery_target = None
                self._set_status("ready", "Dictation cancelled")
                return

            if captured_audio.duration_seconds * 1000 < self.config.audio.min_duration_ms:
                self.logger.info("Ignored dictation shorter than minimum duration")
                self._pending_delivery_target = None
                self._set_status("ready", "Tap ignored")
                return

            self._set_status("processing", "Transcribing...")
            self._processing_thread = threading.Thread(
                target=self._process_capture,
                args=(captured_audio,),
                name="dictation-worker",
                daemon=True,
            )
            self._processing_thread.start()

    def _handle_toggle(self) -> None:
        with self._state_lock:
            if self._status == "recording":
                self._handle_hold_release()
            elif self._status in ("ready", "stopped", "error"):
                self._handle_hold_press()
            else:
                self.logger.info("Ignoring toggle trigger while busy | status=%s", self._status)
                self._notify("Still processing the previous dictation.", "info")
                
    def _handle_cancel(self) -> None:
        with self._state_lock:
            if self._status == "recording":
                self._cancel_requested = True
                self._handle_hold_release()
            elif self._status in {"transcribing", "cleaning", "pasting"}:
                self._cancel_requested = True
                self.logger.info("Cancel requested while busy | status=%s", self._status)
                self._notify("Processing will stop before paste and keep the text safe.", "info")

    def _handle_repaste_last(self) -> None:
        if self._last_final_text:
            self.logger.info("Re-pasting last dictation")
            self._set_status("pasting", "Pasting previous result...")
            try:
                self.output.deliver(self._last_final_text, target=self._last_delivery_target)
            except Exception as exc:
                self.logger.exception("Re-paste failed: %s", exc)
                self._set_status("error", "Could not re-paste the last result. Check the log.")
                return
            self._set_status("ready", "Ready")
        else:
            self.logger.info("No prior dictation to re-paste")

    def _process_capture(self, captured_audio: CapturedAudio) -> None:
        metrics = PipelineMetrics(recording_seconds=captured_audio.duration_seconds)
        if captured_audio.was_truncated:
            self.logger.warning(
                "Recording hit the %ss safety limit and was truncated",
                self.config.audio.max_duration_seconds,
            )

        try:
            self._set_status("transcribing", "Transcribing locally...")
            transcription_start = time.perf_counter()
            transcription = self.transcriber.transcribe(captured_audio)
            metrics.transcription_seconds = time.perf_counter() - transcription_start
            self._pin_cpu_if_requested()
            self._emit_runtime_notice()
            raw_text = transcription.text.strip()
            if not raw_text:
                self.logger.info("No speech detected in recording")
                self._pending_delivery_target = None
                self._set_status("ready", "No speech detected")
                return

            self._set_status("cleaning", "Polishing transcript...")
            cleanup_start = time.perf_counter()
            try:
                cleanup_result = self.cleaner.clean(raw_text)
            except Exception as exc:
                self.logger.exception("Cleanup failed unexpectedly, using raw transcript: %s", exc)
                cleanup_result = CleanupResult(
                    text=raw_text,
                    used_fallback=True,
                    attempts=0,
                    provider=self.config.cleanup.provider,
                )
            metrics.cleanup_seconds = time.perf_counter() - cleanup_start

            final_text = cleanup_result.text.strip() or raw_text
            self._last_final_text = final_text
            delivery_target = self._pending_delivery_target
            self._last_delivery_target = delivery_target
            
            if self._cancel_requested:
                self.logger.info("Processing cancelled before paste; preserving transcript")
                copied = False
                try:
                    copied = self.output.copy_to_clipboard(final_text)
                except Exception as exc:
                    self.logger.exception("Failed to preserve cancelled dictation in clipboard: %s", exc)
                self._emit_result(
                    raw_text=raw_text,
                    final_text=final_text,
                    used_fallback=cleanup_result.used_fallback,
                    copied=copied,
                    pasted=False,
                    delivery_state="copied_only" if copied else "failed",
                    delivery_note=(
                        "Processing was canceled before paste. FlowType kept the result in the clipboard."
                        if copied
                        else "Processing was canceled before paste and FlowType could not copy the result."
                    ),
                    target_title=delivery_target.title if delivery_target is not None else "",
                )
                self._pending_delivery_target = None
                self._set_status("ready", "Processing canceled")
                return

            self._set_status("pasting", "Pasting into the active app...")
            delivery_start = time.perf_counter()
            delivery_result = self.output.deliver(final_text, target=delivery_target)
            metrics.delivery_seconds = time.perf_counter() - delivery_start
            self._pending_delivery_target = None
            self._emit_result(
                raw_text=raw_text,
                final_text=final_text,
                used_fallback=cleanup_result.used_fallback,
                copied=delivery_result.copied,
                pasted=delivery_result.pasted,
                delivery_state=delivery_result.delivery_state,
                delivery_note=delivery_result.failure_reason,
                target_title=delivery_result.target_title,
            )

            self.logger.info(
                "Dictation complete | chars=%s | copied=%s | pasted=%s | delivery=%s | target=%s | "
                "recording=%.2fs transcription=%.2fs cleanup=%.2fs delivery=%.2fs | "
                "whisper_device=%s cleanup_fallback=%s",
                len(final_text),
                delivery_result.copied,
                delivery_result.pasted,
                delivery_result.delivery_state,
                delivery_result.target_title or "<none>",
                metrics.recording_seconds,
                metrics.transcription_seconds,
                metrics.cleanup_seconds,
                metrics.delivery_seconds,
                transcription.used_device or "unknown",
                cleanup_result.used_fallback,
            )
            self._set_status("ready", "Ready")
        except Exception as exc:
            self._pending_delivery_target = None
            self.logger.exception("Dictation failed: %s", exc)
            message = str(exc).strip() or "Last dictation failed. Check the log."
            if len(message) > 96:
                message = "Last dictation failed. Check the log."
            self._set_status("error", message)

    def _set_status(self, status: str, detail: str) -> None:
        with self._state_lock:
            self._status = status
        cb = self.status_callback
        if cb is not None:
            cb(status, detail)

    def _notify(self, message: str, tone: str = "info") -> None:
        cb = self.notification_callback
        if cb is not None and message.strip():
            cb(message, tone)

    def _emit_result(
        self,
        raw_text: str,
        final_text: str,
        used_fallback: bool,
        copied: bool,
        pasted: bool,
        delivery_state: str,
        delivery_note: str,
        target_title: str,
    ) -> None:
        cb = self.result_callback
        if cb is None:
            return
        cb(
            DictationResult(
                raw_text=raw_text,
                final_text=final_text,
                used_fallback=used_fallback,
                copied=copied,
                pasted=pasted,
                delivery_state=delivery_state,
                delivery_note=delivery_note,
                target_title=target_title,
                mode_name=self.config.cleanup.mode_name,
                provider=self.config.cleanup.provider,
                model=self.config.cleanup.model,
            )
        )

    def _pin_cpu_if_requested(self) -> None:
        consume = getattr(self.transcriber, "consume_persist_cpu_requested", None)
        if consume is None or not consume():
            return
        try:
            config_path, data = load_config_data(self.config.config_path)
            data.setdefault("transcription", {})
            if str(data["transcription"].get("device", "auto")).strip().lower() == "auto":
                data["transcription"]["device"] = "cpu"
                data["transcription"]["compute_type"] = "int8"
                save_config_data(config_path, data)
                self.logger.warning("Pinned transcription to CPU after CUDA inference failure")
        except Exception as exc:
            self.logger.exception("Failed to persist CPU transcription fallback: %s", exc)

    def _emit_runtime_notice(self) -> None:
        consume = getattr(self.transcriber, "consume_runtime_notice", None)
        if consume is None:
            return
        notice = consume()
        if notice:
            self._notify(notice, "info")
