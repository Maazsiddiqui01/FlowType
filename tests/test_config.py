from __future__ import annotations

from pathlib import Path

import pytest

from flowtype.config import RECOMMENDED_SHORTCUTS, load_config, save_config_data, write_default_config


def test_load_config_creates_default_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_path = tmp_path / "config.toml"
    monkeypatch.delenv("FLOWTYPE_CONFIG", raising=False)

    config = load_config(config_path)

    assert config_path.exists()
    assert config.general.hotkey == "ctrl+shift+space"
    assert config.shortcuts.toggle_recording == RECOMMENDED_SHORTCUTS["toggle_recording"]
    assert config.shortcuts.cancel_recording == RECOMMENDED_SHORTCUTS["cancel_recording"]
    assert config.general.log_file.parent == config_path.parent / "logs"
    assert config.experience.onboarding_dismissed is False
    assert config.experience.close_to_tray is True
    assert config.startup.launch_at_login is True
    assert config.startup.start_minimized is True
    assert config.startup.prompt_completed is False


def test_load_config_uses_environment_api_key(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    monkeypatch.setenv("OPENROUTER_API_KEY", "router-secret")

    config = load_config(config_path)

    assert config.cleanup.api_key == "router-secret"


def test_invalid_paste_method_raises(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    config_path.write_text(
        """
[general]
hotkey = "ctrl+shift+space"
log_level = "INFO"

[audio]
sample_rate = 16000
channels = 1
dtype = "int16"
max_duration_seconds = 300
min_duration_ms = 250

[transcription]
model_size = "base.en"
device = "auto"
compute_type = "auto"
language = "en"
beam_size = 1
vad_filter = true

[cleanup]
provider = "none"
api_key = ""
model = "unused"
temperature = 0.1
max_tokens = 128
timeout_seconds = 20
max_retries = 3
retry_backoff_seconds = 1.0
min_word_count = 3
prompt = "unused"

[output]
paste_method = "bad"
paste_delay_ms = 80
restore_clipboard = false
""",
        encoding="utf-8",
    )

    with pytest.raises(ValueError):
        load_config(config_path)


def test_sample_rate_must_stay_16000(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    with pytest.raises(ValueError):
        save_config_data(
            config_path,
            {
                "audio": {
                    "sample_rate": 44100,
                }
            },
        )


def test_save_config_data_persists_user_changes(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)

    save_config_data(
        config_path,
        {
            "general": {"hotkey": "ctrl+alt+space"},
            "cleanup": {
                "provider": "openai",
                "api_key": "saved-key",
                "model": "gpt-4o-mini",
            },
            "output": {
                "paste_method": "clipboard_only",
                "restore_clipboard": True,
            },
            "experience": {
                "close_to_tray": False,
            },
            "startup": {
                "launch_at_login": False,
                "start_minimized": False,
                "prompt_completed": True,
            },
        },
    )

    config = load_config(config_path)

    assert config.general.hotkey == "ctrl+alt+space"
    assert config.cleanup.provider == "openai"
    assert config.cleanup.api_key == "saved-key"
    assert config.output.paste_method == "clipboard_only"
    assert config.output.restore_clipboard is True
    assert config.experience.close_to_tray is False
    assert config.startup.launch_at_login is False
    assert config.startup.start_minimized is False
    assert config.startup.prompt_completed is True


def test_load_config_uses_provider_specific_env_fallbacks(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    monkeypatch.setenv("GEMINI_API_KEY", "gemini-secret")
    monkeypatch.setenv("XAI_API_KEY", "xai-secret")

    save_config_data(config_path, {"cleanup": {"provider": "gemini", "api_key": "", "model": "gemini-2.5-flash"}})
    config = load_config(config_path)
    assert config.cleanup.api_key == "gemini-secret"

    save_config_data(config_path, {"cleanup": {"provider": "xai", "api_key": "", "model": "grok-3-fast"}})
    config = load_config(config_path)
    assert config.cleanup.api_key == "xai-secret"
