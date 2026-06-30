"""Platform-neutral types shared by every OS backend.

Keeping the snapshot type here (rather than in a single OS backend) lets the macOS
and no-op backends produce the same value object the Windows backend does, so callers
never branch on platform.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True, frozen=True)
class ForegroundWindowSnapshot:
    """The app/window that was frontmost when a capture started, so the cleaned text can
    be delivered back to it.

    Field meaning is platform-shaded:
    - Windows: ``hwnd`` is the real window handle; ``process_name`` is e.g. ``code.exe``.
    - macOS: ``hwnd`` is unused (0); ``process_id`` is the app PID and ``process_name`` is
      the bundle identifier (e.g. ``com.microsoft.VSCode``); ``title`` is the app name.
    """

    hwnd: int = 0
    title: str = ""
    process_id: int = 0
    process_name: str = ""
