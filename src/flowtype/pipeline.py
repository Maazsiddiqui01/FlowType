from __future__ import annotations

import importlib
import logging
import threading
import time
from dataclasses import dataclass
from typing import Callable

from flowtype.audio import AudioRecorder, CapturedAudio
from flowtype.cleanup import TextCleaner
from flowtype.config import AppConfig
from flowtype.output import OutputDelivery
from flowtype.transcriber import Transcriber
from flowtype.shortcuts import ShortcutManager, normalize_hotkey_token, parse_hotkey

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
    mode_name: str
    provider: str
    model: str


StatusCallback = Callable[[str, str], None]
AudioLevelCallback = Callable[[float], None]
ResultCallback = Callable[[DictationResult], None]


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
        self.logger = logger or logging.getLogger("flowtype.pipeline")
        self._state_lock = threading.RLock()
        self._shortcut_manager: ShortcutManager | None = None
        self._processing_thread: threading.Thread | None = None
        self._status = "starting"
        self._last_final_text = ""
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
            if self._status == "recording" or self._status == "processing":
                return

            self._cancel_requested = False
            try:
                self.recorder.audio_level_callback = self.audio_level_callback
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
                self._set_status("ready", "Dictation cancelled")
                return

            if captured_audio.duration_seconds * 1000 < self.config.audio.min_duration_ms:
                self.logger.info("Ignored dictation shorter than minimum duration")
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
            elif self._status in ("ready", "stopped"):
                self._handle_hold_press()
                
    def _handle_cancel(self) -> None:
        with self._state_lock:
            if self._status == "recording":
                self._cancel_requested = True
                self._handle_hold_release()
            elif self._status == "processing":
                # Mark cancel intent for when background workers sync
                self._cancel_requested = True
                self.logger.info("Cancel requested during processing (best effort)")

    def _handle_repaste_last(self) -> None:
        if self._last_final_text:
            self.logger.info("Re-pasting last dictation")
            self._set_status("pasting", "Pasting previous result...")
            self.output.deliver(self._last_final_text)
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
            raw_text = transcription.text.strip()
            if not raw_text:
                self.logger.info("No speech detected in recording")
                self._set_status("ready", "No speech detected")
                return

            self._set_status("cleaning", "Polishing transcript...")
            cleanup_start = time.perf_counter()
            cleanup_result = self.cleaner.clean(raw_text)
            metrics.cleanup_seconds = time.perf_counter() - cleanup_start

            final_text = cleanup_result.text.strip() or raw_text
            self._last_final_text = final_text
            
            if self._cancel_requested:
                self.logger.info("Delivery cancelled before paste")
                self._set_status("ready", "Dictation cancelled")
                return

            self._set_status("pasting", "Pasting into the active app...")
            delivery_start = time.perf_counter()
            delivery_result = self.output.deliver(final_text)
            metrics.delivery_seconds = time.perf_counter() - delivery_start
            self._emit_result(
                raw_text=raw_text,
                final_text=final_text,
                used_fallback=cleanup_result.used_fallback,
                copied=delivery_result.copied,
                pasted=delivery_result.pasted,
            )

            self.logger.info(
                "Dictation complete | chars=%s | copied=%s | pasted=%s | "
                "recording=%.2fs transcription=%.2fs cleanup=%.2fs delivery=%.2fs | "
                "whisper_device=%s cleanup_fallback=%s",
                len(final_text),
                delivery_result.copied,
                delivery_result.pasted,
                metrics.recording_seconds,
                metrics.transcription_seconds,
                metrics.cleanup_seconds,
                metrics.delivery_seconds,
                transcription.used_device or "unknown",
                cleanup_result.used_fallback,
            )
            self._set_status("ready", "Ready")
        except Exception as exc:
            self.logger.exception("Dictation failed: %s", exc)
            self._set_status("error", "Last dictation failed. Check the log.")

    def _set_status(self, status: str, detail: str) -> None:
        with self._state_lock:
            self._status = status
        cb = self.status_callback
        if cb is not None:
            cb(status, detail)

    def _emit_result(
        self,
        raw_text: str,
        final_text: str,
        used_fallback: bool,
        copied: bool,
        pasted: bool,
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
                mode_name=self.config.cleanup.mode_name,
                provider=self.config.cleanup.provider,
                model=self.config.cleanup.model,
            )
        )
