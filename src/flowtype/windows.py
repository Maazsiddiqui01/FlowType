from __future__ import annotations

import ctypes
import os
from ctypes import wintypes


APP_USER_MODEL_ID = "AntiGravity.FlowType"
DWMWA_BORDER_COLOR = 34
DWMWA_CAPTION_COLOR = 35
DWMWA_TEXT_COLOR = 36
WM_SETICON = 0x0080
ICON_SMALL = 0
ICON_BIG = 1
IMAGE_ICON = 1
LR_LOADFROMFILE = 0x0010
LR_DEFAULTSIZE = 0x0040
GCLP_HICON = -14
GCLP_HICONSM = -34


def is_windows() -> bool:
    return os.name == "nt"


def set_app_user_model_id(app_id: str = APP_USER_MODEL_ID) -> None:
    if not is_windows():
        return
    try:
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(app_id)
    except Exception:
        return


def set_native_title_bar_colors(hwnd: int, caption_hex: str, text_hex: str, border_hex: str | None = None) -> None:
    if not is_windows() or not hwnd:
        return
    try:
        dwmapi = ctypes.windll.dwmapi
    except Exception:
        return

    _set_dwm_color(dwmapi, hwnd, DWMWA_CAPTION_COLOR, _hex_to_colorref(caption_hex))
    _set_dwm_color(dwmapi, hwnd, DWMWA_TEXT_COLOR, _hex_to_colorref(text_hex))
    if border_hex:
        _set_dwm_color(dwmapi, hwnd, DWMWA_BORDER_COLOR, _hex_to_colorref(border_hex))


def set_native_window_icon(hwnd: int, icon_path: str) -> None:
    if not is_windows() or not hwnd or not icon_path:
        return
    try:
        user32 = ctypes.windll.user32
    except Exception:
        return

    try:
        load_image = user32.LoadImageW
        load_image.restype = wintypes.HANDLE
        handle = load_image(
            None,
            icon_path,
            IMAGE_ICON,
            0,
            0,
            LR_LOADFROMFILE | LR_DEFAULTSIZE,
        )
        if not handle:
            return

        user32.SendMessageW(wintypes.HWND(hwnd), WM_SETICON, ICON_SMALL, handle)
        user32.SendMessageW(wintypes.HWND(hwnd), WM_SETICON, ICON_BIG, handle)
        try:
            user32.SetClassLongPtrW(wintypes.HWND(hwnd), GCLP_HICON, handle)
            user32.SetClassLongPtrW(wintypes.HWND(hwnd), GCLP_HICONSM, handle)
        except Exception:
            return
    except Exception:
        return


def _set_dwm_color(dwmapi, hwnd: int, attribute: int, colorref: int) -> None:
    value = wintypes.DWORD(colorref)
    try:
        dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(hwnd),
            ctypes.c_uint(attribute),
            ctypes.byref(value),
            ctypes.sizeof(value),
        )
    except Exception:
        return


def _hex_to_colorref(value: str) -> int:
    normalized = value.lstrip("#")
    if len(normalized) != 6:
        return 0
    red = int(normalized[0:2], 16)
    green = int(normalized[2:4], 16)
    blue = int(normalized[4:6], 16)
    return red | (green << 8) | (blue << 16)
