from __future__ import annotations

import logging
import sys
import threading
from pathlib import Path
from typing import Any, Callable

from PySide6.QtCore import QEvent, QObject, QTimer
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtGui import QFont, QFontDatabase, QIcon
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication

from flowtype.audio import AudioRecorder
from flowtype.branding import APP_DISPLAY_NAME, APP_PUBLISHER, app_icon_path
from flowtype.cleanup import TextCleaner
from flowtype.config import AppConfig, load_config, load_config_data, save_config_data
from flowtype.output import OutputDelivery
from flowtype.pipeline import DictationPipeline
from flowtype.startup import sync_launch_at_login
from flowtype.transcriber import Transcriber
from flowtype.ui.controller import AppController
from flowtype.ui.single_instance import SingleInstanceManager
from flowtype.ui.system_tray import UiTrayController
from flowtype.windows import set_app_user_model_id, set_native_title_bar_colors, set_native_window_icon

logger = logging.getLogger("flowtype.ui.app")


def _font_asset_path() -> Path | None:
    candidate = Path(__file__).resolve().parent.parent / "assets" / "fonts" / "Inter.ttf"
    if candidate.exists():
        return candidate
    return None


class WindowCloseInterceptor(QObject):
    def __init__(
        self,
        controller: AppController,
        tray: UiTrayController,
        quit_callback: Callable[[], None],
        logger_: logging.Logger | None = None,
    ) -> None:
        super().__init__()
        self._controller = controller
        self._tray = tray
        self._quit_callback = quit_callback
        self._logger = logger_ or logger
        self._allow_exit = False

    def allow_exit(self) -> None:
        self._allow_exit = True

    def eventFilter(self, watched: QObject, event: QEvent) -> bool:  # pragma: no cover - GUI integration
        if event.type() == QEvent.Type.Close and not self._allow_exit:
            if self._controller.closeToTray and self._tray.available:
                event.ignore()
                if hasattr(watched, "hide"):
                    watched.hide()
                self._tray.show_hidden_hint_once()
                return True
            event.ignore()
            self._quit_callback()
            return True
        return super().eventFilter(watched, event)


def run_ui_mode(
    config: AppConfig,
    parent_logger: logging.Logger,
    components: Any,
    start_warmup: Callable[[], None],
    *,
    start_hidden: bool = False,
    activation_message: str = "show",
) -> int:
    QQuickStyle.setStyle("Basic")
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    app.setApplicationName(APP_DISPLAY_NAME)
    app.setOrganizationName(APP_PUBLISHER)
    set_app_user_model_id()

    font_family = "Segoe UI Variable Text"
    font_path = _font_asset_path()
    if not QFontDatabase.hasFamily(font_family) and font_path is not None:
        font_id = QFontDatabase.addApplicationFont(str(font_path))
        families = QFontDatabase.applicationFontFamilies(font_id) if font_id >= 0 else []
        if families:
            font_family = families[0]
    app.setFont(QFont(font_family, 10))

    icon_path = app_icon_path()
    if icon_path.exists():
        app_icon = QIcon(str(icon_path))
        app.setWindowIcon(app_icon)
    else:
        app_icon = QIcon()

    instance = SingleInstanceManager(parent=app)
    try:
        acquired = instance.try_acquire(activation_message)
    except RuntimeError as exc:
        parent_logger.error("Single-instance setup failed: %s", exc)
        return 1
    if not acquired:
        return 0

    runtime: dict[str, Any] = {
        "config": config,
        "components": components,
        "pipeline": None,
    }

    try:
        engine = QQmlApplicationEngine()
        engine.rootContext().setContextProperty("StartHidden", start_hidden)

        def build_components_for(config_: AppConfig):
            return type(components)(
                recorder=AudioRecorder(config_.audio, logger=parent_logger.getChild("audio")),
                transcriber=Transcriber(config_.transcription, logger=parent_logger.getChild("transcriber")),
                cleaner=TextCleaner(config_.cleanup, logger=parent_logger.getChild("cleanup")),
                output=OutputDelivery(config_.output, logger=parent_logger.getChild("output")),
            )

        def apply_transcriber_runtime_fallbacks(transcriber: Any, config_path: Path) -> None:
            notice = getattr(transcriber, "consume_runtime_notice", lambda: "")()
            if notice:
                parent_logger.warning(notice)
                controller.pipeline_notification_callback(notice, "info")

            consume = getattr(transcriber, "consume_persist_cpu_requested", None)
            if consume is None or not consume():
                return
            try:
                loaded_path, data = load_config_data(config_path)
                data.setdefault("transcription", {})
                if str(data["transcription"].get("device", "auto")).strip().lower() == "auto":
                    data["transcription"]["device"] = "cpu"
                    data["transcription"]["compute_type"] = "int8"
                    save_config_data(loaded_path, data)
                    parent_logger.warning("Persisted CPU transcription fallback after warm-up inference failure")
            except Exception as exc:
                parent_logger.exception("Failed to persist CPU fallback after warm-up: %s", exc)

        def start_background_warmup_for(config_path_: Path, components_: Any) -> None:
            def warm_up() -> None:
                try:
                    components_.transcriber.warm_up()
                    apply_transcriber_runtime_fallbacks(components_.transcriber, config_path_)
                    parent_logger.info(
                        "Transcriber warm-up finished using device=%s compute_type=%s",
                        components_.transcriber.used_device or "unknown",
                        components_.transcriber.used_compute_type or "unknown",
                    )
                except Exception as exc:
                    parent_logger.warning("Transcriber warm-up failed: %s", exc)

            thread = threading.Thread(target=warm_up, name="ui-transcriber-warmup", daemon=True)
            thread.start()

        def build_pipeline(config_: AppConfig, components_: Any) -> DictationPipeline:
            return DictationPipeline(
                config=config_,
                recorder=components_.recorder,
                transcriber=components_.transcriber,
                cleaner=components_.cleaner,
                output=components_.output,
                logger=parent_logger.getChild("pipeline"),
            )

        pipeline = build_pipeline(config, components)

        controller = AppController(
            config=config,
            pipeline=pipeline,
            runtime_reloader=lambda: reload_runtime(),
            logger_=parent_logger.getChild("controller"),
        )

        def connect_pipeline(pipeline_: DictationPipeline) -> None:
            pipeline_.status_callback = controller.pipeline_status_callback
            pipeline_.audio_level_callback = controller.pipeline_audio_level_callback
            pipeline_.result_callback = controller.pipeline_result_callback
            pipeline_.notification_callback = controller.pipeline_notification_callback

        def reload_runtime() -> tuple[AppConfig, DictationPipeline]:
            new_config = load_config(runtime["config"].config_path)
            new_components = build_components_for(new_config)
            new_pipeline = build_pipeline(new_config, new_components)
            connect_pipeline(new_pipeline)

            old_pipeline = runtime["pipeline"]
            runtime["config"] = new_config
            runtime["components"] = new_components
            runtime["pipeline"] = new_pipeline

            if old_pipeline is not None:
                old_pipeline.stop()

            sync_launch_at_login(new_config)
            start_background_warmup_for(new_config.config_path, new_components)
            new_pipeline.start()
            return new_config, new_pipeline

        connect_pipeline(pipeline)
        runtime["pipeline"] = pipeline
        engine.rootContext().setContextProperty("AppController", controller)

        qml_file = Path(__file__).resolve().parent / "qml" / "Main.qml"
        engine.load(str(qml_file))
        if not engine.rootObjects():
            parent_logger.error("Failed to load Main.qml. Exiting.")
            return 1

        hud_engine = QQmlApplicationEngine()
        hud_engine.rootContext().setContextProperty("AppController", controller)
        hud_qml_file = Path(__file__).resolve().parent / "qml" / "HUDWindow.qml"
        hud_engine.load(str(hud_qml_file))
        if not hud_engine.rootObjects():
            parent_logger.error("Failed to load HUDWindow.qml. Exiting.")
            return 1

        result_engine = QQmlApplicationEngine()
        result_engine.rootContext().setContextProperty("AppController", controller)
        result_qml_file = Path(__file__).resolve().parent / "qml" / "ResultWindow.qml"
        result_engine.load(str(result_qml_file))
        if not result_engine.rootObjects():
            parent_logger.error("Failed to load ResultWindow.qml. Exiting.")
            return 1

        window = engine.rootObjects()[0]
        hud_window = hud_engine.rootObjects()[0]
        result_window = result_engine.rootObjects()[0]
        if app_icon and hasattr(window, "setIcon"):
            window.setIcon(app_icon)
        if app_icon and hasattr(hud_window, "setIcon"):
            hud_window.setIcon(app_icon)
        if app_icon and hasattr(result_window, "setIcon"):
            result_window.setIcon(app_icon)

        def reposition_overlay(overlay_window: Any) -> None:
            try:
                target_screen = overlay_window.screen() or window.screen() or app.primaryScreen()
            except Exception:
                target_screen = app.primaryScreen()
            if target_screen is None:
                return

            rect = target_screen.availableGeometry()
            width = int(overlay_window.width())
            height = int(overlay_window.height())
            margin = 12
            centered_x = rect.x() + max(0, round((rect.width() - width) / 2))
            top_docked = str(controller.hudPosition).strip().lower() == "top"
            y = rect.y() + margin if top_docked else rect.y() + rect.height() - height - margin
            overlay_window.setX(centered_x)
            overlay_window.setY(y)

        def reposition_hud() -> None:
            reposition_overlay(hud_window)
            reposition_overlay(result_window)

        def show_main_window(page_index: int | None = None) -> None:
            if page_index is not None:
                window.setProperty("currentPage", page_index)
            if hasattr(window, "setVisible") and not window.isVisible():
                window.setVisible(True)
            if hasattr(window, "showNormal"):
                window.showNormal()
            apply_window_branding()
            if hasattr(window, "raise_"):
                window.raise_()
            if hasattr(window, "requestActivate"):
                window.requestActivate()

        def quit_app() -> None:
            interceptor.allow_exit()
            tray.stop()
            app.quit()

        tray = UiTrayController(
            show_window_callback=lambda: show_main_window(),
            open_settings_callback=lambda: show_main_window(6),
            open_app_folder_callback=controller.openAppDirectory,
            open_logs_callback=controller.openLogsDirectory,
            quit_callback=lambda: quit_app(),
            logger=parent_logger.getChild("tray"),
        )
        tray.start()
        tray.set_status(controller.status, controller.detail)
        controller.stateChanged.connect(lambda: tray.set_status(controller.status, controller.detail))

        interceptor = WindowCloseInterceptor(controller, tray, quit_app, parent_logger.getChild("window"))
        window.installEventFilter(interceptor)

        def apply_window_branding() -> None:
            dark_mode = bool(controller.darkMode)
            caption_color = "#0c0e14" if dark_mode else "#eef4ff"
            text_color = "#f0f4f8" if dark_mode else "#10243a"
            border_color = "#1a2030" if dark_mode else "#c7d7eb"
            try:
                hwnd = int(window.winId())
            except Exception:
                hwnd = 0
            if hwnd:
                set_native_title_bar_colors(hwnd, caption_color, text_color, border_color)
                if icon_path.exists():
                    set_native_window_icon(hwnd, str(icon_path))
            try:
                hud_hwnd = int(hud_window.winId())
            except Exception:
                hud_hwnd = 0
            if hud_hwnd and icon_path.exists():
                set_native_window_icon(hud_hwnd, str(icon_path))
            try:
                result_hwnd = int(result_window.winId())
            except Exception:
                result_hwnd = 0
            if result_hwnd and icon_path.exists():
                set_native_window_icon(result_hwnd, str(icon_path))

        apply_window_branding()
        reposition_hud()
        QTimer.singleShot(0, reposition_hud)
        controller.stateChanged.connect(reposition_hud)
        controller.configChanged.connect(reposition_hud)
        controller.resultCardChanged.connect(reposition_hud)
        hud_window.widthChanged.connect(reposition_hud)
        hud_window.heightChanged.connect(reposition_hud)
        hud_window.screenChanged.connect(lambda *_: reposition_hud())
        result_window.widthChanged.connect(reposition_hud)
        result_window.heightChanged.connect(reposition_hud)
        result_window.screenChanged.connect(lambda *_: reposition_hud())
        primary_screen = app.primaryScreen()
        if primary_screen is not None and hasattr(primary_screen, "availableGeometryChanged"):
            primary_screen.availableGeometryChanged.connect(lambda *_: reposition_hud())

        def handle_activation(message: str) -> None:
            normalized = message.strip().lower()
            if normalized == "settings":
                show_main_window(6)
                return
            if normalized == "show":
                show_main_window()

        instance.activationRequested.connect(handle_activation)

        sync_launch_at_login(config)
        start_warmup()
        pipeline.start()

        if not start_hidden:
            if activation_message == "settings":
                show_main_window(6)
            else:
                show_main_window()
        QTimer.singleShot(0, reposition_hud)

        ret = app.exec()
        return int(ret)
    finally:
        pipeline = runtime.get("pipeline")
        if pipeline is not None:
            pipeline.stop()
        instance.release()
