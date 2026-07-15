from __future__ import annotations

import logging
from pathlib import Path
from typing import Callable

from PySide6.QtGui import QAction, QIcon
from PySide6.QtWidgets import QMenu, QSystemTrayIcon

from flowtype.branding import APP_DISPLAY_NAME, app_icon_path, tray_icon_path


class UiTrayController:
    def __init__(
        self,
        *,
        show_window_callback: Callable[[], None],
        open_settings_callback: Callable[[], None],
        open_app_folder_callback: Callable[[], None],
        open_logs_callback: Callable[[], None],
        quit_callback: Callable[[], None],
        hint_flag_path: Path | None = None,
        logger: logging.Logger | None = None,
    ) -> None:
        self._logger = logger or logging.getLogger("flowtype.ui.tray")
        self._show_window_callback = show_window_callback
        self._open_settings_callback = open_settings_callback
        self._open_app_folder_callback = open_app_folder_callback
        self._open_logs_callback = open_logs_callback
        self._quit_callback = quit_callback
        self._status = "starting"
        self._detail = "Starting FlowType..."
        # Persisted so the "minimized to tray" hint appears at most once, ever —
        # not on every launch. Falls back to per-run only if no path is given.
        self._hint_flag_path = hint_flag_path
        self._close_hint_shown = self._hint_flag_path.exists() if self._hint_flag_path else False
        self._icon: QSystemTrayIcon | None = None

    @property
    def available(self) -> bool:
        return bool(self._icon is not None)

    def start(self) -> None:
        if not QSystemTrayIcon.isSystemTrayAvailable():
            self._logger.warning("System tray is not available; close-to-tray will be disabled.")
            return

        self._icon = QSystemTrayIcon()
        self._icon.setIcon(self._icon_for_status(self._status))
        self._icon.setToolTip(f"{APP_DISPLAY_NAME} - {self._detail}")
        self._icon.setContextMenu(self._build_menu())
        self._icon.activated.connect(self._handle_activation)
        self._icon.show()

    def stop(self) -> None:
        if self._icon is None:
            return
        self._icon.hide()
        self._icon.deleteLater()
        self._icon = None

    def set_status(self, status: str, detail: str) -> None:
        self._status = status
        self._detail = detail
        if self._icon is None:
            return
        self._icon.setIcon(self._icon_for_status(status))
        self._icon.setToolTip(f"{APP_DISPLAY_NAME} - {detail}")

    def show_hidden_hint_once(self) -> None:
        if self._icon is None or self._close_hint_shown:
            return
        self._close_hint_shown = True
        self._persist_hint_shown()
        # Use the FlowType logo (not the generic system "info" glyph) and keep the
        # copy short. Windows attributes it to "FlowType" via the AppUserModelID.
        icon_path = app_icon_path()
        icon = QIcon(str(icon_path)) if icon_path.exists() else QSystemTrayIcon.MessageIcon.Information
        self._icon.showMessage(
            APP_DISPLAY_NAME,
            "Still running in the tray — click the icon to reopen or quit.",
            icon,
            3500,
        )

    def _persist_hint_shown(self) -> None:
        if self._hint_flag_path is None:
            return
        try:
            self._hint_flag_path.parent.mkdir(parents=True, exist_ok=True)
            self._hint_flag_path.write_text("1", encoding="utf-8")
        except Exception as exc:  # pragma: no cover - best-effort flag
            self._logger.debug("Could not persist tray hint flag: %s", exc)

    def _build_menu(self) -> QMenu:
        menu = QMenu()

        open_action = QAction("Open FlowType", menu)
        open_action.triggered.connect(lambda: self._show_window_callback())
        menu.addAction(open_action)

        settings_action = QAction("Settings", menu)
        settings_action.triggered.connect(lambda: self._open_settings_callback())
        menu.addAction(settings_action)

        menu.addSeparator()

        app_folder_action = QAction("Open App Folder", menu)
        app_folder_action.triggered.connect(lambda: self._open_app_folder_callback())
        menu.addAction(app_folder_action)

        logs_action = QAction("Open Logs", menu)
        logs_action.triggered.connect(lambda: self._open_logs_callback())
        menu.addAction(logs_action)

        menu.addSeparator()

        quit_action = QAction("Quit", menu)
        quit_action.triggered.connect(lambda: self._quit_callback())
        menu.addAction(quit_action)
        return menu

    def _handle_activation(self, reason: QSystemTrayIcon.ActivationReason) -> None:
        if reason in {
            QSystemTrayIcon.ActivationReason.Trigger,
            QSystemTrayIcon.ActivationReason.DoubleClick,
        }:
            self._show_window_callback()

    def _icon_for_status(self, status: str) -> QIcon:
        asset = tray_icon_path(status)
        if asset.exists():
            return QIcon(str(asset))
        fallback = app_icon_path()
        return QIcon(str(fallback))
