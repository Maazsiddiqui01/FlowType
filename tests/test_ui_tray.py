from __future__ import annotations

from pathlib import Path

from flowtype.ui.system_tray import UiTrayController


def _noop() -> None:
    return None


def _make(hint_flag_path: Path | None) -> UiTrayController:
    return UiTrayController(
        show_window_callback=_noop,
        open_settings_callback=_noop,
        open_app_folder_callback=_noop,
        open_logs_callback=_noop,
        quit_callback=_noop,
        hint_flag_path=hint_flag_path,
    )


def test_tray_hint_not_marked_shown_on_fresh_flag(tmp_path: Path) -> None:
    ctrl = _make(tmp_path / "tray_hint_shown")
    assert ctrl._close_hint_shown is False


def test_tray_hint_suppressed_when_flag_exists(tmp_path: Path) -> None:
    flag = tmp_path / "tray_hint_shown"
    flag.write_text("1", encoding="utf-8")
    ctrl = _make(flag)
    # A prior run already showed the hint -> never show again.
    assert ctrl._close_hint_shown is True


def test_persist_hint_creates_flag(tmp_path: Path) -> None:
    flag = tmp_path / "sub" / "tray_hint_shown"
    ctrl = _make(flag)
    ctrl._persist_hint_shown()
    assert flag.exists()
    # A controller built afterwards treats the hint as already shown.
    assert _make(flag)._close_hint_shown is True
