from __future__ import annotations

import importlib
import logging
import sys
import threading
from dataclasses import dataclass

import numpy as np
import types
from typing import Callable, Any

from flowtype.config import AudioConfig


class AudioRecorderError(RuntimeError):
    """Raised when audio capture cannot start or stop cleanly."""


@dataclass(slots=True, frozen=True)
class CapturedAudio:
    audio_array: np.ndarray
    sample_rate: int
    duration_seconds: float
    was_truncated: bool
    frame_count: int

    @property
    def is_empty(self) -> bool:
        return self.frame_count == 0 or self.audio_array.size == 0


class AudioRecorder:
    def __init__(self, settings: AudioConfig, logger: logging.Logger | None = None, audio_level_callback: Callable[[float], None] | None = None) -> None:
        self.settings = settings
        self.logger = logger or logging.getLogger("flowtype.audio")
        self.audio_level_callback = audio_level_callback
        self._lock = threading.RLock()
        self._stream: Any = None
        self._sounddevice: types.ModuleType | None = None
        self._chunks: list[np.ndarray] = []
        self._recorded_frames = 0
        self._is_recording = False
        self._was_truncated = False
        self._status_messages: list[str] = []
        self._actual_sample_rate = self.settings.sample_rate
        self._max_frames = self.settings.sample_rate * self.settings.max_duration_seconds

    def start(self) -> None:
        with self._lock:
            if self._is_recording:
                raise AudioRecorderError("recording is already active")

            sounddevice = self._load_sounddevice()
            self._chunks = []
            self._recorded_frames = 0
            self._was_truncated = False
            self._status_messages = []
            # Reset per-recording derived state so a prior native-rate fallback does
            # not leak its sample rate / frame cap into the next (normal) recording.
            self._actual_sample_rate = self.settings.sample_rate
            self._max_frames = self.settings.sample_rate * self.settings.max_duration_seconds

            def callback(indata, frames, _time_info, status) -> None:
                del frames
                if status:
                    self._status_messages.append(str(status))

                with self._lock:
                    if not self._is_recording:
                        return

                    remaining = self._max_frames - self._recorded_frames
                    if remaining <= 0:
                        self._was_truncated = True
                        raise sounddevice.CallbackStop()

                    clipped = indata[:remaining].copy()
                    self._chunks.append(clipped)
                    self._recorded_frames += len(clipped)

                    cb = self.audio_level_callback
                    if cb is not None:
                        float_data = clipped.astype(np.float32) / 32768.0
                        peak = float(np.max(np.abs(float_data)))
                        rms = float(np.sqrt(np.mean(float_data**2)))
                        # Compress and boost mic energy so the HUD reacts visibly to normal speech.
                        boosted = max(rms * 10.5, peak * 3.2)
                        normalized = max(0.0, min(1.0, (boosted - 0.015) / 0.75))
                        cb(normalized)

                    if len(clipped) < len(indata):
                        self._was_truncated = True
                        raise sounddevice.CallbackStop()

            try:
                self._stream = sounddevice.InputStream(
                    samplerate=self.settings.sample_rate,
                    channels=self.settings.channels,
                    dtype=self.settings.dtype,
                    blocksize=0,
                    callback=callback,
                )
                self._actual_sample_rate = self.settings.sample_rate
                self._is_recording = True
                self._stream.start()
            except Exception as exc:  # pragma: no cover - depends on local audio stack
                try:
                    device_info = sounddevice.query_devices(None, 'input')
                    native_rate = int(device_info['default_samplerate'])
                    self._max_frames = int(native_rate * self.settings.max_duration_seconds)
                    
                    self._stream = sounddevice.InputStream(
                        samplerate=native_rate,
                        channels=self.settings.channels,
                        dtype=self.settings.dtype,
                        blocksize=0,
                        callback=callback,
                    )
                    self._actual_sample_rate = native_rate
                    self._is_recording = True
                    self._stream.start()
                    self.logger.info("Fell back to native sample rate %dHz instead of requested %dHz", native_rate, self.settings.sample_rate)
                except Exception as fallback_exc:
                    self._stream = None
                    self._is_recording = False
                    raise AudioRecorderError(f"failed to start audio capture even with native rate fallback: {fallback_exc}") from fallback_exc

    def stop(self) -> CapturedAudio:
        with self._lock:
            stream = self._stream
            self._stream = None
            self._is_recording = False
            chunks = self._chunks
            recorded_frames = self._recorded_frames
            was_truncated = self._was_truncated
            status_messages = self._status_messages
            actual_sample_rate = self._actual_sample_rate
            self._chunks = []
            self._recorded_frames = 0
            self._was_truncated = False
            self._status_messages = []

        if stream is not None:
            try:
                stream.stop()
            except Exception:
                pass
            try:
                stream.close()
            except Exception:
                pass

        if status_messages:
            self.logger.warning("Audio stream reported issues: %s", "; ".join(status_messages))

        if recorded_frames == 0:
            return CapturedAudio(
                audio_array=np.array([], dtype=np.float32),
                sample_rate=self.settings.sample_rate,
                duration_seconds=0.0,
                was_truncated=was_truncated,
                frame_count=0,
            )

        audio_array = np.concatenate(chunks, axis=0)
        if audio_array.ndim > 1:
            audio_array = audio_array.mean(axis=1)

        if actual_sample_rate != self.settings.sample_rate:
            audio_array = _resample(audio_array, actual_sample_rate, self.settings.sample_rate, self.logger)
            recorded_frames = len(audio_array)

        float_audio = audio_array.astype(np.float32) / 32768.0
        duration_seconds = recorded_frames / float(self.settings.sample_rate)

        return CapturedAudio(
            audio_array=float_audio,
            sample_rate=self.settings.sample_rate,
            duration_seconds=duration_seconds,
            was_truncated=was_truncated,
            frame_count=recorded_frames,
        )

    def is_recording(self) -> bool:
        with self._lock:
            return self._is_recording

    @property
    def actual_sample_rate(self) -> int:
        with self._lock:
            return self._actual_sample_rate

    def _load_sounddevice(self):
        if self._sounddevice is None:
            try:
                self._sounddevice = importlib.import_module("sounddevice")
            except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
                if getattr(sys, "frozen", False):
                    raise AudioRecorderError(
                        "Audio capture components are missing from this FlowType install. Reinstall the latest build."
                    ) from exc
                raise AudioRecorderError(
                    "sounddevice is not installed. Run `python -m pip install -e .` first."
                ) from exc
        return self._sounddevice


def _resample(audio_array: np.ndarray, src_rate: int, dst_rate: int, logger: logging.Logger) -> np.ndarray:
    """Resample mono audio from src_rate to dst_rate, preserving int16 amplitude scale.

    Prefers a high-quality polyphase/soxr resampler and falls back to linear
    interpolation only if neither is available. The device-fallback path (capturing
    at a native rate when the mic refuses 16 kHz) is the only caller, so quality here
    directly affects transcription accuracy on those machines.
    """
    if src_rate == dst_rate or audio_array.size == 0:
        return audio_array

    samples = audio_array.astype(np.float64, copy=False)

    try:  # high quality, tiny dependency
        import soxr  # type: ignore

        return soxr.resample(samples, src_rate, dst_rate)
    except Exception:
        pass

    try:  # part of scipy if present
        from math import gcd
        from scipy.signal import resample_poly  # type: ignore

        divisor = gcd(int(src_rate), int(dst_rate))
        up = int(dst_rate) // divisor
        down = int(src_rate) // divisor
        return resample_poly(samples, up, down)
    except Exception:
        logger.warning(
            "Falling back to linear resampling %dHz->%dHz; install 'soxr' for better quality",
            src_rate,
            dst_rate,
        )

    duration = len(samples) / float(src_rate)
    new_length = max(1, int(round(duration * dst_rate)))
    x_old = np.linspace(0.0, duration, len(samples), endpoint=False)
    x_new = np.linspace(0.0, duration, new_length, endpoint=False)
    return np.interp(x_new, x_old, samples)
