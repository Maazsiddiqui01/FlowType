"""OS platform-integration seam.

Callers import the OS-specific contract from here (``from flowtype.platform import
snapshot_foreground_window``) and never branch on the platform themselves. The right
backend is selected once, at import, by ``sys.platform``:

- ``win32``  -> .windows  (DWM chrome, Win32 foreground, DPAPI lives in keystore)
- ``darwin`` -> .darwin   (AppKit foreground, pyobjc; chrome no-ops in v1)
- else       -> .base     (typed no-ops; app still runs, OS extras do nothing)
"""
from __future__ import annotations

import sys

from flowtype.platform._common import ForegroundWindowSnapshot

if sys.platform == "win32":
    from flowtype.platform import windows as _backend
elif sys.platform == "darwin":
    from flowtype.platform import darwin as _backend
else:
    from flowtype.platform import base as _backend

# Re-export the contract from the active backend.
is_windows = _backend.is_windows
set_app_user_model_id = _backend.set_app_user_model_id
set_native_title_bar_colors = _backend.set_native_title_bar_colors
supports_mica = _backend.supports_mica
set_window_backdrop_material = _backend.set_window_backdrop_material
enable_acrylic_blur = _backend.enable_acrylic_blur
set_native_window_icon = _backend.set_native_window_icon
snapshot_foreground_window = _backend.snapshot_foreground_window
restore_foreground_window = _backend.restore_foreground_window
is_fullscreen_app_foreground = _backend.is_fullscreen_app_foreground

__all__ = [
    "ForegroundWindowSnapshot",
    "is_windows",
    "set_app_user_model_id",
    "set_native_title_bar_colors",
    "supports_mica",
    "set_window_backdrop_material",
    "enable_acrylic_blur",
    "set_native_window_icon",
    "snapshot_foreground_window",
    "restore_foreground_window",
    "is_fullscreen_app_foreground",
]
