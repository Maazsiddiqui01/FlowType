from __future__ import annotations

from types import SimpleNamespace

from flowtype.shortcuts import (
    ShortcutManager,
    normalize_hotkey_token,
    parse_hotkey,
    should_suppress_hotkey,
    validate_shortcut_for_action,
)


def _ev(name: str, event_type: str) -> SimpleNamespace:
    return SimpleNamespace(name=name, event_type=event_type)


def test_hold_releases_when_modifier_lifted_before_main_key() -> None:
    # Regression for the reported bug: hold Ctrl+Shift+Space, then lift Ctrl/Shift
    # while still holding Space -> must stop (release), not keep recording.
    events: list[str] = []
    mgr = ShortcutManager()
    mgr.register_hold(
        "ctrl+shift+space",
        on_press=lambda: events.append("press"),
        on_release=lambda: events.append("release"),
    )

    for key in ("ctrl", "shift", "space"):
        mgr._kb_event(_ev(key, "down"))
    assert events == ["press"]

    mgr._kb_event(_ev("ctrl", "up"))  # lift a MODIFIER first, Space still down
    assert events == ["press", "release"]


def test_hold_releases_when_main_key_lifted() -> None:
    events: list[str] = []
    mgr = ShortcutManager()
    mgr.register_hold(
        "ctrl+shift+space",
        on_press=lambda: events.append("press"),
        on_release=lambda: events.append("release"),
    )
    for key in ("ctrl", "shift", "space"):
        mgr._kb_event(_ev(key, "down"))
    mgr._kb_event(_ev("space", "up"))
    assert events == ["press", "release"]


def test_hold_normalizes_windows_event_to_meta_token() -> None:
    events: list[str] = []
    mgr = ShortcutManager()
    mgr.register_hold(
        "ctrl+win",
        on_press=lambda: events.append("press"),
        on_release=lambda: events.append("release"),
    )
    mgr._kb_event(_ev("ctrl", "down"))
    mgr._kb_event(_ev("left windows", "down"))  # 'windows' must map to the 'meta' token
    assert events == ["press"]
    mgr._kb_event(_ev("left windows", "up"))
    assert events == ["press", "release"]


def test_should_suppress_only_modifier_combos() -> None:
    # Modifier combos are consumed (so the exact chord doesn't leak to other apps)...
    assert should_suppress_hotkey(("ctrl", "shift", "space")) is True
    assert should_suppress_hotkey(("ctrl", "alt", "space")) is True
    assert should_suppress_hotkey(("ctrl", "meta")) is True
    # ...but bare single keys are NOT suppressed (else Escape/F-keys break globally).
    assert should_suppress_hotkey(("escape",)) is False
    assert should_suppress_hotkey(("f8",)) is False


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
