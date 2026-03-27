from __future__ import annotations

import importlib
import logging
import threading
from dataclasses import dataclass
from typing import Callable, Literal, Any


HOTKEY_ALIASES = {
    "control": "ctrl",
    "ctrl_l": "ctrl",
    "ctrl_r": "ctrl",
    "shift_l": "shift",
    "shift_r": "shift",
    "alt_l": "alt",
    "alt_r": "alt",
    "cmd": "meta",
    "super": "meta",
    "return": "enter",
    "esc": "escape",
    "win": "meta",
    "windows": "meta",
}

MODIFIER_TOKENS = ("ctrl", "alt", "shift", "meta")
COMMON_EDITING_SHORTCUTS = {
    "ctrl+a",
    "ctrl+c",
    "ctrl+v",
    "ctrl+x",
    "ctrl+y",
    "ctrl+z",
    "alt+tab",
}

@dataclass
class ShortcutBinding:
    mode: Literal["hold", "trigger"]
    tokens: frozenset[str]
    on_press: Callable[[], None] | None = None
    on_release: Callable[[], None] | None = None
    active: bool = False

class ShortcutManager:
    def __init__(self, logger: logging.Logger | None = None) -> None:
        self.logger = logger or logging.getLogger("flowtype.shortcuts")
        self._listener: Any = None
        self._pressed: set[str] = set()
        self._bindings: list[ShortcutBinding] = []
        self._lock = threading.RLock()

    def register_hold(self, hotkey: str, on_press: Callable[[], None], on_release: Callable[[], None]) -> None:
        tokens = frozenset(parse_hotkey(hotkey))
        self._bindings.append(ShortcutBinding(mode="hold", tokens=tokens, on_press=on_press, on_release=on_release))
        self.logger.debug("Registered hold hotkey: %s", hotkey)

    def register_action(self, hotkey: str, on_trigger: Callable[[], None]) -> None:
        tokens = frozenset(parse_hotkey(hotkey))
        self._bindings.append(ShortcutBinding(mode="trigger", tokens=tokens, on_press=on_trigger))
        self.logger.debug("Registered action hotkey: %s", hotkey)

    def start(self) -> None:
        keyboard = self._load_keyboard()
        self._listener = keyboard.Listener(
            on_press=self._handle_press,
            on_release=self._handle_release,
        )
        self._listener.start()

    def stop(self) -> None:
        l = self._listener
        if l is not None:
            l.stop()
            self._listener = None

    def _handle_press(self, key) -> None:
        token = normalize_key_token(key)
        if not token:
            return

        actions_to_run = []
        with self._lock:
            self._pressed.add(token)
            
            for binding in self._bindings:
                if not binding.active and binding.tokens.issubset(self._pressed):
                    binding.active = True
                    cb = binding.on_press
                    if cb is not None:
                        actions_to_run.append(cb)

        for action in actions_to_run:
            try:
                action()
            except Exception as e:
                self.logger.error("Error running hotkey action: %s", e)

    def _handle_release(self, key) -> None:
        token = normalize_key_token(key)
        if not token:
            return

        actions_to_run = []
        with self._lock:
            self._pressed.discard(token)
            
            for binding in self._bindings:
                if binding.active and not binding.tokens.issubset(self._pressed):
                    binding.active = False
                    if binding.mode == "hold":
                        cb = binding.on_release
                        if cb is not None:
                            actions_to_run.append(cb)

        for action in actions_to_run:
            try:
                action()
            except Exception as e:
                self.logger.error("Error running hotkey release action: %s", e)

    def _load_keyboard(self):
        try:
            return importlib.import_module("pynput.keyboard")
        except ModuleNotFoundError as exc:  # pragma: no cover
            raise RuntimeError("pynput is not installed. Run `python -m pip install -e .` first.") from exc

def parse_hotkey(hotkey: str) -> list[str]:
    tokens = []
    for raw_token in hotkey.split("+"):
        token = normalize_hotkey_token(raw_token)
        if not token:
            raise ValueError(f"hotkey token is empty in {hotkey!r}")
        tokens.append(token)
    return tokens


def canonicalize_hotkey(tokens: list[str]) -> list[str]:
    normalized_tokens = [normalize_hotkey_token(token) for token in tokens if normalize_hotkey_token(token)]
    ordered_modifiers = [token for token in MODIFIER_TOKENS if token in normalized_tokens]
    main_keys = [token for token in normalized_tokens if token not in MODIFIER_TOKENS]
    return [*ordered_modifiers, *main_keys]


def validate_shortcut_for_action(action: str, hotkey: str) -> str:
    normalized_hotkey = hotkey.strip().lower()
    if not normalized_hotkey:
        return ""

    tokens = canonicalize_hotkey(parse_hotkey(normalized_hotkey))
    modifiers = [token for token in tokens if token in MODIFIER_TOKENS]
    main_keys = [token for token in tokens if token not in MODIFIER_TOKENS]

    if len(main_keys) != 1:
        raise ValueError("Use exactly one main key with any modifiers.")

    canonical = "+".join(tokens)

    if action in {"hold_to_talk", "toggle_recording", "repaste_last"} and not modifiers:
        raise ValueError("Use Ctrl, Alt, Shift, or Win with one main key.")

    if action == "cancel_recording" and not modifiers and main_keys[0] != "escape":
        raise ValueError("Use Esc or a modified shortcut for cancel recording.")

    if action == "repaste_last" and canonical in COMMON_EDITING_SHORTCUTS:
        raise ValueError("Choose a re-paste shortcut that does not clash with common editing keys.")

    return canonical

def normalize_hotkey_token(token: str) -> str:
    normalized = token.strip().lower().replace("key.", "")
    normalized = HOTKEY_ALIASES.get(normalized, normalized)
    return normalized

def normalize_key_token(key) -> str:
    char = getattr(key, "char", None)
    if char:
        return normalize_hotkey_token(char)

    name = getattr(key, "name", "")
    if name:
        return normalize_hotkey_token(name)

    raw = str(key)
    if raw.startswith("Key."):
        return normalize_hotkey_token(raw.replace("Key.", "", 1))
    return ""
