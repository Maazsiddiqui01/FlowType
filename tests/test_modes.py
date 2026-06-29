from __future__ import annotations

import logging
from dataclasses import replace
from pathlib import Path

from flowtype.catalog import resolve_mode_for_app
from flowtype.cleanup import TextCleaner
from flowtype.config import CleanupConfig, _parse_app_rules, load_config, save_config_data, write_default_config


def _settings() -> CleanupConfig:
    return CleanupConfig(
        provider="openrouter",
        api_key="k",
        model="m",
        prompt="Clean it.",
        temperature=0.1,
        max_tokens=128,
        timeout_seconds=5,
        max_retries=1,
        retry_backoff_seconds=0.0,
        min_word_count=3,
    )


def test_resolve_mode_matches_exe_name() -> None:
    rules = (("code.exe", "technical"), ("outlook", "meeting"))
    assert resolve_mode_for_app(rules, "Code.exe", "main.py - VS Code", "default") == "technical"


def test_resolve_mode_matches_window_title() -> None:
    rules = (("inbox", "meeting"),)
    assert resolve_mode_for_app(rules, "chrome.exe", "Inbox (12) - Gmail", "default") == "meeting"


def test_resolve_mode_falls_back_to_default_when_no_rule_matches() -> None:
    rules = (("code.exe", "technical"),)
    assert resolve_mode_for_app(rules, "notepad.exe", "Untitled", "focused") == "focused"


def test_resolve_mode_ignores_unknown_mode_id() -> None:
    rules = (("code.exe", "nonsense"),)
    assert resolve_mode_for_app(rules, "code.exe", "", "default") == "default"


def test_parse_app_rules_skips_comments_and_blanks() -> None:
    text = "code.exe = technical\n# a comment\nslack=default\nno-equals-here\n  outlook = meeting "
    assert _parse_app_rules(text) == (
        ("code.exe", "technical"),
        ("slack", "default"),
        ("outlook", "meeting"),
    )


def test_clean_uses_mode_prompt_override() -> None:
    cleaner = TextCleaner(_settings(), logger=logging.getLogger("test.modes"))
    prompt = cleaner._compose_prompt("Keep code verbatim and terse.")
    assert "Mode guidance:" in prompt
    assert "Keep code verbatim and terse." in prompt


def test_app_rules_round_trip_through_config(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    save_config_data(config_path, {"mode": {"app_rules": "code.exe = technical\nslack = default"}})

    config = load_config(config_path)
    assert config.mode.app_rules == (("code.exe", "technical"), ("slack", "default"))
    assert "code.exe = technical" in config.mode.app_rules_text
