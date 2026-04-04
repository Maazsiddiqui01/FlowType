from __future__ import annotations

import logging
import os
import threading
from datetime import datetime
from pathlib import Path
from typing import Callable

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

from flowtype.catalog import (
    cleanup_model_cards,
    cleanup_provider_cards,
    mode_cards,
    provider_display_name,
    transcription_language_cards,
)
from flowtype import __version__
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
    audioLevelReported = Signal(float)
    configChanged = Signal()
    historyChanged = Signal()
    notificationChanged = Signal()
    resultCardChanged = Signal()
    aiEnhancerFinished = Signal(bool, str, str)

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
        self._latest_result_text = ""
        self._result_card_preview_text = ""
        self._latest_result_title = ""
        self._result_card_message = ""
        self._result_card_tone = "info"
        self._result_card_visible = False
        self._result_card_persistent = False
        self._result_card_can_repaste = False
        self._result_card_enhancing = False
        self._result_card_recent_limit = 5
        self._result_card_timer = QTimer(self)
        self._result_card_timer.setInterval(8000)
        self._result_card_timer.setSingleShot(True)
        self._result_card_timer.timeout.connect(self._auto_dismiss_result_card)
        self.aiEnhancerFinished.connect(self._apply_ai_enhancer_result)
        self.audioLevelReported.connect(self._apply_audio_level)

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

    def _set_result_card(
        self,
        *,
        visible: bool,
        title: str = "",
        message: str = "",
        preview_text: str = "",
        tone: str = "info",
        persistent: bool = False,
        can_repaste: bool = False,
    ) -> None:
        self._latest_result_title = title
        self._result_card_message = message
        self._result_card_preview_text = preview_text
        self._result_card_tone = tone
        self._result_card_visible = visible
        self._result_card_persistent = persistent
        self._result_card_can_repaste = can_repaste and bool(self._latest_result_text.strip())
        self.resultCardChanged.emit()

        self._result_card_timer.stop()
        if visible and not persistent:
            self._result_card_timer.start()

    @Slot()
    def _auto_dismiss_result_card(self) -> None:
        if self._result_card_persistent:
            return
        if self._result_card_visible:
            self._set_result_card(visible=False)

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
        if status != "recording" and self._audio_level != 0.0:
            self._apply_audio_level(0.0)
        if status in {"recording", "transcribing", "cleaning", "pasting"} and self._result_card_visible:
            self._set_result_card(visible=False)
        if status == "error":
            self._set_result_card(
                visible=True,
                title="Dictation problem",
                message=detail,
                preview_text="",
                tone="error",
                persistent=True,
                can_repaste=False,
            )
        self._set_status(status, detail)

    def pipeline_notification_callback(self, message: str, tone: str) -> None:
        self._set_notification(message, tone)

    def pipeline_audio_level_callback(self, level: float) -> None:
        self.audioLevelReported.emit(float(level))

    @Slot(float)
    def _apply_audio_level(self, level: float) -> None:
        clamped = max(0.0, min(1.0, float(level)))
        if abs(clamped - self._audio_level) < 0.003:
            return
        self._audio_level = clamped
        self.audioLevelChanged.emit()

    def pipeline_result_callback(self, result: DictationResult) -> None:
        if not result.final_text.strip():
            return

        self._latest_result_text = result.final_text
        new_entry = build_history_entry(
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
        for i, existing_entry in enumerate(self._history_entries):
            if i >= limit:
                break
            new_entries.append(existing_entry)
        self._history_entries = [new_entry, *new_entries][:limit]
        if self._config.history.persist:
            self._history_entries = self._history_store.append(new_entry)
        self.historyChanged.emit()

        title = "Result copied"
        tone = "info"
        message = "FlowType kept the result safe in your clipboard."
        persistent = True
        if result.pasted:
            title = "Text pasted"
            tone = "success"
            message = "FlowType copied and pasted the result back into your app."
            if result.target_title:
                message = f'FlowType returned to "{result.target_title}" and pasted the result.'
            if result.used_fallback:
                message += " Cleanup fell back to the raw transcript."
            persistent = False
        elif result.delivery_note:
            message = result.delivery_note
            if result.used_fallback:
                message += " Cleanup fell back to the raw transcript."
        elif result.used_fallback:
            message = "Cleanup fell back to the raw transcript and FlowType kept it in your clipboard."

        self._set_result_card(
            visible=True,
            title=title,
            message=message,
            preview_text=result.final_text,
            tone=tone,
            persistent=persistent,
            can_repaste=bool(result.copied),
        )

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

    @Property(bool, notify=resultCardChanged)
    def resultCardVisible(self) -> bool:
        return self._result_card_visible

    @Property(bool, notify=resultCardChanged)
    def resultCardPersistent(self) -> bool:
        return self._result_card_persistent

    @Property(str, notify=resultCardChanged)
    def resultCardTitle(self) -> str:
        return self._latest_result_title

    @Property(str, notify=resultCardChanged)
    def resultCardMessage(self) -> str:
        return self._result_card_message

    @Property(str, notify=resultCardChanged)
    def resultCardPreview(self) -> str:
        return self._result_card_preview_text

    @Property(str, notify=resultCardChanged)
    def resultCardTone(self) -> str:
        return self._result_card_tone

    @Property(bool, notify=resultCardChanged)
    def resultCardCanRepaste(self) -> bool:
        return self._result_card_can_repaste

    @Property(bool, notify=resultCardChanged)
    def resultCardCanEnhance(self) -> bool:
        return self.cleanupEnabled and bool(self._latest_result_text.strip()) and not self._result_card_enhancing

    @Property(bool, notify=resultCardChanged)
    def resultCardEnhancing(self) -> bool:
        return self._result_card_enhancing

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

    @Property(str, notify=configChanged)
    def hudPosition(self) -> str:
        return self._config.experience.hud_position

    @Property(bool, notify=configChanged)
    def showIdleHud(self) -> bool:
        return self._config.experience.show_idle_hud

    @Property(bool, notify=configChanged)
    def closeToTray(self) -> bool:
        return self._config.experience.close_to_tray

    @Property(bool, notify=configChanged)
    def darkMode(self) -> bool:
        return self._config.experience.dark_mode

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
    def historyPersist(self) -> bool:
        return self._config.history.persist

    @Property(int, notify=configChanged)
    def historyMaxItems(self) -> int:
        return self._config.history.max_items

    @Property(str, notify=configChanged)
    def appVersion(self) -> str:
        return __version__

    @Property(bool, notify=configChanged)
    def onboardingVisible(self) -> bool:
        if not self._config.startup.prompt_completed:
            return True
        return (not self._config.experience.onboarding_dismissed) and (not self.cleanupEnabled)

    @Property(bool, notify=configChanged)
    def onboardingDismissed(self) -> bool:
        return self._config.experience.onboarding_dismissed

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
                    "entryId": entry.entry_id,
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
    def recentResultItems(self) -> list[dict]:
        items = self.historyItems
        return items[: self._result_card_recent_limit]

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
    def dismissResultCard(self) -> None:
        self._set_result_card(visible=False)

    @Slot()
    def copyLatestResult(self) -> None:
        text_to_copy = self._result_card_preview_text.strip() or self._latest_result_text.strip()
        if not text_to_copy:
            return
        try:
            self._pipeline.output.copy_to_clipboard(text_to_copy)
            self._set_notification("Latest result copied.", "success")
        except Exception as exc:
            self._logger.exception("Failed to copy latest result: %s", exc)
            self._set_notification("Could not copy the latest result.", "error")

    @Slot()
    def enhanceLatestResultForAi(self) -> None:
        if self._result_card_enhancing:
            return
        if not self.cleanupEnabled:
            self._set_notification("Add a cleanup provider before using AI prompt enhancement.", "error")
            return
        source_text = self._latest_result_text.strip()
        if not source_text:
            return

        self._result_card_enhancing = True
        self.resultCardChanged.emit()
        self._set_result_card(
            visible=True,
            title="Enhancing for AI",
            message="FlowType is turning the latest result into a stronger AI-ready prompt.",
            preview_text=self._result_card_preview_text or source_text,
            tone="info",
            persistent=True,
            can_repaste=True,
        )

        def worker() -> None:
            try:
                enhancement = self._pipeline.cleaner.enhance_for_ai(source_text)
                enhanced_text = enhancement.text.strip()
                if enhancement.used_fallback or not enhanced_text or enhanced_text == source_text:
                    self.aiEnhancerFinished.emit(False, source_text, "Could not enhance the prompt right now.")
                    return
                try:
                    self._pipeline.output.copy_to_clipboard(enhanced_text)
                except Exception as exc:
                    self._logger.exception("Failed to copy enhanced prompt: %s", exc)
                    self.aiEnhancerFinished.emit(False, source_text, "Enhanced prompt was created, but FlowType could not copy it.")
                    return
                self.aiEnhancerFinished.emit(True, enhanced_text, "AI-ready prompt copied. Your original dictation stays unchanged.")
            except Exception as exc:
                self._logger.exception("AI enhancement failed: %s", exc)
                self.aiEnhancerFinished.emit(False, source_text, "Could not enhance the prompt right now.")

        threading.Thread(target=worker, name="ai-enhancer", daemon=True).start()

    @Slot(bool, str, str)
    def _apply_ai_enhancer_result(self, success: bool, preview_text: str, message: str) -> None:
        self._result_card_enhancing = False
        self._set_result_card(
            visible=True,
            title="AI-ready prompt" if success else "Prompt enhancement unavailable",
            message=message,
            preview_text=preview_text,
            tone="success" if success else "error",
            persistent=True,
            can_repaste=bool(self._latest_result_text.strip()),
        )
        self._set_notification(message, "success" if success else "error")

    @Slot(int)
    def copyRecentResult(self, index: int) -> None:
        items = self.recentResultItems
        if index < 0 or index >= len(items):
            return
        text = str(items[index].get("finalText", "")).strip()
        if not text:
            return
        try:
            self._pipeline.output.copy_to_clipboard(text)
            self._set_notification("Saved result copied.", "success")
        except Exception as exc:
            self._logger.exception("Failed to copy saved result: %s", exc)
            self._set_notification("Could not copy the saved result.", "error")

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

    @Slot(str, str, bool, int, int, int)
    def saveExperienceSettings(
        self,
        hud_style: str,
        hud_position: str,
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
            data["experience"]["hud_position"] = hud_position.strip().lower() or "bottom"
            data["experience"]["show_idle_hud"] = bool(show_idle_hud)
            data["experience"]["idle_hud_user_set"] = True
            data["audio"]["min_duration_ms"] = int(min_duration_ms)
            data["audio"]["max_duration_seconds"] = int(max_duration_seconds)
            data["output"]["paste_delay_ms"] = int(paste_delay_ms)

        self._persist_config(mutate, "Recording experience updated.")

    @Slot(str, str, bool)
    def saveHudPresentation(self, hud_style: str, hud_position: str, show_idle_hud: bool) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("experience", {})
            data["experience"]["hud_style"] = hud_style.strip().lower() or "mini"
            data["experience"]["hud_position"] = hud_position.strip().lower() or "bottom"
            data["experience"]["show_idle_hud"] = bool(show_idle_hud)
            data["experience"]["idle_hud_user_set"] = True

        self._persist_config(mutate, "HUD placement updated.")

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

    @Slot(int, bool)
    def saveHistorySettings(self, max_items: int, persist: bool) -> None:
        normalized_max_items = max(1, int(max_items))

        def mutate(data: dict) -> None:
            data.setdefault("history", {})
            data["history"]["max_items"] = normalized_max_items
            data["history"]["persist"] = bool(persist)

        self._persist_config(mutate, "History settings updated.")

    @Slot()
    def toggleDarkMode(self) -> None:
        new_value = not self._config.experience.dark_mode

        def mutate(data: dict) -> None:
            data.setdefault("experience", {})
            data["experience"]["dark_mode"] = new_value

        self._persist_config(mutate, "")

    @Slot()
    def resetOnboarding(self) -> None:
        def mutate(data: dict) -> None:
            data.setdefault("startup", {})
            data.setdefault("experience", {})
            data["startup"]["prompt_completed"] = False
            data["experience"]["onboarding_dismissed"] = False

        self._persist_config(mutate, "Setup wizard reset.")

    @Slot()
    def resetConfig(self) -> None:
        backup_path: Path | None = self._config.config_path.with_suffix(".backup.toml")
        try:
            backup_path.write_text(self._config.config_path.read_text(encoding="utf-8"), encoding="utf-8")
        except Exception:
            backup_path = None

        self._persist_config(lambda data: data.clear(), "Configuration restored to defaults.")
        if backup_path is not None:
            self._set_notification(
                f"Configuration restored. Backup saved to {backup_path.name}.",
                "success",
            )

    @Slot(str)
    def openProviderKeyPage(self, provider: str) -> None:
        import webbrowser

        urls = {
            "openrouter": "https://openrouter.ai/keys",
            "openai": "https://platform.openai.com/api-keys",
            "anthropic": "https://console.anthropic.com/settings/keys",
            "gemini": "https://aistudio.google.com/apikey",
            "xai": "https://console.x.ai/",
            "groq": "https://console.groq.com/keys",
        }
        url = urls.get(provider.strip().lower(), "")
        if url:
            webbrowser.open(url)

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
            data["experience"]["show_idle_hud"] = False
            data["experience"]["idle_hud_user_set"] = False
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
            data["experience"]["show_idle_hud"] = False
            data["experience"]["idle_hud_user_set"] = False
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
