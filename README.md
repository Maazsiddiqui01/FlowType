# FlowType

**Local-first voice dictation for Windows.** Hold a hotkey, speak, and FlowType transcribes on your machine, optionally cleans the text with an AI model you bring, and pastes it into whatever app you're using.

It's a [Wispr Flow](https://wisprflow.ai)-style dictation experience that runs locally and lets you plug in your own model and key — your audio is transcribed on-device, and cleanup only ever talks to the provider you choose.

> Status: Windows beta (`v0.1.13`). macOS is not supported yet.

---

## Why FlowType

- **Local transcription.** Speech-to-text runs on your machine with [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper) (CPU int8, with an automatic CUDA→CPU fallback). No audio leaves the device for transcription.
- **Bring your own model.** Cleanup is optional and uses *your* account: OpenRouter, OpenAI, Anthropic (Claude), Gemini, xAI (Grok), Groq, a local Ollama, any OpenAI-compatible endpoint — or no cleanup at all (raw transcript).
- **Private by default.** API keys are encrypted at rest with Windows DPAPI. FlowType never proxies your requests; it calls your provider directly.
- **It always records.** Recordings are journaled to disk as you speak and recovered after a crash, the capture pipeline never drops a hotkey press, and if cleanup fails for any reason you still get the raw transcript pasted.
- **Stays out of the way.** A minimal bottom HUD shows a thin idle line that expands to a hint on hover and a compact meter while recording — and it hides itself over fullscreen video and games.

## Features

- Global **push-to-talk** (hold) and **toggle** (tap) hotkeys, plus cancel and re-paste — all editable in-app with live reload.
- **Cleanup modes** (Default, Focused Writing, Meetings, Technical) plus custom instructions, and **per-app modes** that auto-switch based on the app you're dictating into.
- **Vocabulary** rules to protect names, product terms, and acronyms during cleanup.
- **History** of every dictation, with one-click copy, re-paste, and "Clean with AI" to re-run cleanup on a take you pasted raw.
- **Learn from behavior** — after you dictate into the same app a few times, FlowType offers to set a per-app mode for it (dismissable).
- **Per-language** transcription lock for faster, steadier results than auto-detect.
- Light and dark themes, system tray with close-to-tray lifecycle, and launch-at-login.

## Install (Windows)

1. Download the latest installer from [Releases](https://github.com/Maazsiddiqui01/FlowType/releases).
2. Run it — no admin rights needed. It installs per-user to `%LocalAppData%\Programs\FlowType`.
3. Launch FlowType and complete the short first-run setup (pick a provider + key, or stay local-only).

Your config, history, logs, and model cache live in `%APPDATA%\FlowType`, so reinstalling or updating never wipes your data. This beta has no auto-update yet — download and run the newer installer to update.

## Using it

1. Focus any text field.
2. Hold **`Ctrl + Shift + Space`**, speak, and release.
3. FlowType transcribes, cleans (if configured), and pastes.

For longer dictation, tap **`Ctrl + Alt + Space`** to start and again to stop. Press **`Esc`** to cancel a take. All shortcuts are configurable in **Settings**.

The first dictation downloads the Whisper model into `%APPDATA%\FlowType\models` (one-time).

## Configuration

Open the **Cleanup** screen to choose a provider and paste your key. A status banner tells you whether cleanup is **off** (raw transcripts), **needs a key**, or **active**. You can also set keys via environment variables:

| Provider | Variable |
| --- | --- |
| OpenRouter | `OPENROUTER_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Anthropic (Claude) | `ANTHROPIC_API_KEY` |
| Gemini | `GEMINI_API_KEY` / `GOOGLE_API_KEY` |
| xAI (Grok) | `XAI_API_KEY` |
| Groq | `GROQ_API_KEY` |

Notes:
- Cleanup runs only when a provider is selected and a valid key is present; otherwise the raw transcript is pasted.
- If a target app blocks simulated paste, switch `output.paste_method` to `clipboard_only` in the config.
- Recording is capped at 30 minutes by default to prevent a runaway background capture.

## Run from source

FlowType uses [uv](https://docs.astral.sh/uv/). Python 3.11 or 3.12 on Windows.

```powershell
uv sync                      # create the env and install deps
uv run python -m flowtype    # launch the desktop app
```

Useful flags: `--background` (start hidden in the tray), `--no-tray` (console mode, handy for validating mic/model/cleanup), `--settings` (open the desktop shell).

Prefer plain pip? `python -m pip install -e .[dev]` then `python -m flowtype` works too.

## Build the Windows installer

```powershell
uv run python scripts/build.py --installer
```

This produces a branded PyInstaller `onedir` build in `dist\FlowType\`, validates the bundle, and emits a per-user installer at `dist-installer\FlowType-Beta-<version>.exe`. The installer deliberately does **not** bundle a Whisper model — it's downloaded and cached on first use. See [docs/PACKAGED_SMOKE_CHECKLIST.md](docs/PACKAGED_SMOKE_CHECKLIST.md) for the release smoke test.

## Development

```powershell
uv run python -m pytest          # test suite
uv run python -m compileall src  # quick syntax check
```

The codebase is a Python core (`src/flowtype/`: capture → transcribe → cleanup → paste pipeline, config, providers, Windows integration) with a PySide6/QML desktop shell (`src/flowtype/ui/`). See [CONTRIBUTING.md](CONTRIBUTING.md) for the product direction and contribution guidelines.

## License

[MIT](LICENSE) © AntiGravity
