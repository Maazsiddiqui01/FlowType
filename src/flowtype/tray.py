from __future__ import annotations

import importlib
import logging
import os
from pathlib import Path

from flowtype.branding import tray_icon_path


STATUS_COLORS = {
    "ready": "#2563eb",
    "recording": "#dc2626",
    "processing": "#d97706",
    "stopped": "#475569",
    "starting": "#0f172a",
}


class TrayController:
    def __init__(
        self,
        config_path: Path,
        log_path: Path,
        open_settings_callback=None,
        open_app_folder_callback=None,
        quit_callback=None,
        logger: logging.Logger | None = None,
    ) -> None:
        self.config_path = config_path
        self.log_path = log_path
        self.open_settings_callback = open_settings_callback
        self.open_app_folder_callback = open_app_folder_callback
        self.quit_callback = quit_callback
        self.logger = logger or logging.getLogger("flowtype.tray")
        self._pystray = None
        self._image_module = None
        self._draw_module = None
        self._icon = None
        self._pipeline = None
        self._on_ready = None
        self._status = "starting"
        self._detail = "Starting..."

    def bind_pipeline(self, pipeline) -> None:
        self._pipeline = pipeline

    def update_paths(self, config_path: Path, log_path: Path) -> None:
        self.config_path = config_path
        self.log_path = log_path

    def set_status(self, status: str, detail: str) -> None:
        self._status = status
        self._detail = detail
        if self._icon is not None:
            self._icon.title = f"FlowType - {detail}"
            self._icon.icon = self._build_image(status)

    def run(self, on_ready=None) -> None:
        self._on_ready = on_ready
        pystray = self._load_pystray()
        self._icon = pystray.Icon(
            "FlowType",
            icon=self._build_image(self._status),
            title=f"FlowType - {self._detail}",
            menu=pystray.Menu(
                pystray.MenuItem("Settings", self._open_settings),
                pystray.MenuItem("Open App Folder", self._open_app_folder),
                pystray.MenuItem("Open Logs", self._open_logs),
                pystray.MenuItem("Quit", self._quit),
            ),
        )
        self._icon.run(setup=self._setup)

    def _setup(self, icon) -> None:
        del icon
        if self._on_ready is not None:
            self._on_ready()
        elif self._pipeline is not None:
            self._pipeline.start()
            self.set_status("ready", "Ready")

    def _quit(self, icon, item) -> None:
        del item
        if self.quit_callback is not None:
            self.quit_callback()
        elif self._pipeline is not None:
            self._pipeline.stop()
        icon.stop()

    def _open_settings(self, icon, item) -> None:
        del icon, item
        if self.open_settings_callback is not None:
            self.open_settings_callback()
            return
        self._open_path(self.config_path)

    def _open_app_folder(self, icon, item) -> None:
        del icon, item
        if self.open_app_folder_callback is not None:
            self.open_app_folder_callback()
            return
        self._open_path(self.config_path.parent)

    def _open_logs(self, icon, item) -> None:
        del icon, item
        self._open_path(self.log_path.parent)

    def _open_path(self, path: Path) -> None:
        try:
            os.startfile(str(path))  # type: ignore[attr-defined]
        except Exception as exc:  # pragma: no cover - OS integration
            self.logger.warning("Could not open %s: %s", path, exc)

    def _build_image(self, status: str):
        image_module, draw_module = self._load_pillow()
        branded_asset = tray_icon_path(status)
        if branded_asset.exists():
            return image_module.open(branded_asset).convert("RGBA")
        image = image_module.new("RGBA", (64, 64), (0, 0, 0, 0))
        draw = draw_module.Draw(image)
        color = STATUS_COLORS.get(status, STATUS_COLORS["starting"])
        draw.rounded_rectangle((8, 8, 56, 56), radius=14, fill=color)
        draw.rectangle((20, 20, 44, 44), fill="white")
        return image

    def _load_pystray(self):
        if self._pystray is None:
            try:
                self._pystray = importlib.import_module("pystray")
            except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
                raise RuntimeError("pystray is not installed. Run `python -m pip install -e .` first.") from exc
        return self._pystray

    def _load_pillow(self):
        if self._image_module is None or self._draw_module is None:
            try:
                image_module = importlib.import_module("PIL.Image")
                draw_module = importlib.import_module("PIL.ImageDraw")
            except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
                raise RuntimeError("Pillow is not installed. Run `python -m pip install -e .` first.") from exc
            self._image_module = image_module
            self._draw_module = draw_module
        return self._image_module, self._draw_module
