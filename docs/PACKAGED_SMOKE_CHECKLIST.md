# Packaged Smoke Checklist

Use this checklist for every Windows beta build of FlowType.

## Build Artifacts

1. Run `python scripts/build.py`.
2. If Inno Setup is installed, run `python scripts/build.py --installer`.
3. Confirm these files exist:
   - `dist\FlowType\FlowType.exe`
   - `dist\FlowType\_internal\flowtype\assets\branding\logo-mark.png`
   - `build\branding\app-icon.ico`
   - `build\version_info.txt`
   - `dist-installer\FlowType-Beta-<version>.exe` when installer build is requested

## Branding

1. `FlowType.exe` uses the FlowType icon, not the Python icon.
2. The window icon and taskbar icon match the FlowType logo.
3. Tray status icons are branded for:
   - ready
   - recording
   - processing
   - error
4. Installer icon and wizard art are branded.

## App Lifecycle

1. Launch `FlowType.exe` normally and confirm the desktop shell opens.
2. Launch `FlowType.exe --background` and confirm the process starts without forcing the full shell open.
3. Launch a second instance with `--settings` and confirm it restores the existing app instead of leaving duplicates.
4. Close the main window and confirm the app stays alive in the tray when close-to-tray is enabled.
5. Quit from the tray menu and confirm the process exits fully.

## First-Run Setup

1. On a fresh config, confirm onboarding appears.
2. Confirm onboarding includes:
   - cleanup provider choice
   - API key field where required
   - curated model selection
   - transcription language selection
   - launch-at-login choice
3. Confirm skipping onboarding leaves local transcription usable.

## Functional Flow

1. Dictate into Notepad using hold-to-talk.
2. Dictate a longer sample using toggle-recording.
3. Cancel a recording with `Esc`.
4. Confirm final text pastes into:
   - Notepad
   - VS Code
   - a browser text field
5. Confirm raw transcript fallback still pastes when cleanup fails.

## Failure Paths

1. No API key configured.
2. Invalid API key.
3. Network timeout during cleanup.
4. Microphone unavailable.
5. Paste blocked by the target app.

## Installer Path

1. Install silently or interactively from `FlowType-Beta-<version>.exe`.
2. Confirm install path is `%LocalAppData%\Programs\FlowType`.
3. Launch the installed app.
4. Confirm uninstall entry exists.
5. Run silent uninstall and confirm the install directory is removed.
