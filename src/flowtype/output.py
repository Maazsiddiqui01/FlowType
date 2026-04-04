from __future__ import annotations

import importlib
import logging
import sys
import time
from dataclasses import dataclass

from flowtype.config import OutputConfig
from flowtype.windows import ForegroundWindowSnapshot, restore_foreground_window


MIN_CTRL_V_DELAY_MS = 180
CLIPBOARD_RESTORE_DELAY_SECONDS = 0.5
MODIFIER_KEY_NAMES = (
    "ctrl",
    "shift",
    "shift_l",
    "shift_r",
    "alt",
    "alt_l",
    "alt_r",
    "alt_gr",
    "cmd",
    "cmd_l",
    "cmd_r",
)


@dataclass(slots=True, frozen=True)
class DeliveryResult:
    copied: bool
    pasted: bool
    delivery_state: str = "none"
    target_restored: bool = False
    target_title: str = ""
    failure_reason: str = ""


class OutputDelivery:
    def __init__(self, settings: OutputConfig, logger: logging.Logger | None = None) -> None:
        self.settings = settings
        self.logger = logger or logging.getLogger("flowtype.output")
        self._keyboard_controller = None
        self._keyboard_key = None

    def deliver(self, text: str, target: ForegroundWindowSnapshot | None = None) -> DeliveryResult:
        text = text.strip()
        if not text:
            return DeliveryResult(copied=False, pasted=False, delivery_state="none")

        pyperclip = self._load_pyperclip()
        previous_clipboard = None
        if self.settings.restore_clipboard:
            try:
                previous_clipboard = pyperclip.paste()
            except Exception:
                previous_clipboard = None

        pyperclip.copy(text)
        time.sleep(self._paste_delay_seconds())

        pasted = False
        target_restored = False
        failure_reason = ""
        target_title = target.title if target is not None else ""
        if self.settings.paste_method == "ctrl_v":
            if target is not None:
                target_restored = self._restore_target(target)
                if not target_restored:
                    failure_reason = "Could not return focus to the original app. FlowType kept the result in the clipboard."
                    self.logger.warning(
                        "Skipping automatic paste because the original target could not be restored | hwnd=%s title=%s",
                        target.hwnd,
                        target.title or "<untitled>",
                    )
                    return DeliveryResult(
                        copied=True,
                        pasted=False,
                        delivery_state="copied_only",
                        target_restored=False,
                        target_title=target_title,
                        failure_reason=failure_reason,
                    )
            pasted = self._paste_via_keyboard()
            if pasted and target is None:
                target_restored = True
            if not pasted:
                failure_reason = "Automatic paste failed. FlowType kept the result in the clipboard."

        if self.settings.restore_clipboard and previous_clipboard is not None and pasted:
            time.sleep(CLIPBOARD_RESTORE_DELAY_SECONDS)
            pyperclip.copy(previous_clipboard)

        return DeliveryResult(
            copied=True,
            pasted=pasted,
            delivery_state="pasted" if pasted else "copied_only",
            target_restored=target_restored,
            target_title=target_title,
            failure_reason=failure_reason,
        )

    def copy_to_clipboard(self, text: str) -> bool:
        normalized = text.strip()
        if not normalized:
            return False
        pyperclip = self._load_pyperclip()
        pyperclip.copy(normalized)
        return True

    def _paste_via_keyboard(self) -> bool:
        controller, key = self._load_keyboard()
        try:
            self._release_hotkey_modifiers(controller, key)
            time.sleep(0.05)
            controller.press(key.ctrl)
            controller.press("v")
            controller.release("v")
            controller.release(key.ctrl)
            return True
        except Exception as exc:  # pragma: no cover - depends on active desktop
            self.logger.warning(
                "Automatic paste failed; transcript remains in the clipboard: %s",
                exc,
            )
            return False

    def _load_pyperclip(self):
        try:
            return importlib.import_module("pyperclip")
        except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
            if getattr(sys, "frozen", False):
                raise RuntimeError(
                    "Clipboard components are missing from this FlowType install. Reinstall the latest build."
                ) from exc
            raise RuntimeError("pyperclip is not installed. Run `python -m pip install -e .` first.") from exc

    def _load_keyboard(self):
        if self._keyboard_controller is not None and self._keyboard_key is not None:
            return self._keyboard_controller, self._keyboard_key

        try:
            keyboard = importlib.import_module("pynput.keyboard")
        except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
            if getattr(sys, "frozen", False):
                raise RuntimeError(
                    "Keyboard automation components are missing from this FlowType install. Reinstall the latest build."
                ) from exc
            raise RuntimeError("pynput is not installed. Run `python -m pip install -e .` first.") from exc

        self._keyboard_controller = keyboard.Controller()
        self._keyboard_key = keyboard.Key
        return self._keyboard_controller, self._keyboard_key

    def _paste_delay_seconds(self) -> float:
        if self.settings.paste_method == "ctrl_v":
            return max(self.settings.paste_delay_ms, MIN_CTRL_V_DELAY_MS) / 1000
        return self.settings.paste_delay_ms / 1000

    def _release_hotkey_modifiers(self, controller, key) -> None:
        for key_name in MODIFIER_KEY_NAMES:
            key_value = getattr(key, key_name, None)
            if key_value is None:
                continue
            try:
                controller.release(key_value)
            except Exception:
                continue

    def _restore_target(self, target: ForegroundWindowSnapshot) -> bool:
        return restore_foreground_window(target)
