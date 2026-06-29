from __future__ import annotations

import logging
from pathlib import Path
from types import SimpleNamespace

from flowtype.audio import AudioRecorderError, CapturedAudio
from flowtype.cleanup import CleanupResult
from flowtype.config import load_config, write_default_config
from flowtype.pipeline import DictationPipeline, _Job
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
    def deliver(self, _text: str, target=None) -> DeliveryResult:
        raise RuntimeError("paste blocked")


class SuccessfulOutput:
    def deliver(self, _text: str, target=None) -> DeliveryResult:
        return DeliveryResult(copied=True, pasted=True, delivery_state="pasted", target_restored=True)

    def copy_to_clipboard(self, _text: str) -> bool:
        return True


class CopyOnlyOutput:
    def __init__(self) -> None:
        self.copied_text = ""

    def deliver(self, _text: str, target=None) -> DeliveryResult:
        raise AssertionError("deliver should not run when processing was canceled")

    def copy_to_clipboard(self, text: str) -> bool:
        self.copied_text = text
        return True


class FailingCleaner:
    def clean(self, _raw_text: str) -> CleanupResult:
        raise RuntimeError("cleanup runtime missing")


class PinningTranscriber(DummyTranscriber):
    def __init__(self) -> None:
        self._pin_requested = True
        self._notice = "CUDA transcription failed on this machine. FlowType switched to CPU mode for reliability."

    def consume_persist_cpu_requested(self) -> bool:
        requested = self._pin_requested
        self._pin_requested = False
        return requested

    def consume_runtime_notice(self) -> str:
        notice = self._notice
        self._notice = ""
        return notice


def build_config(tmp_path: Path):
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    return load_config(config_path)


def make_job(*, cancel: bool = False, was_truncated: bool = False) -> _Job:
    job = _Job(
        audio=CapturedAudio(
            audio_array=[],
            sample_rate=16000,
            duration_seconds=1.2,
            was_truncated=was_truncated,
            frame_count=16000,
        ),
        target=None,
        was_truncated=was_truncated,
    )
    if cancel:
        job.cancel.set()
    return job


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
    # The detail is now a categorized, actionable message rather than a generic one.
    assert status_updates[-1][0] == "error"
    assert "microphone" in status_updates[-1][1].lower()


def test_pipeline_allows_new_recording_while_previous_is_processing(tmp_path: Path) -> None:
    """The owner's #1 requirement: a record trigger is NEVER dropped just because the
    previous take is still being transcribed/cleaned/pasted."""
    config = build_config(tmp_path)
    recorder = DummyRecorder()
    pipeline = DictationPipeline(
        config=config,
        recorder=recorder,
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=SuccessfulOutput(),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    # Simulate a previous take still being processed by the worker.
    pipeline._jobs_in_flight = 1
    pipeline._worker_stage = "cleaning"

    pipeline.start_recording()

    assert recorder.started == 1
    assert pipeline.status == "recording"


def test_pipeline_refuses_only_when_a_capture_is_already_active(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    recorder = DummyRecorder()
    pipeline = DictationPipeline(
        config=config,
        recorder=recorder,
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=SuccessfulOutput(),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline.start_recording()
    pipeline.start_recording()  # second press while already capturing

    assert recorder.started == 1  # not restarted
    assert pipeline.status == "recording"


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

    pipeline._consume_job(make_job())

    assert pipeline.status == "error"
    assert status_updates[-1] == ("error", "paste blocked")


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

    pipeline._error_detail = "Previous dictation failed"
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


def test_pipeline_falls_back_to_raw_text_when_cleanup_raises(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    results = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=FailingCleaner(),
        output=SuccessfulOutput(),
        result_callback=lambda result: results.append(result),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._consume_job(make_job())

    assert pipeline.status == "ready"
    assert results
    assert results[-1].final_text == "hello there from flowtype"
    assert results[-1].used_fallback is True


def test_pipeline_preserves_text_when_processing_is_canceled(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    output = CopyOnlyOutput()
    results = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=output,
        result_callback=lambda result: results.append(result),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._consume_job(make_job(cancel=True))

    assert pipeline.status == "ready"
    assert output.copied_text == "Hello There From Flowtype"
    assert results[-1].delivery_state == "copied_only"
    assert "clipboard" in results[-1].delivery_note.lower()


def test_pipeline_surfaces_truncation_note_in_result(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    results = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=DummyTranscriber(),
        cleaner=DummyCleaner(),
        output=SuccessfulOutput(),
        result_callback=lambda result: results.append(result),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._consume_job(make_job(was_truncated=True))

    assert results
    assert "maximum length" in results[-1].delivery_note.lower()


def test_pipeline_pins_cpu_in_config_after_runtime_cuda_failure(tmp_path: Path) -> None:
    config = build_config(tmp_path)
    notices: list[tuple[str, str]] = []
    pipeline = DictationPipeline(
        config=config,
        recorder=DummyRecorder(),
        transcriber=PinningTranscriber(),
        cleaner=DummyCleaner(),
        output=SuccessfulOutput(),
        notification_callback=lambda message, tone: notices.append((message, tone)),
        logger=logging.getLogger("test.pipeline.runtime"),
    )

    pipeline._consume_job(make_job())

    reloaded = load_config(config.config_path)
    assert reloaded.transcription.device == "cpu"
    assert reloaded.transcription.compute_type == "int8"
    assert notices[-1][0].startswith("CUDA transcription failed")
