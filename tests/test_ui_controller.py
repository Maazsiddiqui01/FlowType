from __future__ import annotations

from pathlib import Path

from flowtype.config import load_config, write_default_config
from flowtype.ui.controller import AppController


class StubPipeline:
    def __init__(self, config) -> None:
        self.config = config
        self.status = "ready"

    def _handle_hold_press(self) -> None:
        self.status = "recording"

    def _handle_hold_release(self) -> None:
        self.status = "ready"

    def _handle_repaste_last(self) -> None:
        return None

    def toggle_recording(self) -> None:
        if self.status == "recording":
            self._handle_hold_release()
        else:
            self._handle_hold_press()

    def repaste_last(self) -> None:
        self._handle_repaste_last()


def build_controller(config_path: Path) -> AppController:
    current = {"config": load_config(config_path)}

    def reload_runtime():
        current["config"] = load_config(config_path)
        return current["config"], StubPipeline(current["config"])

    return AppController(
        config=current["config"],
        pipeline=StubPipeline(current["config"]),
        runtime_reloader=reload_runtime,
    )


def test_controller_saves_and_reloads_runtime_settings(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    assert controller.onboardingVisible is True

    controller.saveModeSettings("technical", "Keep bullet lists compact.")
    assert controller.activeMode == "technical"
    assert "bullet lists" in controller.customModePrompt

    controller.saveVocabulary("FlowType\none password => 1Password")
    assert "FlowType" in controller.vocabularyText
    assert "1Password" in controller.vocabularyText

    controller.saveTranscriptionLanguage("ur")
    assert controller.transcriptionLanguage == "ur"
    assert controller.transcriptionLanguageLabel == "Urdu"

    controller.saveCleanupSettings(
        "openai",
        "demo-key",
        "gpt-4o-mini",
        "Return only polished dictated text.",
        "clipboard_only",
        True,
    )
    assert controller.provider == "openai"
    assert controller.apiKey == "demo-key"
    assert controller.model == "gpt-4o-mini"
    assert controller.restoreClipboard is True
    assert controller.pasteMethod == "clipboard_only"

    controller.saveExperienceSettings("mini", "top", False, 400, 180, 240)
    assert controller.hudStyle == "mini"
    assert controller.hudPosition == "top"
    assert controller.showIdleHud is False
    assert controller.minDurationMs == 400
    assert controller.maxDurationSeconds == 180
    assert controller.pasteDelayMs == 240
    assert controller.closeToTray is True

    controller.saveHudPresentation("classic", "bottom", True)
    assert controller.hudStyle == "classic"
    assert controller.hudPosition == "bottom"
    assert controller.showIdleHud is True

    controller.saveStartupSettings(False, False, False)
    assert controller.launchAtLogin is False
    assert controller.startMinimized is False
    assert controller.closeToTray is False
    assert controller.startupPromptCompleted is True

    controller.saveShortcut("hold_to_talk", "ctrl+alt+d")
    assert controller.holdToTalk == "ctrl+alt+d"


def test_controller_onboarding_flows_update_runtime(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    controller.skipOnboarding(False)
    assert controller.provider == "none"
    assert controller.onboardingVisible is False
    assert controller.launchAtLogin is False

    controller.completeOnboarding("openai", "demo-key", "gpt-4o-mini", "en", True)
    assert controller.provider == "openai"
    assert controller.apiKey == "demo-key"
    assert controller.model == "gpt-4o-mini"
    assert controller.transcriptionLanguage == "en"
    assert controller.cleanupEnabled is True
    assert controller.onboardingVisible is False
    assert controller.launchAtLogin is True
    assert controller.toggleRecordingShortcut == "ctrl+alt+space"
    assert controller.cancelRecording == "escape"


def test_controller_restores_recommended_shortcuts(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    controller.saveShortcut("hold_to_talk", "ctrl+alt+d")
    controller.saveShortcut("toggle_recording", "")

    controller.restoreRecommendedShortcuts()

    assert controller.holdToTalk == "ctrl+shift+space"
    assert controller.toggleRecordingShortcut == "ctrl+alt+space"
    assert controller.cancelRecording == "escape"


def test_controller_rejects_invalid_shortcuts(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    controller.saveShortcut("toggle_recording", "`")

    assert controller.toggleRecordingShortcut == "ctrl+alt+space"
    assert "Ctrl, Alt, Shift, or Win" in controller.notificationMessage


def test_controller_exposes_curated_provider_cards(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    labels = [card["label"] for card in controller.providerCards]

    assert "OpenRouter" in labels
    assert "OpenAI" in labels
    assert "Claude" in labels
    assert "Gemini" in labels
    assert "Grok" in labels
    assert "Local only" in labels


def test_controller_treats_ollama_as_cleanup_enabled_without_api_key(tmp_path: Path) -> None:
    config_path = tmp_path / "config.toml"
    write_default_config(config_path)
    controller = build_controller(config_path)

    controller.saveCleanupSettings(
        "ollama",
        "",
        "llama3.1:8b",
        "Return only cleaned text.",
        "ctrl_v",
        False,
    )

    assert controller.provider == "ollama"
    assert controller.cleanupEnabled is True
    assert controller.needsApiKey is False
