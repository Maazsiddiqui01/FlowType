from __future__ import annotations

import logging
from pathlib import Path

import numpy as np

from flowtype.audio import (
    AudioRecorder,
    list_orphan_recordings,
    read_wav,
    write_wav,
    _resample,
)
from flowtype.config import AudioConfig


def make_audio_config(tmp_path: Path, journal: bool = True) -> AudioConfig:
    return AudioConfig(
        sample_rate=16000,
        channels=1,
        dtype="int16",
        max_duration_seconds=1800,
        min_duration_ms=250,
        journal_audio=journal,
        recordings_dir=tmp_path / "recordings",
    )


def test_write_then_read_wav_round_trips(tmp_path: Path) -> None:
    samples = (np.sin(np.linspace(0, 6.28, 16000)) * 0.5).astype(np.float32)
    path = tmp_path / "tone.wav"
    write_wav(path, samples, 16000)

    captured = read_wav(path, target_rate=16000)
    assert captured.sample_rate == 16000
    assert captured.frame_count == 16000
    # within 16-bit quantization error
    assert np.max(np.abs(captured.audio_array - samples)) < 1e-3


def test_read_wav_resamples_to_target(tmp_path: Path) -> None:
    samples = (np.sin(np.linspace(0, 6.28, 8000)) * 0.4).astype(np.float32)
    path = tmp_path / "tone8k.wav"
    write_wav(path, samples, 8000)

    captured = read_wav(path, target_rate=16000)
    assert captured.sample_rate == 16000
    # ~doubled length after upsampling 8k -> 16k
    assert abs(captured.frame_count - 16000) < 50


def test_stop_journals_recording_to_disk(tmp_path: Path) -> None:
    recorder = AudioRecorder(make_audio_config(tmp_path), logger=logging.getLogger("test.audio"))
    # Simulate an in-progress capture without a real input device.
    chunk = (np.ones(16000, dtype=np.int16) * 1000)
    recorder._chunks = [chunk]
    recorder._recorded_frames = 16000
    recorder._is_recording = True
    recorder._stream = None
    recorder._actual_sample_rate = 16000

    captured = recorder.stop()

    assert captured.file_path is not None
    journaled = Path(captured.file_path)
    assert journaled.exists()
    reloaded = read_wav(journaled, target_rate=16000)
    assert reloaded.frame_count == 16000


def test_journaling_disabled_writes_no_file(tmp_path: Path) -> None:
    recorder = AudioRecorder(make_audio_config(tmp_path, journal=False), logger=logging.getLogger("test.audio"))
    recorder._chunks = [(np.ones(8000, dtype=np.int16) * 500)]
    recorder._recorded_frames = 8000
    recorder._is_recording = True
    recorder._stream = None
    recorder._actual_sample_rate = 16000

    captured = recorder.stop()

    assert captured.file_path is None


def test_list_orphan_recordings_sorted(tmp_path: Path) -> None:
    recordings = tmp_path / "recordings"
    recordings.mkdir()
    samples = np.zeros(1600, dtype=np.float32)
    first = recordings / "rec-1000.wav"
    second = recordings / "rec-2000.wav"
    write_wav(first, samples, 16000)
    write_wav(second, samples, 16000)

    orphans = list_orphan_recordings(recordings)
    assert [p.name for p in orphans] == ["rec-1000.wav", "rec-2000.wav"]
    assert list_orphan_recordings(None) == []
    assert list_orphan_recordings(tmp_path / "missing") == []


def test_resample_changes_length() -> None:
    data = np.linspace(-1000, 1000, 8000).astype(np.float64)
    out = _resample(data, 8000, 16000, logging.getLogger("test.audio"))
    assert abs(len(out) - 16000) < 50
