"""No-op platform backend for OSes without a native integration (e.g. Linux).

Every function degrades safely: the app still runs (transcription, cleanup, UI) but the
OS-specific extras (paste-into-app, native chrome) simply do nothing. This is the typed
contract every backend must satisfy.
"""
from __future__ import annotations

from flowtype.platform._common import ForegroundWindowSnapshot

APP_USER_MODEL_ID = "AntiGravity.FlowType"


def is_windows() -> bool:
    return False


def set_app_user_model_id(app_id: str = APP_USER_MODEL_ID) -> None:
    return None


def set_native_title_bar_colors(hwnd: int, caption_hex: str, text_hex: str, border_hex: str | None = None) -> None:
    return None


def supports_mica() -> bool:
    return False


def set_window_backdrop_material(hwnd: int, dark: bool, material: str = "mica") -> bool:
    return False


def enable_acrylic_blur(hwnd: int, tint_argb: int = 0x140A0E14) -> bool:
    return False


def set_native_window_icon(hwnd: int, icon_path: str) -> None:
    return None


def snapshot_foreground_window() -> ForegroundWindowSnapshot | None:
    return None


def restore_foreground_window(snapshot: ForegroundWindowSnapshot | None) -> bool:
    return False


def is_fullscreen_app_foreground() -> bool:
    return False


def configure_overlay_panel(window) -> bool:
    return False


def prime_permissions() -> None:
    return None


def accessibility_trusted() -> bool:
    return True  # no OS-level gate on this platform
