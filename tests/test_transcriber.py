from __future__ import annotations

from types import SimpleNamespace
from pathlib import Path

import numpy as np

from flowtype.audio import CapturedAudio
from flowtype.config import TranscriptionConfig
from flowtype.transcriber import Transcriber


class FakeWhisperModel:
    def __init__(self, *_args, device: str, **_kwargs) -> None:
        self.device = device

    def transcribe(self, _audio, **_kwargs):
        if self.device == "cuda":
            raise RuntimeError("Library cublas64_12.dll is not found or cannot be loaded")
        return [SimpleNamespace(text="Hello world.")], SimpleNamespace(language="en")


class FakeWhisperModule:
    WhisperModel = FakeWhisperModel


def test_transcriber_falls_back_to_cpu_when_cuda_inference_fails(tmp_path: Path, monkeypatch) -> None:
    config = TranscriptionConfig(
        model_size="base.en",
        device="auto",
        compute_type="auto",
        language="en",
        beam_size=1,
        vad_filter=True,
        model_cache_dir=tmp_path / "models",
    )
    transcriber = Transcriber(config)
    monkeypatch.setattr(transcriber, "_load_whisper_module", lambda: FakeWhisperModule())

    audio = CapturedAudio(
        audio_array=np.zeros(16000, dtype=np.float32),
        sample_rate=16000,
        duration_seconds=1.0,
        was_truncated=False,
        frame_count=16000,
    )

    result = transcriber.transcribe(audio)

    assert result.text == "Hello world."
    assert result.used_device == "cpu"
    assert result.used_compute_type == "int8"
    assert transcriber.consume_persist_cpu_requested() is True
    assert "cpu mode" in transcriber.consume_runtime_notice().lower()


def test_transcriber_warmup_validates_backend_and_pins_cpu(tmp_path: Path, monkeypatch) -> None:
    config = TranscriptionConfig(
        model_size="base.en",
        device="auto",
        compute_type="auto",
        language="en",
        beam_size=1,
        vad_filter=True,
        model_cache_dir=tmp_path / "models",
    )
    transcriber = Transcriber(config)
    monkeypatch.setattr(transcriber, "_load_whisper_module", lambda: FakeWhisperModule())

    transcriber.warm_up()

    assert transcriber.used_device == "cpu"
    assert transcriber.used_compute_type == "int8"
    assert transcriber.consume_persist_cpu_requested() is True
    assert "cpu mode" in transcriber.consume_runtime_notice().lower()
