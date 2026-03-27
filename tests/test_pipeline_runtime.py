from __future__ import annotations

import logging
from pathlib import Path
from types import SimpleNamespace

from flowtype.audio import AudioRecorderError, CapturedAudio
from flowtype.cleanup import CleanupResult
from flowtype.config import load_config, write_default_config
from flowtype.pipeline import DictationPipeline
from flowtype.output import DeliveryResult


class StartFailRecorder:
    audio_level_callback = None

    def start(self) -> None:
        raise AudioRecorderError("no microphone")

    def stop(self):  # pragma: no cover - not used in this path
        raise AssertionError("stop should not be called")

    def is_recording(self) -> bool:
        return False


class DummyRecorder:
    audio_level_callback = None

    def __init__(self) -> None:
        self.started = 0

    def start(self) -> None:
        self.started += 1
        return None

    def stop(self):  # pragma: no cover - not used in this path
        raise AssertionError("stop should not be called")

    def is_recording(self) -> bool:
        return False


class DummyTranscriber:
    def transcribe(self, _captured_audio: CapturedAudio):
        return SimpleNamespace(text="hello there from flowtype", used_device="cpu")


class DummyCleaner:
    def clean(self, raw_text: str) -> CleanupResult:
        return CleanupResult(text=raw_text.title(), used_fallback=False, attempts=1, provider="openrouter")


class FailingOutput:
    def deliver(self, _text: str) -> DeliveryResult:
        raise RuntimeError("paste blocked")


class SuccessfulOutput:
    def deliver(self, _text: str) -> DeliveryResult:
        return DeliveryResult(copied=True, pasted=True)


def build_config(tmp_path: Path):
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    return load_config(config_path)


def test_pipeline_sets_error_status_when_recording_cannot_start(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    status_updates: list[tuple[str, str]] = []
    pipeline = DictationPipeline(
        config=config,
        recorder=StartFailRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=FailingOutput(),
        status_callback=lambda status, detail: status_updates.append((status, detail)),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline.start_recording()

    assert pipeline.status == "error"
    assert status_updates[-1] == ("error", "Could not start recording. Check microphone access.")


def test_pipeline_sets_error_status_when_delivery_fails(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    status_updates: list[tuple[str, str]] = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=FailingOutput(),
        status_callback=lambda status, detail: status_updates.append((status, detail)),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._process_capture(
        CapturedAudio(
            audio_array=[],
            sample_rate=16000,
            duration_seconds=1.2,
            was_truncated=False,
            frame_count=16000,
        )
    )

    assert pipeline.status == "error"
    assert status_updates[-1] == ("error", "Last dictation failed. Check the log.")


def test_toggle_recording_can_retry_from_error_state(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    recorder = DummyRecorder()
    status_updates: list[tuple[str, str]] = []
    pipeline = DictationPipeline(
        config=config,
        recorder=recorder,
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=SuccessfulOutput(),
        status_callback=lambda status, detail: status_updates.append((status, detail)),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._set_status("error", "Previous dictation failed")
    pipeline.toggle_recording()

    assert recorder.started == 1
    assert pipeline.status == "recording"
    assert status_updates[-1] == ("recording", "Recording...")


def test_repaste_failure_sets_error_status(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    status_updates: list[tuple[str, str]] = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=FailingOutput(),
        status_callback=lambda status, detail: status_updates.append((status, detail)),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._last_final_text = "Hello again"
    pipeline.repaste_last()

    assert pipeline.status == "error"
    assert status_updates[-1] == ("error", "Could not re-paste the last result. Check the log.")
