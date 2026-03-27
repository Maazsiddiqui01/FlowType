# FlowType UI Implementation Backlog

This is the practical handoff list for the engineer implementing the polished shell.

## P0

- Replace Tkinter settings with `PySide6 + QML`
- Add single-instance app lock
- Build non-activating bottom overlay window
- Emit live audio level telemetry from recorder to UI
- Add recording, transcribing, cleaning, pasting, success, and error states
- Implement the screenshot-inspired shell:
  - left rail
  - `Home`
  - `Modes`
  - `Vocabulary`
  - `Configuration`
  - `Sound`
  - `History`
- Add customizable shortcuts:
  - hold-to-talk
  - toggle recording
  - cancel recording
- Add compact shortcut editor with reset actions and conflict warnings
- Add `Classic` and `Mini` recording HUD styles
- Keep automatic paste as the default behavior
- Add OpenRouter curated model picker
- Add direct OpenAI provider support
- Add dynamic prompt assembly:
  - base rules
  - active mode
  - vocabulary
  - app context

## P1

- Add provider abstraction:
  - OpenRouter
  - OpenAI
  - Anthropic
  - xAI
  - Ollama
  - Custom OpenAI-compatible
- Add provider-specific settings forms
- Add test-connection action
- Move secrets to Windows Credential Manager
- Add optional mini indicator HUD
- Add vocabulary editor with:
  - exact spellings
  - spoken-to-written replacements
  - global / mode / app scope
- Add modes editor with:
  - provider/model selection
  - language
  - app activation rules

## P2

- Add history panel
- Add re-paste last result
- Add mode presets:
  - default dictation
  - email
  - message
  - note
- Add onboarding flow
- Add startup on login toggle

## Engineering Notes

- Keep the current core modules as the source of truth for dictation logic.
- Treat the UI shell as a client of the pipeline state, not the owner of the pipeline.
- Do not block the hotkey path on heavyweight UI rendering.
- The UI should still degrade gracefully if the cleanup provider is unavailable.
- The first target is a stable personal-use Windows beta, not public-release feature maximalism.
- Model pickers should be curated first and advanced second.
- Modes and vocabulary are not cosmetic; they must feed the prompt assembly layer.
