from __future__ import annotations

import ctypes
import os
import sys
from dataclasses import dataclass
from ctypes import wintypes


APP_USER_MODEL_ID = "AntiGravity.FlowType"
DWMWA_USE_IMMERSIVE_DARK_MODE = 20
DWMWA_BORDER_COLOR = 34
DWMWA_CAPTION_COLOR = 35
DWMWA_TEXT_COLOR = 36
DWMWA_SYSTEMBACKDROP_TYPE = 38

# DWM system backdrop materials (Windows 11)
DWMSBT_AUTO = 0
DWMSBT_NONE = 1
DWMSBT_MAINWINDOW = 2      # Mica
DWMSBT_TRANSIENTWINDOW = 3  # Acrylic
DWMSBT_TABBEDWINDOW = 4     # Mica Alt

# SetWindowCompositionAttribute (acrylic blur-behind, Win10 1803+/Win11)
WCA_ACCENT_POLICY = 19
ACCENT_DISABLED = 0
ACCENT_ENABLE_BLURBEHIND = 3
ACCENT_ENABLE_ACRYLICBLURBEHIND = 4

MICA_MIN_BUILD = 22000
WM_SETICON = 0x0080
ICON_SMALL = 0
ICON_BIG = 1
IMAGE_ICON = 1
LR_LOADFROMFILE = 0x0010
LR_DEFAULTSIZE = 0x0040
GCLP_HICON = -14
GCLP_HICONSM = -34
SW_RESTORE = 9


@dataclass(slots=True, frozen=True)
class ForegroundWindowSnapshot:
    hwnd: int
    title: str = ""
    process_id: int = 0


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


def windows_build() -> int:
    if not is_windows():
        return 0
    try:
        return int(sys.getwindowsversion().build)
    except Exception:
        return 0


def supports_mica() -> bool:
    """Windows 11 (build >= 22000) supports the DWM Mica system backdrop."""
    return is_windows() and windows_build() >= MICA_MIN_BUILD


def set_window_backdrop_material(hwnd: int, dark: bool, material: str = "mica") -> bool:
    """Apply a translucent system backdrop (Mica/Acrylic) to a top-level window.

    Returns True only if the OS accepted it. Callers should fall back to a solid
    window background when this returns False (e.g. on Windows 10).
    """
    if not hwnd or not supports_mica():
        return False
    try:
        dwmapi = ctypes.windll.dwmapi
    except Exception:
        return False

    _set_dwm_int(dwmapi, hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, 1 if dark else 0)
    backdrop = {
        "mica": DWMSBT_MAINWINDOW,
        "mica-alt": DWMSBT_TABBEDWINDOW,
        "acrylic": DWMSBT_TRANSIENTWINDOW,
    }.get(material, DWMSBT_MAINWINDOW)
    return _set_dwm_int(dwmapi, hwnd, DWMWA_SYSTEMBACKDROP_TYPE, backdrop) == 0


def enable_acrylic_blur(hwnd: int, tint_argb: int = 0x140A0E14) -> bool:
    """Frosted acrylic blur-behind for a frameless overlay (the HUD).

    tint_argb is 0xAARRGGBB; it is converted to the ABGR gradient color the
    composition API expects. A low alpha keeps it a subtle frost so the QML fill
    provides the actual color/contrast.
    """
    if not is_windows() or not hwnd:
        return False
    try:
        user32 = ctypes.windll.user32
        set_attr = user32.SetWindowCompositionAttribute
    except Exception:
        return False

    a = (tint_argb >> 24) & 0xFF
    r = (tint_argb >> 16) & 0xFF
    g = (tint_argb >> 8) & 0xFF
    b = tint_argb & 0xFF
    gradient_abgr = (a << 24) | (b << 16) | (g << 8) | r

    class ACCENT_POLICY(ctypes.Structure):
        _fields_ = [
            ("AccentState", ctypes.c_int),
            ("AccentFlags", ctypes.c_int),
            ("GradientColor", ctypes.c_uint),
            ("AnimationId", ctypes.c_int),
        ]

    class WINDOWCOMPOSITIONATTRIBDATA(ctypes.Structure):
        _fields_ = [
            ("Attribute", ctypes.c_int),
            ("Data", ctypes.c_void_p),
            ("SizeOfData", ctypes.c_size_t),
        ]

    try:
        accent = ACCENT_POLICY(ACCENT_ENABLE_ACRYLICBLURBEHIND, 0, gradient_abgr, 0)
        data = WINDOWCOMPOSITIONATTRIBDATA(
            WCA_ACCENT_POLICY, ctypes.cast(ctypes.byref(accent), ctypes.c_void_p), ctypes.sizeof(accent)
        )
        return bool(set_attr(wintypes.HWND(hwnd), ctypes.byref(data)))
    except Exception:
        return False


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


def snapshot_foreground_window() -> ForegroundWindowSnapshot | None:
    if not is_windows():
        return None
    try:
        user32 = ctypes.windll.user32
    except Exception:
        return None

    try:
        hwnd = int(user32.GetForegroundWindow())
    except Exception:
        return None
    if not hwnd:
        return None

    title = _window_title(hwnd)
    process_id = _window_process_id(hwnd)
    return ForegroundWindowSnapshot(hwnd=hwnd, title=title, process_id=process_id)


def restore_foreground_window(snapshot: ForegroundWindowSnapshot | None) -> bool:
    if not is_windows() or snapshot is None or not snapshot.hwnd:
        return False

    try:
        user32 = ctypes.windll.user32
    except Exception:
        return False

    hwnd = wintypes.HWND(snapshot.hwnd)
    try:
        if not bool(user32.IsWindow(hwnd)):
            return False
    except Exception:
        return False

    try:
        if bool(user32.IsIconic(hwnd)):
            user32.ShowWindow(hwnd, SW_RESTORE)
    except Exception:
        pass

    try:
        user32.BringWindowToTop(hwnd)
        user32.SetForegroundWindow(hwnd)
        if int(user32.GetForegroundWindow()) == snapshot.hwnd:
            return True
    except Exception:
        pass

    current_foreground = _safe_foreground_handle(user32)
    current_thread_id = _safe_window_thread_id(user32, current_foreground)
    target_thread_id = _safe_window_thread_id(user32, snapshot.hwnd)
    this_thread_id = _safe_current_thread_id(user32)

    attached_threads: list[int] = []
    try:
        for thread_id in {current_thread_id, target_thread_id}:
            if thread_id and thread_id != this_thread_id:
                try:
                    if bool(user32.AttachThreadInput(this_thread_id, thread_id, True)):
                        attached_threads.append(thread_id)
                except Exception:
                    continue

        try:
            user32.BringWindowToTop(hwnd)
            user32.SetForegroundWindow(hwnd)
            user32.SetFocus(hwnd)
            user32.SetActiveWindow(hwnd)
        except Exception:
            pass
    finally:
        for thread_id in attached_threads:
            try:
                user32.AttachThreadInput(this_thread_id, thread_id, False)
            except Exception:
                continue

    try:
        return int(user32.GetForegroundWindow()) == snapshot.hwnd
    except Exception:
        return False

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


def _set_dwm_int(dwmapi, hwnd: int, attribute: int, value: int) -> int:
    """Set an integer/BOOL DWM window attribute. Returns the HRESULT (0 == success)."""
    data = ctypes.c_int(int(value))
    try:
        return int(
            dwmapi.DwmSetWindowAttribute(
                wintypes.HWND(hwnd),
                ctypes.c_uint(attribute),
                ctypes.byref(data),
                ctypes.sizeof(data),
            )
        )
    except Exception:
        return -1


def _hex_to_colorref(value: str) -> int:
    normalized = value.lstrip("#")
    if len(normalized) != 6:
        return 0
    red = int(normalized[0:2], 16)
    green = int(normalized[2:4], 16)
    blue = int(normalized[4:6], 16)
    return red | (green << 8) | (blue << 16)


def _window_title(hwnd: int) -> str:
    try:
        user32 = ctypes.windll.user32
        length = int(user32.GetWindowTextLengthW(wintypes.HWND(hwnd)))
        buffer = ctypes.create_unicode_buffer(max(length + 1, 1))
        user32.GetWindowTextW(wintypes.HWND(hwnd), buffer, len(buffer))
        return buffer.value.strip()
    except Exception:
        return ""


def _window_process_id(hwnd: int) -> int:
    try:
        user32 = ctypes.windll.user32
        process_id = wintypes.DWORD()
        user32.GetWindowThreadProcessId(wintypes.HWND(hwnd), ctypes.byref(process_id))
        return int(process_id.value)
    except Exception:
        return 0


def _safe_foreground_handle(user32) -> int:
    try:
        return int(user32.GetForegroundWindow())
    except Exception:
        return 0


def _safe_window_thread_id(user32, hwnd: int) -> int:
    if not hwnd:
        return 0
    try:
        return int(user32.GetWindowThreadProcessId(wintypes.HWND(hwnd), None))
    except Exception:
        return 0


def _safe_current_thread_id(user32) -> int:
    try:
        return int(user32.GetCurrentThreadId())
    except Exception:
        return 0
