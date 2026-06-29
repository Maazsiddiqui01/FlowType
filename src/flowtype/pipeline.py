from __future__ import annotations

import logging
import os
import queue
import threading
import time
from dataclasses import dataclass, field
from typing import Callable

from flowtype.audio import AudioRecorder, CapturedAudio, list_orphan_recordings, read_wav
from flowtype.catalog import mode_instructions, resolve_mode_for_app
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
    target_process: str = ""


@dataclass(slots=True)
class _Job:
    """A single captured take queued for transcription + cleanup + delivery.

    Each take carries its own foreground-window target (snapshot at capture time)
    and its own cancel flag, so overlapping dictations never cross-contaminate.
    """

    audio: CapturedAudio | None
    target: ForegroundWindowSnapshot | None
    was_truncated: bool
    file_path: str | None = None
    copy_only: bool = False  # recovery takes are copied, never auto-pasted
    recovered: bool = False
    cancel: threading.Event = field(default_factory=threading.Event)


# Sentinel pushed onto the job queue to shut the worker down cleanly.
_SHUTDOWN = object()


StatusCallback = Callable[[str, str], None]
AudioLevelCallback = Callable[[float], None]
ResultCallback = Callable[[DictationResult], None]
NotificationCallback = Callable[[str, str], None]


_STAGE_DETAIL = {
    "transcribing": "Transcribing locally...",
    "cleaning": "Polishing transcript...",
    "pasting": "Pasting into the active app...",
}


class DictationPipeline:
    """Coordinates capture -> transcription -> cleanup -> delivery.

    Design goals (owner mandate: "if someone records it must ALWAYS record"):

    * Capture is decoupled from processing. Pressing record while a previous take
      is still transcribing/cleaning/pasting starts a NEW capture immediately; the
      captured audio is queued to a single serialized worker. A trigger is only ever
      refused if a capture is *literally* already in progress on the one recorder.
    * All shared state is guarded by a single re-entrant lock, and the cancel flag is
      per-job, so the worker and hotkey threads never race.
    * Status / result / notification callbacks are invoked from worker/hotkey threads;
      the UI controller is responsible for marshalling them onto the GUI thread.
    """

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

        self._jobs: "queue.Queue[object]" = queue.Queue()
        self._worker_thread: threading.Thread | None = None
        self._jobs_in_flight = 0

        self._lifecycle = "starting"  # starting | ready | stopped
        self._capture_active = False
        self._capture_cancel = False
        self._worker_stage = ""  # "", transcribing, cleaning, pasting
        self._active_job: _Job | None = None
        self._error_detail = ""
        self._presented_status = ""

        self._pending_delivery_target: ForegroundWindowSnapshot | None = None
        self._last_final_text = ""
        self._last_delivery_target: ForegroundWindowSnapshot | None = None

    # ── lifecycle ────────────────────────────────────────────────────────────
    @property
    def status(self) -> str:
        with self._state_lock:
            status, _ = self._compute_status_locked()
            return status

    def start(self) -> None:
        with self._state_lock:
            self._lifecycle = "ready"
            self._error_detail = ""
            if self._worker_thread is None or not self._worker_thread.is_alive():
                self._worker_thread = threading.Thread(
                    target=self._worker_loop, name="dictation-worker", daemon=True
                )
                self._worker_thread.start()

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
        self._refresh_status()

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

        with self._state_lock:
            self._pending_delivery_target = None
            worker = self._worker_thread
            self._worker_thread = None
            self._lifecycle = "stopped"

        if self.recorder.is_recording():
            try:
                self.recorder.stop()
            except Exception:
                pass

        if worker is not None and worker.is_alive():
            self._jobs.put(_SHUTDOWN)
            worker.join(timeout=2.0)

        self._emit_status("stopped", "FlowType stopped")

    # ── capture (always allowed) ─────────────────────────────────────────────
    def _handle_hold_press(self) -> None:
        with self._state_lock:
            if self._capture_active:
                # A capture is already running on the single recorder; this is the
                # normal "already recording" case, not a dropped take.
                self.logger.debug("Record trigger ignored: a capture is already active")
                return

            self._capture_cancel = False
            self._error_detail = ""
            try:
                self.recorder.audio_level_callback = self.audio_level_callback
                self._pending_delivery_target = snapshot_foreground_window()
                self.recorder.start()
            except Exception as exc:
                self.recorder.audio_level_callback = None
                self._pending_delivery_target = None
                self._error_detail = self._describe_capture_error(exc)
                self.logger.exception("Failed to start recording: %s", exc)
                self._notify(self._error_detail, "error")
                self._refresh_status()
                return

            self._capture_active = True
            self.logger.info("Recording started")

        self._refresh_status()

    def _handle_hold_release(self) -> None:
        with self._state_lock:
            if not self._capture_active:
                return

            self._capture_active = False
            cancel = self._capture_cancel
            self._capture_cancel = False
            target = self._pending_delivery_target
            self._pending_delivery_target = None

            try:
                self.recorder.audio_level_callback = None
                captured_audio = self.recorder.stop()
            except Exception as exc:
                self.logger.exception("Failed to stop recording: %s", exc)
                self._error_detail = "Could not finish recording. Check the log."
                self._notify(self._error_detail, "error")
                self._refresh_status()
                return

        if cancel:
            self.logger.info("Recording cancelled, discarding audio")
            self._delete_recording_file(captured_audio.file_path)
            self._refresh_status()
            return

        if captured_audio.duration_seconds * 1000 < self.config.audio.min_duration_ms:
            self.logger.info("Ignored dictation shorter than minimum duration")
            self._delete_recording_file(captured_audio.file_path)
            self._refresh_status()
            return

        if captured_audio.was_truncated:
            self.logger.warning(
                "Recording hit the %ss safety limit and was truncated",
                self.config.audio.max_duration_seconds,
            )

        job = _Job(
            audio=captured_audio,
            target=target,
            was_truncated=captured_audio.was_truncated,
            file_path=captured_audio.file_path,
        )
        with self._state_lock:
            self._jobs_in_flight += 1
        self._jobs.put(job)
        self._refresh_status()

    def recover_orphans(self) -> int:
        """Re-process journaled takes left behind by a crash. Recovered takes are
        copied to the clipboard (never auto-pasted, since the original target is gone)
        and added to History, so a crash never silently loses a recording."""
        recordings_dir = self.config.audio.recordings_dir
        orphans = list_orphan_recordings(recordings_dir)
        if not orphans:
            return 0

        enqueued = 0
        for path in orphans:
            # Decode lazily on the worker thread (read_wav does blocking I/O + resample);
            # doing it here would block whoever calls recover_orphans (the GUI thread).
            job = _Job(
                audio=None,
                target=None,
                was_truncated=False,
                file_path=str(path),
                copy_only=True,
                recovered=True,
            )
            with self._state_lock:
                self._jobs_in_flight += 1
            self._jobs.put(job)
            enqueued += 1

        if enqueued:
            self.logger.info("Recovering %s orphaned recording(s) from a previous session", enqueued)
            self._notify(
                f"Recovering {enqueued} unfinished recording{'s' if enqueued != 1 else ''} "
                "from a previous session. The cleaned text will appear and be copied to your clipboard.",
                "info",
            )
            self._refresh_status()
        return enqueued

    def _handle_toggle(self) -> None:
        with self._state_lock:
            capturing = self._capture_active
        if capturing:
            self._handle_hold_release()
        else:
            self._handle_hold_press()

    def _handle_cancel(self) -> None:
        release = False
        active_job: _Job | None = None
        with self._state_lock:
            if self._capture_active:
                self._capture_cancel = True
                release = True
            else:
                active_job = self._active_job

        if release:
            self._handle_hold_release()
            return

        if active_job is not None:
            active_job.cancel.set()
            self.logger.info("Cancel requested while processing")
            self._notify("Processing will stop before paste and keep the text safe.", "info")

    def _handle_repaste_last(self) -> None:
        with self._state_lock:
            text = self._last_final_text
            target = self._last_delivery_target
        if not text:
            self.logger.info("No prior dictation to re-paste")
            return

        self.logger.info("Re-pasting last dictation")
        self._emit_status("pasting", "Pasting previous result...")
        try:
            self.output.deliver(text, target=target)
        except Exception as exc:
            self.logger.exception("Re-paste failed: %s", exc)
            with self._state_lock:
                self._error_detail = "Could not re-paste the last result. Check the log."
            self._notify("Could not re-paste the last result. Check the log.", "error")
            self._refresh_status()
            return
        self._refresh_status()

    # ── worker ───────────────────────────────────────────────────────────────
    def _worker_loop(self) -> None:
        while True:
            job = self._jobs.get()
            try:
                if job is _SHUTDOWN:
                    return
                self._consume_job(job)
            finally:
                self._jobs.task_done()

    def _consume_job(self, job: object) -> None:
        """Process a single queued take with full error handling + status finalization.

        Split out from the worker loop (which owns only the queue get/task_done) so it
        is synchronously testable and so an exception in one take never kills the worker.
        """
        if not isinstance(job, _Job):
            return
        with self._state_lock:
            self._active_job = job
        try:
            self._process_job(job)
            # Processing completed (delivered/copied/cancelled-safe/no-speech): the
            # journaled file is no longer needed. On a hard exception we keep it so the
            # take can be recovered on next launch.
            self._delete_job_file(job)
        except Exception as exc:
            self.logger.exception("Dictation failed: %s", exc)
            message = str(exc).strip() or "Last dictation failed. Check the log."
            if len(message) > 96:
                message = "Last dictation failed. Check the log."
            with self._state_lock:
                self._error_detail = message
        finally:
            with self._state_lock:
                self._active_job = None
                self._worker_stage = ""
                self._jobs_in_flight = max(0, self._jobs_in_flight - 1)
                if self._lifecycle == "starting":
                    self._lifecycle = "ready"
            self._refresh_status()

    def _process_job(self, job: _Job) -> None:
        audio = job.audio
        if audio is None and job.file_path:
            # Recovery take: decode the journaled WAV here (on the worker), not on the
            # caller's thread. If it is unreadable, drop the file so it cannot loop.
            try:
                audio = read_wav(job.file_path, target_rate=self.config.audio.sample_rate, logger=self.logger)
            except Exception as exc:
                self.logger.warning("Could not read recovered recording %s: %s; removing", job.file_path, exc)
                self._delete_recording_file(job.file_path)
                return
        if audio is None:
            return

        metrics = PipelineMetrics(recording_seconds=audio.duration_seconds)

        self._set_stage("transcribing")
        transcription_start = time.perf_counter()
        transcription = self.transcriber.transcribe(audio)
        metrics.transcription_seconds = time.perf_counter() - transcription_start
        self._pin_cpu_if_requested()
        self._emit_runtime_notice()

        raw_text = transcription.text.strip()
        if not raw_text:
            self.logger.info("No speech detected in recording")
            self._notify("No speech detected.", "info")
            return

        self._set_stage("cleaning")
        effective_mode, mode_prompt = self._resolve_mode(job)
        cleanup_start = time.perf_counter()
        try:
            cleanup_result = self.cleaner.clean(raw_text, mode_prompt=mode_prompt)
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
        with self._state_lock:
            self._last_final_text = final_text
            self._last_delivery_target = job.target
            self._error_detail = ""

        truncated_note = (
            " Recording reached the maximum length and was capped; the captured part was kept."
            if job.was_truncated
            else ""
        )

        if job.copy_only:
            # Recovery take: copy, never paste (the original target is long gone).
            copied = False
            try:
                copied = self.output.copy_to_clipboard(final_text)
            except Exception as exc:
                self.logger.exception("Failed to copy recovered dictation: %s", exc)
            note = (
                "Recovered from a previous session and copied to your clipboard."
                if copied
                else "Recovered from a previous session, but FlowType could not copy it."
            )
            self._emit_result(
                raw_text=raw_text,
                final_text=final_text,
                used_fallback=cleanup_result.used_fallback,
                copied=copied,
                pasted=False,
                delivery_state="copied_only" if copied else "failed",
                delivery_note=note + truncated_note,
                target_title="",
                mode_name=effective_mode,
                target_process=(job.target.process_name if job.target is not None else ""),
            )
            return

        if job.cancel.is_set():
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
                )
                + truncated_note,
                target_title=job.target.title if job.target is not None else "",
                mode_name=effective_mode,
                target_process=(job.target.process_name if job.target is not None else ""),
            )
            return

        self._set_stage("pasting")
        delivery_start = time.perf_counter()
        delivery_result = self.output.deliver(final_text, target=job.target)
        metrics.delivery_seconds = time.perf_counter() - delivery_start
        self._emit_result(
            raw_text=raw_text,
            final_text=final_text,
            used_fallback=cleanup_result.used_fallback,
            copied=delivery_result.copied,
            pasted=delivery_result.pasted,
            delivery_state=delivery_result.delivery_state,
            delivery_note=(delivery_result.failure_reason + truncated_note).strip(),
            target_title=delivery_result.target_title,
            mode_name=effective_mode,
            target_process=(job.target.process_name if job.target is not None else ""),
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

    # ── status plumbing ──────────────────────────────────────────────────────
    def _delete_job_file(self, job: _Job) -> None:
        self._delete_recording_file(job.file_path)

    def _delete_recording_file(self, file_path: str | None) -> None:
        if not file_path:
            return
        try:
            os.remove(file_path)
        except OSError:
            pass

    def _set_stage(self, stage: str) -> None:
        with self._state_lock:
            self._worker_stage = stage
        self._refresh_status()

    def _compute_status_locked(self) -> tuple[str, str]:
        if self._lifecycle == "stopped":
            return ("stopped", "FlowType stopped")
        if self._capture_active:
            return ("recording", "Recording...")
        if self._jobs_in_flight > 0:
            stage = self._worker_stage or "transcribing"
            return (stage, _STAGE_DETAIL.get(stage, "Working..."))
        if self._error_detail:
            return ("error", self._error_detail)
        if self._lifecycle == "starting":
            return ("starting", "Starting FlowType...")
        return ("ready", "Ready")

    def _refresh_status(self) -> None:
        # Emit under the lock so callback order matches _presented_status order (two
        # threads refreshing concurrently could otherwise deliver status out of order).
        # The callback only posts a queued Qt signal (or logs), so it never re-enters
        # pipeline code; the RLock is reentrant anyway.
        with self._state_lock:
            status, detail = self._compute_status_locked()
            if status == self._presented_status and status not in {"error"}:
                # Avoid spamming identical transitions, but always re-emit errors.
                return
            self._presented_status = status
            cb = self.status_callback
            if cb is not None:
                cb(status, detail)

    def _emit_status(self, status: str, detail: str) -> None:
        with self._state_lock:
            self._presented_status = status
            cb = self.status_callback
            if cb is not None:
                cb(status, detail)

    def _notify(self, message: str, tone: str = "info") -> None:
        cb = self.notification_callback
        if cb is not None and message.strip():
            cb(message, tone)

    def _describe_capture_error(self, exc: Exception) -> str:
        text = str(exc).lower()
        if "permission" in text or "denied" in text or "access is denied" in text:
            return "Microphone access is blocked. Allow microphone access in Windows settings, then try again."
        if "busy" in text or "in use" in text or "unavailable" in text or "already" in text:
            return "The microphone is in use by another app. Close it and try again."
        if (
            "no default" in text
            or "no input" in text
            or "no such device" in text
            or "invalid device" in text
            or "found no" in text
            or "no device" in text
        ):
            return "No microphone was found. Connect an input device and try again."
        return "Could not start recording. Check microphone access and try again."

    def _resolve_mode(self, job: _Job) -> tuple[str, str]:
        """Pick the cleanup Mode for this take. With per-app rules configured, the
        foreground app at capture time selects the Mode; otherwise the active Mode is
        used. The global custom prompt only applies to the active Mode."""
        active = self.config.mode.active
        target = job.target
        if target is not None and self.config.mode.app_rules:
            effective = resolve_mode_for_app(
                self.config.mode.app_rules,
                getattr(target, "process_name", ""),
                getattr(target, "title", ""),
                active,
            )
        else:
            effective = active
        custom = self.config.mode.custom_prompt if effective == active else ""
        return effective, mode_instructions(effective, custom)

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
        mode_name: str | None = None,
        target_process: str = "",
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
                mode_name=mode_name or self.config.cleanup.mode_name,
                provider=self.config.cleanup.provider,
                model=self.config.cleanup.model,
                target_process=target_process,
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
