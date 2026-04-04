from __future__ import annotations

from flowtype.shortcuts import normalize_hotkey_token, parse_hotkey, validate_shortcut_for_action


def test_parse_hotkey_normalizes_aliases() -> None:
    assert parse_hotkey("Control+Shift+Space") == ["ctrl", "shift", "space"]


def test_normalize_hotkey_token_removes_key_prefix() -> None:
    assert normalize_hotkey_token("Key.enter") == "enter"


def test_validate_shortcut_allows_single_key_hold_shortcut() -> None:
    assert validate_shortcut_for_action("hold_to_talk", "space") == "space"


def test_validate_shortcut_allows_modifier_only_recording_combo() -> None:
    assert validate_shortcut_for_action("toggle_recording", "ctrl+win") == "ctrl+meta"


def test_validate_shortcut_rejects_common_global_shortcuts() -> None:
    try:
        validate_shortcut_for_action("toggle_recording", "ctrl+v")
    except ValueError as exc:
        assert "does not clash" in str(exc)
    else:  # pragma: no cover - explicit failure branch
        raise AssertionError("Expected a dangerous shortcut validation error")


def test_validate_shortcut_rejects_common_repaste_binding() -> None:
    try:
        validate_shortcut_for_action("repaste_last", "v")
    except ValueError as exc:
        assert "Ctrl, Alt, Shift, or Win" in str(exc)
    else:  # pragma: no cover - explicit failure branch
        raise AssertionError("Expected a repaste shortcut validation error")


def test_validate_shortcut_rejects_modifier_only_repaste_binding() -> None:
    try:
        validate_shortcut_for_action("repaste_last", "ctrl+win")
    except ValueError as exc:
        assert "one main key" in str(exc)
    else:  # pragma: no cover - explicit failure branch
        raise AssertionError("Expected a repaste shortcut validation error")
