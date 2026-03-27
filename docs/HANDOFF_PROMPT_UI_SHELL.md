# FlowType Handoff Prompt: Windows-Native UI Shell

You are implementing the polished Windows-native product shell for FlowType.

## Context

This repository already contains the working core dictation pipeline:

- global hotkey
- microphone recording
- local Faster-Whisper transcription
- cleanup with fallback to raw transcript
- clipboard copy and paste

Do not rewrite the core dictation backend unless a narrow refactor is required to expose state/events to the UI.

Read these files first:

- `README.md`
- `implementation_plan.md`
- `IMPLEMENTATION_NOTES.md`
- `GEMINI.md`
- `docs/NEXT_PHASE_PRODUCT_DIRECTION.md`
- `docs/UI_IMPLEMENTATION_BACKLOG.md`

## Primary Goal

Build a complete native-feeling Windows application shell around the existing backend so it can become the user’s daily driver.

This is not a web app.
This is not a prototype.
This must behave like a polished Windows desktop application.

## Technology Direction

Use:

- `PySide6`
- `Qt Quick / QML`

Do not use Tkinter for the long-term shell.
Do not move the product to Electron.

## Design Direction

Use the provided Superwhisper-style screenshots as layout inspiration, without cloning them literally.

Target shell structure:

- left rail navigation
- compact desktop window
- sections:
  - `Home`
  - `Modes`
  - `Vocabulary`
  - `Configuration`
  - `Sound`
  - `History`

The UI should feel compact, dark, calm, and precise.

## Recording UX Requirements

Implement a bottom-center recording HUD that:

- does not steal focus
- stays above the active window
- supports `Classic` and `Mini` styles
- shows a flat idle line when no speech is present
- shows animated reactive bars/waves when speech is detected
- shows state transitions for:
  - recording
  - transcribing
  - cleaning
  - pasting
  - success
  - error

Use smoothed live microphone levels, not a heavy waveform renderer.

## Shortcut Requirements

Add in-app shortcut configuration for:

- hold-to-talk
- toggle recording
- cancel recording
- re-paste last result
- optional mode switch

Requirements:

- direct keyboard capture
- reset buttons
- conflict warnings
- Windows-risk warnings for `Win` shortcuts

## Provider Requirements

The app is local-first and privacy-first.
Users bring their own API keys.
There must be no FlowType-hosted backend.

First-class providers:

- OpenRouter
- OpenAI
- Custom OpenAI-compatible endpoint
- Ollama

Architecture-ready providers:

- Anthropic
- xAI

### OpenRouter UX

OpenRouter must have a curated model picker.

Do not dump the raw full catalog by default.

Show:

- recommended free models
- recommended paid models
- short human-readable descriptions
- tags like:
  - `Fast`
  - `Balanced`
  - `Best Quality`
  - `Free`
  - `Paid`

Allow an advanced manual model ID entry for power users.

Do not show fake numeric accuracy. Only show qualitative labels unless there is a real benchmark.

## Modes and Vocabulary

Modes and vocabulary are required product features, not optional chrome.

Modes should control:

- provider
- cleanup model
- optional transcription model
- language
- prompt style
- app activation rules

Vocabulary should support:

- exact spellings
- names
- acronyms
- spoken-to-written replacements
- global / mode / app scope

These must feed a dynamic prompt assembly layer, not sit unused in the UI.

## Prompt Assembly Requirement

Implement or scaffold a composable prompt layer that builds cleanup instructions from:

1. base rules
2. active mode
3. vocabulary
4. app/context hints
5. raw transcript

The UI must configure this system, but the backend should remain the source of truth.

## Windows Requirements

- single-instance app lock
- no focus stealing
- per-monitor DPI awareness
- overlay shown on the active monitor
- preserve automatic paste into the current cursor position
- graceful fallback when a target app blocks simulated paste

## Delivery Priority

Prioritize a stable single-user personal-use beta first.

That means the first high-value milestone is:

- polished shell
- animated recording HUD
- OpenRouter curated model picker
- direct OpenAI support
- modes
- vocabulary
- shortcut editor
- stable paste flow

Public-release niceties can come after that.

## Deliverables

- integrated `PySide6 + QML` shell
- bottom recording HUD
- settings and onboarding
- provider/model UX
- shortcut editor
- mode and vocabulary management
- prompt assembly integration or scaffold
- updated packaging docs
- updated tests and developer notes

Do not stop at mockups. Implement the shell against the current backend.
