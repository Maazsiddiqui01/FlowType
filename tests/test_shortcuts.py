from __future__ import annotations

from types import SimpleNamespace

from flowtype.shortcuts import (
    normalize_hotkey_token,
    normalize_key_token,
)


def test_control_char_maps_back_to_letter() -> None:
    # pynput delivers control chars in .char when Ctrl is held (Ctrl+A -> '\x01').
    assert normalize_key_token(SimpleNamespace(char="\x01")) == "a"
    assert normalize_key_token(SimpleNamespace(char="\x03")) == "c"
    assert normalize_key_token(SimpleNamespace(char="\x1a")) == "z"


def test_plain_char_is_unchanged() -> None:
    assert normalize_key_token(SimpleNamespace(char="a")) == "a"
    assert normalize_key_token(SimpleNamespace(char="A")) == "a"


def test_right_windows_key_normalizes_to_meta() -> None:
    assert normalize_hotkey_token("cmd_r") == "meta"
    assert normalize_hotkey_token("win_r") == "meta"
    assert normalize_key_token(SimpleNamespace(char=None, name="cmd_r")) == "meta"


def test_left_windows_key_normalizes_to_meta() -> None:
    assert normalize_hotkey_token("cmd_l") == "meta"
    assert normalize_hotkey_token("win_l") == "meta"
