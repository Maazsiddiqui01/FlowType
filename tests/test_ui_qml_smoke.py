from __future__ import annotations

import os
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication

from flowtype.config import load_config, write_default_config
from flowtype.ui.controller import AppController


class StubPipeline:
    def __init__(self, config) -> None:
        self.config = config
        self.status = "ready"

    def toggle_recording(self) -> None:
        self.status = "recording" if self.status != "recording" else "ready"

    def repaste_last(self) -> None:
        return None


def _build_controller(config_path: Path) -> AppController:
    current = {"config": load_config(config_path)}

    def reload_runtime():
        current["config"] = load_config(config_path)
        return current["config"], StubPipeline(current["config"])

    return AppController(
        config=current["config"],
        pipeline=StubPipeline(current["config"]),
        runtime_reloader=reload_runtime,
    )


def _app() -> QApplication:
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    QQuickStyle.setStyle("Basic")
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    return app


def test_main_qml_loads_with_real_controller(tmp_path: Path) -> None:
    _app()
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = _build_controller(config_path)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("AppController", controller)
    engine.rootContext().setContextProperty("StartHidden", False)

    qml_path = Path(__file__).resolve().parents[1] / "src" / "flowtype" / "ui" / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    assert engine.rootObjects(), "Main.qml should load successfully with the real controller API"
