from __future__ import annotations

import importlib
import logging
import threading
from dataclasses import dataclass
from typing import Any, Callable, Literal


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
    "page_up": "pageup",
    "page down": "pagedown",
    "page_down": "pagedown",
    "page up": "pageup",
    "del": "delete",
    "ins": "insert",
}

MODIFIER_TOKENS = ("ctrl", "alt", "shift", "meta")
COMMON_EDITING_SHORTCUTS = {
    "ctrl+a",
    "ctrl+c",
    "ctrl+l",
    "ctrl+n",
    "ctrl+o",
    "ctrl+p",
    "ctrl+r",
    "ctrl+s",
    "ctrl+t",
    "ctrl+v",
    "ctrl+w",
    "ctrl+x",
    "ctrl+y",
    "ctrl+z",
    "alt+f4",
    "alt+tab",
    "ctrl+escape",
    "meta+d",
    "meta+e",
    "meta+l",
    "meta+r",
    "meta+space",
    "meta+tab",
    "meta+v",
    "meta+shift+s",
}
RISKY_MODIFIER_ONLY_SHORTCUTS = {
    "alt+shift",
    "ctrl+shift",
}
BACKEND_TOKEN_ALIASES = {
    "meta": "windows",
}


@dataclass
class ShortcutBinding:
    mode: Literal["hold", "trigger"]
    ordered_tokens: tuple[str, ...]
    on_press: Callable[[], None] | None = None
    on_release: Callable[[], None] | None = None
    active: bool = False

    @property
    def tokens(self) -> frozenset[str]:
        return frozenset(self.ordered_tokens)


class ShortcutManager:
    def __init__(self, logger: logging.Logger | None = None) -> None:
        self.logger = logger or logging.getLogger("flowtype.shortcuts")
        self._listener: Any = None
        self._backend_name = ""
        self._pressed: set[str] = set()
        self._bindings: list[ShortcutBinding] = []
        self._keyboard_hotkeys: list[Callable[[], None]] = []
        self._lock = threading.RLock()

    def register_hold(self, hotkey: str, on_press: Callable[[], None], on_release: Callable[[], None]) -> None:
        tokens = tuple(canonicalize_hotkey(parse_hotkey(hotkey)))
        self._bindings.append(
            ShortcutBinding(mode="hold", ordered_tokens=tokens, on_press=on_press, on_release=on_release)
        )
        self.logger.debug("Registered hold hotkey: %s", hotkey)

    def register_action(self, hotkey: str, on_trigger: Callable[[], None]) -> None:
        tokens = tuple(canonicalize_hotkey(parse_hotkey(hotkey)))
        self._bindings.append(ShortcutBinding(mode="trigger", ordered_tokens=tokens, on_press=on_trigger))
        self.logger.debug("Registered action hotkey: %s", hotkey)

    def start(self) -> None:
        try:
            keyboard = self._load_keyboard_backend()
            self._start_keyboard_backend(keyboard)
            self._backend_name = "keyboard"
            self.logger.info("Shortcut backend started with suppressed Windows keyboard hook")
            return
        except Exception as exc:
            self.logger.warning("Keyboard shortcut backend unavailable; falling back to pynput: %s", exc)

        keyboard = self._load_pynput_keyboard()
        self._listener = keyboard.Listener(on_press=self._handle_press, on_release=self._handle_release)
        self._listener.start()
        self._backend_name = "pynput"

    def stop(self) -> None:
        for remove in self._keyboard_hotkeys:
            try:
                remove()
            except Exception:
                continue
        self._keyboard_hotkeys = []

        listener = self._listener
        if listener is not None:
            listener.stop()
            self._listener = None

        self._backend_name = ""
        self._pressed.clear()

    def _start_keyboard_backend(self, keyboard: Any) -> None:
        for binding in self._bindings:
            hotkey = backend_hotkey(binding.ordered_tokens)
            if binding.mode == "hold":
                press_remove = keyboard.add_hotkey(
                    hotkey,
                    self._safe_callback(binding.on_press),
                    suppress=True,
                    trigger_on_release=False,
                )
                release_remove = keyboard.add_hotkey(
                    hotkey,
                    self._safe_callback(binding.on_release),
                    suppress=True,
                    trigger_on_release=True,
                )
                self._keyboard_hotkeys.extend([press_remove, release_remove])
                continue

            remove = keyboard.add_hotkey(
                hotkey,
                self._safe_callback(binding.on_press),
                suppress=True,
                trigger_on_release=False,
            )
            self._keyboard_hotkeys.append(remove)

    def _safe_callback(self, callback: Callable[[], None] | None) -> Callable[[], None]:
        def wrapped() -> None:
            if callback is None:
                return
            try:
                callback()
            except Exception as exc:
                self.logger.error("Error running hotkey action: %s", exc)

        return wrapped

    def _handle_press(self, key: Any) -> None:
        token = normalize_key_token(key)
        if not token:
            return

        actions_to_run = []
        with self._lock:
            self._pressed.add(token)
            for binding in self._bindings:
                if not binding.active and binding.tokens.issubset(self._pressed):
                    binding.active = True
                    if binding.on_press is not None:
                        actions_to_run.append(binding.on_press)

        for action in actions_to_run:
            try:
                action()
            except Exception as exc:
                self.logger.error("Error running hotkey action: %s", exc)

    def _handle_release(self, key: Any) -> None:
        token = normalize_key_token(key)
        if not token:
            return

        actions_to_run = []
        with self._lock:
            self._pressed.discard(token)
            for binding in self._bindings:
                if binding.active and not binding.tokens.issubset(self._pressed):
                    binding.active = False
                    if binding.mode == "hold" and binding.on_release is not None:
                        actions_to_run.append(binding.on_release)

        for action in actions_to_run:
            try:
                action()
            except Exception as exc:
                self.logger.error("Error running hotkey release action: %s", exc)

    def _load_keyboard_backend(self) -> Any:
        try:
            return importlib.import_module("keyboard")
        except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
            raise RuntimeError("keyboard is not installed") from exc

    def _load_pynput_keyboard(self) -> Any:
        try:
            return importlib.import_module("pynput.keyboard")
        except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
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
    deduped: list[str] = []
    for token in normalized_tokens:
        if token not in deduped:
            deduped.append(token)
    ordered_modifiers = [token for token in MODIFIER_TOKENS if token in deduped]
    main_keys = [token for token in deduped if token not in MODIFIER_TOKENS]
    return [*ordered_modifiers, *main_keys]


def validate_shortcut_for_action(action: str, hotkey: str) -> str:
    normalized_hotkey = hotkey.strip().lower()
    if not normalized_hotkey:
        return ""

    tokens = canonicalize_hotkey(parse_hotkey(normalized_hotkey))
    modifiers = [token for token in tokens if token in MODIFIER_TOKENS]
    main_keys = [token for token in tokens if token not in MODIFIER_TOKENS]
    canonical = "+".join(tokens)

    if canonical in COMMON_EDITING_SHORTCUTS:
        raise ValueError("Choose a shortcut that does not clash with common editing or system keys.")

    if action == "repaste_last":
        if len(main_keys) != 1 or not modifiers:
            raise ValueError("Use Ctrl, Alt, Shift, or Win with one main key.")
        return canonical

    if len(main_keys) == 1:
        return canonical

    if len(main_keys) == 0 and len(modifiers) >= 2:
        if canonical in RISKY_MODIFIER_ONLY_SHORTCUTS:
            raise ValueError("Choose a modifier combo that will not interfere with Windows or language switching.")
        return canonical

    raise ValueError("Use one key with optional modifiers, or a safe modifier-only combo like Ctrl+Win.")


def normalize_hotkey_token(token: str) -> str:
    normalized = token.strip().lower().replace("key.", "")
    return HOTKEY_ALIASES.get(normalized, normalized)


def normalize_key_token(key: Any) -> str:
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


def backend_hotkey(tokens: tuple[str, ...]) -> str:
    return "+".join(BACKEND_TOKEN_ALIASES.get(token, token) for token in tokens)
