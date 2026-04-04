from __future__ import annotations

import importlib
import logging
import threading
import time
from dataclasses import dataclass

import numpy as np

from flowtype.audio import CapturedAudio
from flowtype.config import TranscriptionConfig


class TranscriberError(RuntimeError):
    """Raised when Faster-Whisper cannot load or transcribe audio."""


@dataclass(slots=True, frozen=True)
class TranscriptionResult:
    text: str
    language: str
    inference_seconds: float
    used_device: str
    used_compute_type: str


class Transcriber:
    def __init__(self, settings: TranscriptionConfig, logger: logging.Logger | None = None) -> None:
        self.settings = settings
        self.logger = logger or logging.getLogger("flowtype.transcriber")
        self._model = None
        self._whisper_module = None
        self._lock = threading.Lock()
        self._used_device = ""
        self._used_compute_type = ""
        self._disabled_devices: set[str] = set()
        self._persist_cpu_requested = False
        self._runtime_notice = ""
        self._warmup_inference_validated = False

    @property
    def used_device(self) -> str:
        return self._used_device

    @property
    def used_compute_type(self) -> str:
        return self._used_compute_type

    def warm_up(self) -> None:
        self._ensure_model_loaded()
        self._validate_backend_inference()

    def consume_persist_cpu_requested(self) -> bool:
        requested = self._persist_cpu_requested
        self._persist_cpu_requested = False
        return requested

    def consume_runtime_notice(self) -> str:
        notice = self._runtime_notice
        self._runtime_notice = ""
        return notice

    def transcribe(self, captured_audio: CapturedAudio) -> TranscriptionResult:
        requested_language = self._requested_language()
        if captured_audio.is_empty:
            return TranscriptionResult(
                text="",
                language=requested_language,
                inference_seconds=0.0,
                used_device=self._used_device,
                used_compute_type=self._used_compute_type,
            )

        model = self._ensure_model_loaded()
        if captured_audio.sample_rate != 16000:
            raise TranscriberError(
                f"unsupported sample rate {captured_audio.sample_rate}; expected 16000"
            )
        audio = captured_audio.audio_array
        start = time.perf_counter()
        try:
            segments, info = self._run_model_transcribe(model, audio, requested_language)
            text = " ".join(segment.text.strip() for segment in segments if segment.text.strip()).strip()
        except Exception as exc:  # pragma: no cover - depends on model/runtime
            if self._should_retry_on_cpu(exc):
                self.logger.warning(
                    "Whisper inference failed on %s (%s); retrying on CPU: %s",
                    self._used_device or "unknown",
                    self._used_compute_type or "unknown",
                    exc,
                )
                self._persist_cpu_requested = True
                self._runtime_notice = (
                    "CUDA transcription failed on this machine. FlowType switched to CPU mode for reliability."
                )
                self._disable_device("cuda")
                return self.transcribe(captured_audio)
            raise TranscriberError(f"transcription failed: {exc}") from exc

        elapsed = time.perf_counter() - start
        detected_language = getattr(info, "language", requested_language or "")
        return TranscriptionResult(
            text=text,
            language=detected_language,
            inference_seconds=elapsed,
            used_device=self._used_device,
            used_compute_type=self._used_compute_type,
        )

    def _requested_language(self) -> str:
        value = (self.settings.language or "").strip().lower()
        if value in {"", "auto"}:
            return ""
        return value

    def _ensure_model_loaded(self):
        if self._model is not None:
            return self._model

        with self._lock:
            if self._model is not None:
                return self._model

            whisper_module = self._load_whisper_module()
            self.settings.model_cache_dir.mkdir(parents=True, exist_ok=True)

            for device in self._candidate_devices():
                compute_type = self._resolve_compute_type(device)
                try:
                    self.logger.info(
                        "Loading Faster-Whisper model %s on %s (%s)",
                        self.settings.model_size,
                        device,
                        compute_type,
                    )
                    self._model = whisper_module.WhisperModel(
                        self.settings.model_size,
                        device=device,
                        compute_type=compute_type,
                        download_root=str(self.settings.model_cache_dir),
                    )
                    self._used_device = device
                    self._used_compute_type = compute_type
                    return self._model
                except Exception as exc:  # pragma: no cover - hardware/runtime dependent
                    self.logger.warning(
                        "Failed to load Whisper model on %s (%s): %s",
                        device,
                        compute_type,
                        exc,
                    )

            raise TranscriberError("unable to load Faster-Whisper model on CUDA or CPU")

    def _load_whisper_module(self):
        if self._whisper_module is None:
            try:
                self._whisper_module = importlib.import_module("faster_whisper")
            except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
                raise TranscriberError(
                    "faster-whisper is not installed. Run `python -m pip install -e .` first."
                ) from exc
        return self._whisper_module

    def _candidate_devices(self) -> list[str]:
        if self.settings.device == "auto":
            candidates = ["cuda", "cpu"]
        else:
            candidates = [self.settings.device]
        filtered = [device for device in candidates if device not in self._disabled_devices]
        return filtered or ["cpu"]

    def _resolve_compute_type(self, device: str) -> str:
        if self.settings.compute_type != "auto":
            return self.settings.compute_type
        return "float16" if device == "cuda" else "int8"

    def _should_retry_on_cpu(self, exc: Exception) -> bool:
        return (
            self.settings.device == "auto"
            and self._used_device == "cuda"
            and "cpu" not in self._disabled_devices
        )

    def _disable_device(self, device: str) -> None:
        with self._lock:
            self._disabled_devices.add(device)
            self._model = None
            self._used_device = ""
            self._used_compute_type = ""
            self._warmup_inference_validated = False

    def _run_model_transcribe(
        self,
        model,
        audio: np.ndarray,
        requested_language: str,
        *,
        vad_filter_override: bool | None = None,
    ):
        return model.transcribe(
            audio,
            language=requested_language or None,
            beam_size=self.settings.beam_size,
            vad_filter=self.settings.vad_filter if vad_filter_override is None else vad_filter_override,
            condition_on_previous_text=False,
        )

    def _validate_backend_inference(self) -> None:
        if self._warmup_inference_validated:
            return
        if self._used_device != "cuda":
            self._warmup_inference_validated = True
            return

        probe_audio = np.zeros(16000, dtype=np.float32)
        model = self._ensure_model_loaded()
        try:
            self._run_model_transcribe(
                model,
                probe_audio,
                self._requested_language(),
                vad_filter_override=False,
            )
            self._warmup_inference_validated = True
        except Exception as exc:  # pragma: no cover - hardware/runtime dependent
            if self._should_retry_on_cpu(exc):
                self.logger.warning(
                    "Warm-up inference failed on %s (%s); retrying on CPU: %s",
                    self._used_device or "unknown",
                    self._used_compute_type or "unknown",
                    exc,
                )
                self._persist_cpu_requested = True
                self._runtime_notice = (
                    "CUDA transcription failed on this machine. FlowType switched to CPU mode for reliability."
                )
                self._disable_device("cuda")
                self._ensure_model_loaded()
                self._warmup_inference_validated = True
                return
            raise TranscriberError(f"warm-up inference failed: {exc}") from exc
