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
    "cmd_l": "meta",
    "cmd_r": "meta",
    "win_l": "meta",
    "win_r": "meta",
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
        self._keyboard_module: Any = None
        self._release_hook: Any = None
        self._kb_pressed: set[str] = set()
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
        started = False
        try:
            keyboard = self._load_keyboard_backend()
            self._start_keyboard_backend(keyboard)
            self._backend_name = "keyboard"
            self.logger.info("Shortcut backend started with suppressed Windows keyboard hook")
            started = True
        except Exception as exc:
            self.logger.warning("Keyboard shortcut backend unavailable; falling back to pynput: %s", exc)

        if not started:
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

        if self._release_hook is not None and self._keyboard_module is not None:
            try:
                self._keyboard_module.unhook(self._release_hook)
            except Exception:
                pass
        self._release_hook = None
        self._keyboard_module = None

        listener = self._listener
        if listener is not None:
            listener.stop()
            self._listener = None

        self._backend_name = ""
        for binding in self._bindings:
            binding.active = False
        self._pressed.clear()
        self._kb_pressed.clear()

    def _start_keyboard_backend(self, keyboard: Any) -> None:
        self._keyboard_module = keyboard
        self._kb_pressed = set()
        has_hold = False
        for binding in self._bindings:
            binding.active = False
            hotkey = backend_hotkey(binding.ordered_tokens)
            # Only swallow the key event for modifier combos. Suppressing a BARE single
            # key (e.g. cancel = "escape") would consume it globally and break it in
            # every other app; a non-suppressed hotkey still fires our callback.
            suppress = should_suppress_hotkey(binding.ordered_tokens)
            if binding.mode == "hold":
                has_hold = True
                # add_hotkey is used ONLY to suppress the combo (so Space isn't typed
                # while talking); press/release are detected by the transition hook
                # below. add_hotkey's own release fires only when the MAIN key lifts,
                # which is the reported bug (releasing a modifier first never stops).
                if suppress:
                    remove = keyboard.add_hotkey(hotkey, lambda: None, suppress=True, trigger_on_release=False)
                    self._keyboard_hotkeys.append(remove)
                continue

            remove = keyboard.add_hotkey(
                hotkey,
                self._safe_callback(binding.on_press),
                suppress=suppress,
                trigger_on_release=False,
            )
            self._keyboard_hotkeys.append(remove)

        # Track real key transitions for hold bindings: press fires when the combo is
        # complete, release fires the instant ANY of its keys lifts. Robust against the
        # suppressed-combo synthetic-event flicker that is_pressed polling suffered from.
        if has_hold:
            self._release_hook = keyboard.hook(self._kb_event)

    def _kb_event(self, event: Any) -> None:
        name = _normalize_event_key(getattr(event, "name", ""))
        if not name:
            return
        event_type = getattr(event, "event_type", "")
        actions: list[tuple[str, Callable[[], None]]] = []
        with self._lock:
            if event_type == "down":
                self._kb_pressed.add(name)
                for binding in self._bindings:
                    if binding.mode == "hold" and not binding.active and binding.tokens.issubset(self._kb_pressed):
                        binding.active = True
                        if binding.on_press is not None:
                            actions.append(("press", binding.on_press))
            elif event_type == "up":
                self._kb_pressed.discard(name)
                for binding in self._bindings:
                    if binding.mode == "hold" and binding.active and not binding.tokens.issubset(self._kb_pressed):
                        binding.active = False
                        if binding.on_release is not None:
                            actions.append(("release", binding.on_release))
        for kind, callback in actions:
            try:
                callback()
            except Exception as exc:
                self.logger.error("Error running hold %s action: %s", kind, exc)

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


def _normalize_event_key(name: str) -> str:
    """Normalize a keyboard-backend event name (e.g. 'left ctrl', 'windows') to a
    canonical token (ctrl, shift, meta, space, ...) matching our hotkey tokens."""
    value = (name or "").strip().lower()
    if value.startswith("left "):
        value = value[5:]
    elif value.startswith("right "):
        value = value[6:]
    return normalize_hotkey_token(value)


def should_suppress_hotkey(ordered_tokens: "tuple[str, ...] | list[str]") -> bool:
    """Suppress (consume) a global hotkey only when it includes a modifier.

    Suppressing a bare single key (e.g. "escape") would block that key system-wide
    and break it in every other app; modifier combos only consume the exact chord.
    """
    return any(token in MODIFIER_TOKENS for token in ordered_tokens)


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
        # When a modifier (esp. Ctrl) is held, pynput delivers a CONTROL character in
        # .char (Ctrl+A -> '\x01'). Map it back to the base letter so the token at press
        # ('\x01') matches the token at release ('a') and the combo can resolve.
        if len(char) == 1 and "\x01" <= char <= "\x1a":
            char = chr(ord(char) - 1 + ord("a"))
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
