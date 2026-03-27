from __future__ import annotations

import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Callable

from PySide6.QtCore import QObject, Property, Signal, Slot

from flowtype.catalog import (
    cleanup_model_cards,
    cleanup_provider_cards,
    mode_cards,
    provider_display_name,
    transcription_language_cards,
)
from flowtype.config import AppConfig, RECOMMENDED_SHORTCUTS, load_config_data, save_config_data
from flowtype.history import HistoryEntry, HistoryStore, build_history_entry
from flowtype.pipeline import DictationPipeline, DictationResult
from flowtype.shortcuts import validate_shortcut_for_action
from flowtype.startup import sync_launch_at_login


logger = logging.getLogger("flowtype.ui.controller")

RuntimeReloader = Callable[[], tuple[AppConfig, DictationPipeline]]


class AppController(QObject):
    stateChanged = Signal()
    audioLevelChanged = Signal()
    configChanged = Signal()
    historyChanged = Signal()
    notificationChanged = Signal()

    def __init__(
        self,
        config: AppConfig,
        pipeline: DictationPipeline,
        runtime_reloader: RuntimeReloader,
        logger_: logging.Logger | None = None,
    ) -> None:
        super().__init__()
        self._logger = logger_ or logger
        self._config = config
        self._pipeline = pipeline
        self._runtime_reloader = runtime_reloader
        self._status = "starting"
        self._detail = "Starting FlowType..."
        self._audio_level = 0.0
        self._notification_message = ""
        self._notification_tone = "info"
        self._history_store = HistoryStore(config.history.file_path, config.history.max_items)
        self._history_entries = self._load_history()

    def _load_history(self) -> list[HistoryEntry]:
        if not self._config.history.persist:
            return []
        return self._history_store.load()

    def _set_notification(self, message: str, tone: str = "info") -> None:
        self._notification_message = message
        self._notification_tone = tone
        self.notificationChanged.emit()

    def _set_status(self, status: str, detail: str) -> None:
        self._status = status
        self._detail = detail
        self.stateChanged.emit()

    def _apply_runtime(self, config: AppConfig, pipeline: DictationPipeline) -> None:
        self._config = config
        self._pipeline = pipeline
        self._history_store = HistoryStore(config.history.file_path, config.history.max_items)
        if config.history.persist:
            self._history_entries = self._history_store.load()
        else:
            limit = config.history.max_items
            new_entries = []
            for i, entry in enumerate(self._history_entries):
                if i >= limit:
                    break
                new_entries.append(entry)
            self._history_entries = new_entries
        self.configChanged.emit()
        self.historyChanged.emit()

    def _persist_config(self, mutator: Callable[[dict], None], success_message: str) -> None:
        try:
            config_path, data = load_config_data(self._config.config_path)
            mutator(data)
            save_config_data(config_path, data)
            config, pipeline = self._runtime_reloader()
            sync_launch_at_login(config)
            self._apply_runtime(config, pipeline)
            self._set_notification(success_message, "success")
        except Exception as exc:
            self._logger.exception("Failed to save FlowType settings: %s", exc)
            self._set_notification(str(exc), "error")

    def pipeline_status_callback(self, status: str, detail: str) -> None:
        self._set_status(status, detail)

    def pipeline_audio_level_callback(self, level: float) -> None:
        self._audio_level = level
        self.audioLevelChanged.emit()

    def pipeline_result_callback(self, result: DictationResult) -> None:
        if not result.final_text.strip():
            return

        entry = build_history_entry(
            final_text=result.final_text,
            raw_text=result.raw_text,
            mode=result.mode_name,
            provider=result.provider,
            model=result.model,
            used_fallback=result.used_fallback,
            pasted=result.pasted,
        )
        limit = self._config.history.max_items
        new_entries = []
        for i, entry in enumerate(self._history_entries):
            if i >= limit:
                break
            new_entries.append(entry)
        self._history_entries = [entry, *new_entries][:limit]
        if self._config.history.persist:
            self._history_entries = self._history_store.append(entry)
        self.historyChanged.emit()

    @Property(str, notify=stateChanged)
    def status(self) -> str:
        return self._status

    @Property(str, notify=stateChanged)
    def detail(self) -> str:
        return self._detail

    @Property(float, notify=audioLevelChanged)
    def audioLevel(self) -> float:
        return self._audio_level

    @Property(str, notify=notificationChanged)
    def notificationMessage(self) -> str:
        return self._notification_message

    @Property(str, notify=notificationChanged)
    def notificationTone(self) -> str:
        return self._notification_tone

    @Property(str, notify=configChanged)
    def holdToTalk(self) -> str:
        return self._config.shortcuts.hold_to_talk

    @Property(str, notify=configChanged)
    def toggleRecordingShortcut(self) -> str:
        return self._config.shortcuts.toggle_recording

    @Property(str, notify=configChanged)
    def cancelRecording(self) -> str:
        return self._config.shortcuts.cancel_recording

    @Property(str, notify=configChanged)
    def repasteLast(self) -> str:
        return self._config.shortcuts.repaste_last

    @Property(str, notify=configChanged)
    def provider(self) -> str:
        return self._config.cleanup.provider

    @Property(str, notify=configChanged)
    def providerLabel(self) -> str:
        return provider_display_name(self._config.cleanup.provider)

    @Property(str, notify=configChanged)
    def apiKey(self) -> str:
        return self._config.cleanup.api_key

    @Property(str, notify=configChanged)
    def model(self) -> str:
        return self._config.cleanup.model

    @Property(str, notify=configChanged)
    def prompt(self) -> str:
        return self._config.cleanup.prompt

    @Property(str, notify=configChanged)
    def pasteMethod(self) -> str:
        return self._config.output.paste_method

    @Property(bool, notify=configChanged)
    def restoreClipboard(self) -> bool:
        return self._config.output.restore_clipboard

    @Property(int, notify=configChanged)
    def pasteDelayMs(self) -> int:
        return self._config.output.paste_delay_ms

    @Property(int, notify=configChanged)
    def minDurationMs(self) -> int:
        return self._config.audio.min_duration_ms

    @Property(int, notify=configChanged)
    def maxDurationSeconds(self) -> int:
        return self._config.audio.max_duration_seconds

    @Property(str, notify=configChanged)
    def activeMode(self) -> str:
        return self._config.mode.active

    @Property(str, notify=configChanged)
    def customModePrompt(self) -> str:
        return self._config.mode.custom_prompt

    @Property(str, notify=configChanged)
    def vocabularyText(self) -> str:
        return self._config.vocabulary.text

    @Property(str, notify=configChanged)
    def hudStyle(self) -> str:
        return self._config.experience.hud_style

    @Property(bool, notify=configChanged)
    def showIdleHud(self) -> bool:
        return self._config.experience.show_idle_hud

    @Property(bool, notify=configChanged)
    def closeToTray(self) -> bool:
        return self._config.experience.close_to_tray

    @Property(str, notify=configChanged)
    def whisperModel(self) -> str:
        return self._config.transcription.model_size

    @Property(str, notify=configChanged)
    def transcriptionLanguage(self) -> str:
        return self._config.transcription.language or "auto"

    @Property(str, notify=configChanged)
    def transcriptionLanguageLabel(self) -> str:
        selected_code = self.transcriptionLanguage
        for card in transcription_language_cards():
            if card["code"] == selected_code:
                return card["label"]
        return selected_code.upper()

    @Property(bool, notify=configChanged)
    def needsApiKey(self) -> bool:
        return self._config.cleanup.provider not in {"none", "ollama"} and not self._config.cleanup.api_key

    @Property(bool, notify=configChanged)
    def cleanupEnabled(self) -> bool:
        return self._config.cleanup.provider == "ollama" or (
            self._config.cleanup.provider != "none" and bool(self._config.cleanup.api_key)
        )

    @Property(bool, notify=configChanged)
    def launchAtLogin(self) -> bool:
        return self._config.startup.launch_at_login

    @Property(bool, notify=configChanged)
    def startMinimized(self) -> bool:
        return self._config.startup.start_minimized

    @Property(bool, notify=configChanged)
    def startupPromptCompleted(self) -> bool:
        return self._config.startup.prompt_completed

    @Property(bool, notify=configChanged)
    def onboardingVisible(self) -> bool:
        if not self._config.startup.prompt_completed:
            return True
        return (not self._config.experience.onboarding_dismissed) and (not self.cleanupEnabled)

    @Property("QVariantList", notify=configChanged)
    def modeCards(self) -> list[dict]:
        cards = []
        for card in mode_cards():
            cards.append({**card, "selected": card["identifier"] == self._config.mode.active})
        return cards

    @Property("QVariantList", notify=configChanged)
    def modelCards(self) -> list[dict]:
        cards = []
        for card in cleanup_model_cards(self._config.cleanup.provider):
            cards.append({**card, "selected": card["identifier"] == self._config.cleanup.model})
        return cards

    @Property("QVariantList", notify=configChanged)
    def providerCards(self) -> list[dict]:
        cards = []
        for card in cleanup_provider_cards():
            cards.append({**card, "selected": card["identifier"] == self._config.cleanup.provider})
        return cards

    @Property("QVariantList", notify=configChanged)
    def featuredProviderCards(self) -> list[dict]:
        cards = []
        for card in cleanup_provider_cards(featured_only=True):
            cards.append({**card, "selected": card["identifier"] == self._config.cleanup.provider})
        return cards

    @Slot(str, result="QVariantList")
    def availableModelCards(self, provider: str) -> list[dict]:
        return cleanup_model_cards(provider.strip().lower())

    @Property("QVariantList", notify=configChanged)
    def transcriptionLanguageCards(self) -> list[dict]:
        selected_code = self.transcriptionLanguage
        cards = []
        for card in transcription_language_cards():
            cards.append({**card, "selected": card["code"] == selected_code})
        return cards

    @Property("QVariantList", notify=historyChanged)
    def historyItems(self) -> list[dict]:
        items = []
        for entry in self._history_entries:
            items.append(
                {
                    "createdAt": self._format_timestamp(entry.created_at),
                    "createdAtRaw": entry.created_at,
                    "finalText": entry.final_text,
                    "rawText": entry.raw_text,
                    "mode": entry.mode,
                    "provider": provider_display_name(entry.provider),
                    "providerId": entry.provider,
                    "model": entry.model,
                    "wordCount": entry.word_count,
                    "usedFallback": entry.used_fallback,
                    "pasted": entry.pasted,
                }
            )
        return items

    @Property("QVariantList", notify=historyChanged)
    def homeStats(self) -> list[dict]:
        total_words = sum(entry.word_count for entry in self._history_entries)
        pasted_count = sum(1 for entry in self._history_entries if entry.pasted)
        fallback_count = sum(1 for entry in self._history_entries if entry.used_fallback)
        return [
            {"label": "Session dictations", "value": str(len(self._history_entries)), "tone": "#7dd3fc"},
            {"label": "Words captured", "value": str(total_words), "tone": "#34d399"},
            {"label": "Auto-pasted", "value": str(pasted_count), "tone": "#f59e0b"},
            {"label": "Fallbacks", "value": str(fallback_count), "tone": "#fda4af"},
        ]

    @Slot()
    def toggleRecording(self) -> None:
        self._pipeline.toggle_recording()

    @Slot()
    def repasteLastText(self) -> None:
        self._pipeline.repaste_last()

    @Slot()
    def clearHistory(self) -> None:
        self._history_entries = []
        if self._config.history.persist:
            self._history_store.clear()
        self.historyChanged.emit()
        self._set_notification("History cleared.", "success")

    @Slot(str, str)
    def saveShortcut(self, action: str, keys: str) -> None:
        normalized = keys.strip().lower()
        try:
            normalized = validate_shortcut_for_action(action, normalized)
        except Exception as exc:
            self._set_notification(str(exc), "error")
            return

        def mutate(data: dict) -> None:
            data.setdefault("shortcuts", {})
            data.setdefault("general", {})
            data["shortcuts"][action] = normalized
            if action == "hold_to_talk":
                data["general"]["hotkey"] = normalized

        self._persist_config(mutate, "Shortcuts updated. Global bindings reloaded.")

    @Slot()
    def restoreRecommendedShortcuts(self) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("general", {})
            data.setdefault("shortcuts", {})
            data["general"]["hotkey"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
            data["shortcuts"]["hold_to_talk"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
            data["shortcuts"]["toggle_recording"] = RECOMMENDED_SHORTCUTS["toggle_recording"]
            data["shortcuts"]["cancel_recording"] = RECOMMENDED_SHORTCUTS["cancel_recording"]
            data["shortcuts"]["repaste_last"] = RECOMMENDED_SHORTCUTS["repaste_last"]

        self._persist_config(mutate, "Recommended shortcut defaults restored.")

    @Slot(str, str)
    def saveModeSettings(self, active_mode: str, custom_prompt: str) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("mode", {})
            data["mode"]["active"] = active_mode.strip().lower() or "default"
            data["mode"]["custom_prompt"] = custom_prompt.strip()

        self._persist_config(mutate, "Mode instructions updated.")

    @Slot(str)
    def saveVocabulary(self, vocabulary_text: str) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("vocabulary", {})
            data["vocabulary"]["entries"] = vocabulary_text.strip()

        self._persist_config(mutate, "Vocabulary guidance updated.")

    @Slot(str)
    def saveTranscriptionLanguage(self, language_code: str) -> None:
        normalized = language_code.strip().lower() or "auto"

        def mutate(data: dict) -> None:
            data.setdefault("transcription", {})
            data["transcription"]["language"] = normalized

        self._persist_config(mutate, "Transcription language updated.")

    @Slot(str, str, str, str, str, bool)
    def saveCleanupSettings(
        self,
        provider: str,
        api_key: str,
        model: str,
        prompt: str,
        paste_method: str,
        restore_clipboard: bool,
    ) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("cleanup", {})
            data.setdefault("output", {})
            data.setdefault("experience", {})
            data["cleanup"]["provider"] = provider.strip().lower() or "none"
            data["cleanup"]["api_key"] = api_key.strip()
            data["cleanup"]["model"] = model.strip()
            data["cleanup"]["prompt"] = prompt.strip()
            data["output"]["paste_method"] = paste_method.strip().lower()
            data["output"]["restore_clipboard"] = bool(restore_clipboard)
            data["experience"]["onboarding_dismissed"] = True

        self._persist_config(mutate, "Cleanup and paste settings updated.")

    @Slot(str, bool, int, int, int)
    def saveExperienceSettings(
        self,
        hud_style: str,
        show_idle_hud: bool,
        min_duration_ms: int,
        max_duration_seconds: int,
        paste_delay_ms: int,
    ) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("experience", {})
            data.setdefault("audio", {})
            data.setdefault("output", {})
            data["experience"]["hud_style"] = hud_style.strip().lower() or "classic"
            data["experience"]["show_idle_hud"] = bool(show_idle_hud)
            data["audio"]["min_duration_ms"] = int(min_duration_ms)
            data["audio"]["max_duration_seconds"] = int(max_duration_seconds)
            data["output"]["paste_delay_ms"] = int(paste_delay_ms)

        self._persist_config(mutate, "Recording experience updated.")

    @Slot(bool, bool, bool)
    def saveStartupSettings(self, launch_at_login: bool, start_minimized: bool, close_to_tray: bool) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("startup", {})
            data.setdefault("experience", {})
            data["startup"]["launch_at_login"] = bool(launch_at_login)
            data["startup"]["start_minimized"] = bool(start_minimized)
            data["startup"]["prompt_completed"] = True
            data["experience"]["close_to_tray"] = bool(close_to_tray)

        self._persist_config(mutate, "Background launch preferences updated.")

    @Slot(str, str, str, str, bool)
    def completeOnboarding(
        self,
        provider: str,
        api_key: str,
        model: str,
        language_code: str,
        launch_at_login: bool,
    ) -> None:
        provider_normalized = provider.strip().lower() or "none"
        api_key_normalized = api_key.strip()
        model_normalized = model.strip()
        language_normalized = language_code.strip().lower() or "auto"

        if provider_normalized not in {"none", "ollama"} and not api_key_normalized:
            self._set_notification("Add an API key or choose local-only for now.", "error")
            return

        def mutate(data: dict) -> None:
            data.setdefault("cleanup", {})
            data.setdefault("transcription", {})
            data.setdefault("experience", {})
            data.setdefault("startup", {})
            data.setdefault("general", {})
            data.setdefault("shortcuts", {})
            data["cleanup"]["provider"] = provider_normalized
            data["cleanup"]["api_key"] = api_key_normalized
            data["cleanup"]["model"] = model_normalized
            data["transcription"]["language"] = language_normalized
            data["experience"]["hud_style"] = "mini"
            data["experience"]["show_idle_hud"] = True
            data["experience"]["onboarding_dismissed"] = True
            data["experience"]["close_to_tray"] = True
            data["startup"]["launch_at_login"] = bool(launch_at_login)
            data["startup"]["start_minimized"] = True
            data["startup"]["prompt_completed"] = True
            if not str(data["shortcuts"].get("hold_to_talk", "")).strip():
                data["general"]["hotkey"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
                data["shortcuts"]["hold_to_talk"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
            if not str(data["shortcuts"].get("toggle_recording", "")).strip():
                data["shortcuts"]["toggle_recording"] = RECOMMENDED_SHORTCUTS["toggle_recording"]
            if not str(data["shortcuts"].get("cancel_recording", "")).strip():
                data["shortcuts"]["cancel_recording"] = RECOMMENDED_SHORTCUTS["cancel_recording"]

        self._persist_config(mutate, "FlowType is ready. You can change these choices later in Settings.")

    @Slot(bool)
    def skipOnboarding(self, launch_at_login: bool = True) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("cleanup", {})
            data.setdefault("experience", {})
            data.setdefault("startup", {})
            data.setdefault("general", {})
            data.setdefault("shortcuts", {})
            data["cleanup"]["provider"] = "none"
            data["cleanup"]["api_key"] = ""
            data["cleanup"]["model"] = ""
            data["experience"]["hud_style"] = "mini"
            data["experience"]["show_idle_hud"] = True
            data["experience"]["onboarding_dismissed"] = True
            data["experience"]["close_to_tray"] = True
            data["startup"]["launch_at_login"] = bool(launch_at_login)
            data["startup"]["start_minimized"] = True
            data["startup"]["prompt_completed"] = True
            if not str(data["shortcuts"].get("hold_to_talk", "")).strip():
                data["general"]["hotkey"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
                data["shortcuts"]["hold_to_talk"] = RECOMMENDED_SHORTCUTS["hold_to_talk"]
            if not str(data["shortcuts"].get("toggle_recording", "")).strip():
                data["shortcuts"]["toggle_recording"] = RECOMMENDED_SHORTCUTS["toggle_recording"]
            if not str(data["shortcuts"].get("cancel_recording", "")).strip():
                data["shortcuts"]["cancel_recording"] = RECOMMENDED_SHORTCUTS["cancel_recording"]

        self._persist_config(mutate, "Onboarding skipped. Local transcription stays available.")

    @Slot()
    def openAppDirectory(self) -> None:
        self._open_path(self._config.general.app_dir)

    @Slot()
    def openConfigFile(self) -> None:
        self._open_path(self._config.config_path)

    @Slot()
    def openLogsDirectory(self) -> None:
        self._open_path(self._config.general.log_file.parent)

    def _open_path(self, path: Path) -> None:
        try:
            os.startfile(str(path))  # type: ignore[attr-defined]
        except Exception as exc:
            self._logger.warning("Failed to open %s: %s", path, exc)
            self._set_notification(f"Could not open {path}", "error")

    def _format_timestamp(self, timestamp: str) -> str:
        if not timestamp:
            return "Unknown"
        try:
            parsed = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        except ValueError:
            return timestamp
        return parsed.astimezone().strftime("%b %d, %I:%M %p")
