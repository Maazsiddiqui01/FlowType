from __future__ import annotations

from types import SimpleNamespace

from flowtype.windows import _rect_covers_monitor


def _rect(left, top, right, bottom):
    return SimpleNamespace(left=left, top=top, right=right, bottom=bottom)


def test_fullscreen_window_covers_monitor() -> None:
    mon = _rect(0, 0, 1920, 1080)
    # Exact full-monitor (borderless fullscreen video) and slightly-larger (exclusive).
    assert _rect_covers_monitor(_rect(0, 0, 1920, 1080), mon) is True
    assert _rect_covers_monitor(_rect(-1, -1, 1921, 1081), mon) is True


def test_maximized_window_leaving_taskbar_is_not_fullscreen() -> None:
    mon = _rect(0, 0, 1920, 1080)
    # Maximized leaves the taskbar visible (bottom < monitor bottom) -> not fullscreen.
    assert _rect_covers_monitor(_rect(0, 0, 1920, 1032), mon) is False


def test_small_window_is_not_fullscreen() -> None:
    mon = _rect(0, 0, 1920, 1080)
    assert _rect_covers_monitor(_rect(100, 100, 800, 600), mon) is False


def test_second_monitor_offset_fullscreen() -> None:
    mon = _rect(1920, 0, 3840, 1080)
    assert _rect_covers_monitor(_rect(1920, 0, 3840, 1080), mon) is True
    assert _rect_covers_monitor(_rect(1920, 0, 3000, 1080), mon) is False
