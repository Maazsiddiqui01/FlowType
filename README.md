# FlowType

FlowType is a Windows-focused desktop dictation app with local Faster-Whisper transcription, optional LLM cleanup, automatic paste, and a packaged Windows installer.

## Quick Start

### Install on Windows

- GitHub release install: download the latest installer from [Releases](https://github.com/Maazsiddiqui01/FlowType/releases).
- Local installer built from this workspace: `dist-installer\FlowType-Beta-0.1.6.exe`
- Install target: `%LocalAppData%\Programs\FlowType`
- User data stays in `%APPDATA%\FlowType`

### Run From Source

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e .[dev]
python -m flowtype
```

### Contribute

- Start here: [CONTRIBUTING.md](CONTRIBUTING.md)
- Packaging checklist: [PACKAGED_SMOKE_CHECKLIST.md](docs/PACKAGED_SMOKE_CHECKLIST.md)
- Build a release locally: `python scripts/build.py --installer`

## How Updates Work

- This beta does not have auto-update yet.
- Installed users should download the next installer and run it again when a bug fix or new release is published.
- Config, history, logs, and model cache live outside the install folder, so reinstalling does not wipe normal user data.
- If you run from source, just pull the latest code, reinstall dependencies if needed, and relaunch the app.

## What FlowType Does

FlowType:

- hold a global push-to-talk hotkey
- optionally tap a toggle-recording hotkey for longer dictation
- speak into your microphone
- transcribe locally with Faster-Whisper
- optionally clean the text with your own OpenRouter, OpenAI, Claude, Gemini, Grok, Groq, or Ollama setup
- paste the final text into the active application

The current build includes a full PySide6 desktop shell rather than only a tray utility:

- Home, Modes, Vocabulary, History, and Settings screens
- first-run onboarding inside the desktop shell for provider, key, and language setup
- startup-at-login choice during onboarding, preselected on for the Windows beta
- animated bottom recording HUD with a tiny idle line, compact active states, and an in-HUD language menu
- curated provider/model setup for OpenRouter, OpenAI, Claude, Gemini, Grok, Groq, Ollama, or raw-only mode
- in-app shortcut editing with live runtime reload
- recommended shortcut defaults for hold, toggle, and cancel recording
- in-app transcription language selection for faster single-language dictation
- vocabulary and mode instructions that feed the cleanup prompt assembly layer
- single-instance restore behavior plus close-to-tray background lifecycle
- branded app, tray, and installer assets generated from the FlowType logo system

## Current MVP

- Global push-to-talk hotkey: `Ctrl+Shift+Space`
- Toggle recording hotkey: `Ctrl+Alt+Space`
- Cancel recording hotkey: `Esc`
- Local transcription with Faster-Whisper
- Curated cleanup providers with retry and raw-transcript fallback
- Mode presets plus custom mode instructions
- Vocabulary preservation rules injected into cleanup
- Transcription language selection in Settings
- Clipboard copy plus automatic paste
- Desktop shell with bottom HUD, history, and unified settings
- Close-to-tray desktop lifecycle with tray reopen and quit actions
- Startup-at-login settings with Windows Run-key integration
- Rotating logs
- Config reload after in-app settings changes
- PyInstaller + Inno Setup packaging path

## Project Layout

```text
.
|-- GEMINI.md
|-- IMPLEMENTATION_NOTES.md
|-- README.md
|-- assets/
|   `-- branding/
|       |-- logo-mark.svg
|       `-- wordmark.svg
|-- config.toml
|-- flowtype.spec
|-- pyproject.toml
|-- requirements.txt
|-- scripts/
|   |-- build.py
|   |-- generate_branding_assets.py
|   `-- installer.iss
|   `-- validate_dist.py
|-- src/
|   `-- flowtype/
|       |-- __init__.py
|       |-- __main__.py
|       |-- audio.py
|       |-- branding.py
|       |-- catalog.py
|       |-- cleanup.py
|       |-- config.py
|       |-- history.py
|       |-- logger.py
|       |-- main.py
|       |-- output.py
|       |-- pipeline.py
|       |-- settings.py
|       |-- shortcuts.py
|       |-- startup.py
|       |-- transcriber.py
|       |-- tray.py
|       |-- windows.py
|       `-- ui/
|           |-- app.py
|           |-- controller.py
|           |-- single_instance.py
|           |-- system_tray.py
|           `-- qml/
|               |-- GeneralSettingsView.qml
|               |-- Main.qml
|               |-- HUDWindow.qml
|               |-- HomeView.qml
|               |-- ModesView.qml
|               |-- VocabularyView.qml
|               |-- ConfigurationView.qml
|               |-- SettingsView.qml
|               |-- SoundView.qml
|               |-- HistoryView.qml
|               `-- ShortcutRecorder.qml
`-- tests/
    |-- conftest.py
    |-- test_cleanup.py
    |-- test_config.py
    |-- test_output.py
    |-- test_pipeline.py
    `-- test_settings.py
```

## Setup

1. Install Python 3.11 or 3.12 on Windows.
2. Create and activate a virtual environment.
3. Install dependencies:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e .[dev]
```

4. Copy `config.toml` into `%APPDATA%\FlowType\config.toml` or let FlowType create it on first run.
5. Add your API key:
   - `OPENROUTER_API_KEY` for OpenRouter
   - `OPENAI_API_KEY` for OpenAI
   - `ANTHROPIC_API_KEY` for Claude
   - `GEMINI_API_KEY` or `GOOGLE_API_KEY` for Gemini
   - `XAI_API_KEY` for Grok
   - `GROQ_API_KEY` for Groq
   - or set `cleanup.api_key` in the generated config file

## Run

Default desktop shell:

```powershell
python -m flowtype
```

Background launch without opening the full shell immediately:

```powershell
python -m flowtype --background
```

Console mode is still useful while validating microphone, model download, and cleanup settings:

```powershell
python -m flowtype --no-tray
```

Open only the settings window:

```powershell
python -m flowtype --settings
```

`--settings` now opens the same PySide6 desktop shell instead of the legacy Tk window path.

Usage:

1. Focus a text field in any application.
2. On first run, either complete onboarding with your API key or skip to stay local-only.
3. Hold `Ctrl+Shift+Space`.
4. Speak.
5. Release the hotkey.
6. FlowType transcribes, cleans, and pastes the text.

For longer dictation, tap `Ctrl+Alt+Space` once to start and the same shortcut again to stop.

## Notes For Daily Use

- First run downloads the Faster-Whisper model into `%APPDATA%\FlowType\models`.
- Modes and vocabulary edits are saved locally and included in cleanup automatically.
- Cleanup only runs when a provider is selected and a valid key is configured.
- The cleanup settings screen intentionally shows a curated model list instead of every model a provider exposes.
- The History screen is local-only and stored in `%APPDATA%\FlowType\history.json`.
- If cleanup fails or no API key is configured, FlowType pastes the raw transcript.
- If paste simulation is blocked by a target app, switch `output.paste_method` to `clipboard_only`.
- Recording is capped at 5 minutes by default to prevent runaway background recording.
- The app reloads settings automatically when you save from the desktop shell.
- The desktop HUD now defaults to a tiny bottom ready line plus a compact in-HUD language switcher.
- The mini HUD is the default and is designed to stay visually quiet until you actually trigger dictation.
- Locking transcription to one language is usually faster and more stable than auto-detect for daily use.
- Closing the main window hides FlowType to the tray by default; quit from the tray menu if you want the process to stop.
- Launch-at-login writes a per-user Windows Run entry and starts FlowType minimized in the tray.

## Packaging

Generate branding assets, build the Windows app bundle, and validate the result:

```powershell
python -m pip install -e .[build]
python scripts/build.py
```

This produces:

- a branded PyInstaller `onedir` build in `dist\FlowType\`
- generated branding artifacts in `build\branding\`
- a version resource in `build\version_info.txt`
- bundle validation via `scripts\validate_dist.py`

The branding pipeline accepts either `assets\branding\logo-mark.svg` or `assets\branding\logo-mark.png` as the canonical source logo. Runtime, tray, EXE, and installer assets are regenerated from that source on every build.

Build the installer from the same entrypoint:

```powershell
python scripts/build.py --installer
```

That produces a per-user installer in `dist-installer\FlowType-Beta-<version>.exe`.

Installer defaults:

- installs to `%LocalAppData%\Programs\FlowType`
- no admin rights required
- Start Menu shortcut
- optional desktop shortcut
- branded installer icon and wizard art

The installer intentionally does not bundle a Whisper model. The app downloads and caches the configured model on first use.

## Verification

Automated tests:

```powershell
python -m pytest
python -m compileall src tests scripts
```

Manual checks:

1. Dictate a short sentence into Notepad.
2. Dictate a longer 60-second paragraph.
3. Break cleanup by using an invalid API key and confirm raw text still gets copied.
4. Change `output.paste_method` to `clipboard_only` if a target window blocks simulated paste.

Packaged-app checklist:

- see [PACKAGED_SMOKE_CHECKLIST.md](docs/PACKAGED_SMOKE_CHECKLIST.md)
