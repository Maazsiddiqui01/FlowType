from __future__ import annotations

from types import SimpleNamespace

from flowtype.shortcuts import (
    _token_virtual_keys,
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


def test_token_virtual_keys_mapping() -> None:
    assert _token_virtual_keys("ctrl") == (0x11,)
    assert _token_virtual_keys("shift") == (0x10,)
    assert _token_virtual_keys("meta") == (0x5B, 0x5C)  # left or right Windows key
    assert _token_virtual_keys("space") == (0x20,)
    assert _token_virtual_keys("a") == (0x41,)
    assert _token_virtual_keys("0") == (0x30,)
    assert _token_virtual_keys("f5") == (0x74,)


def test_token_virtual_keys_unknown_returns_none() -> None:
    # Unmappable tokens must return None so the watchdog never force-releases them.
    assert _token_virtual_keys("é") is None
    assert _token_virtual_keys("mediaplay") is None
    assert _token_virtual_keys("f25") is None
