from __future__ import annotations

import sys
from pathlib import Path


APP_DISPLAY_NAME = "FlowType"
APP_PUBLISHER = "AntiGravity"
APP_DESCRIPTION = "Local dictation for Windows"

_STATUS_ICON_NAMES = {
    "ready": "tray-ready.png",
    "recording": "tray-recording.png",
    "transcribing": "tray-processing.png",
    "cleaning": "tray-processing.png",
    "pasting": "tray-processing.png",
    "processing": "tray-processing.png",
    "error": "tray-error.png",
    "stopped": "tray-ready.png",
    "starting": "tray-ready.png",
}


def assets_dir() -> Path:
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / "flowtype" / "assets" / "branding"
    return Path(__file__).resolve().parent / "assets" / "branding"


def app_icon_path() -> Path:
    return assets_dir() / "app-icon.ico"


def logo_mark_path() -> Path:
    return assets_dir() / "logo-mark.png"


def tray_icon_path(status: str) -> Path:
    return assets_dir() / _STATUS_ICON_NAMES.get(status, "tray-ready.png")


def installer_icon_path(project_root: Path) -> Path:
    return project_root / "build" / "branding" / "app-icon.ico"


def installer_small_bitmap_path(project_root: Path) -> Path:
    return project_root / "build" / "branding" / "installer-small.bmp"


def installer_wide_bitmap_path(project_root: Path) -> Path:
    return project_root / "build" / "branding" / "installer-wide.bmp"
