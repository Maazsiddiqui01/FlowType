# FlowType Next-Phase Product Direction

This document sets the direction for the polished Windows product layer that should sit on top of the current FlowType core.

The current codebase already has:

- local transcription
- cleanup fallback behavior
- global push-to-talk
- tray runtime
- a functional settings window

The next phase is about turning that into a daily-use desktop product with a small, elegant, animated UX.

## 1. Product Goal

FlowType should feel like a Windows-native equivalent of the best parts of Wispr Flow, Superwhisper, and FreeFlow:

- always available
- visually calm when idle
- obvious when recording
- fast to trust
- customizable without being overwhelming

The user should not need to edit config files for normal usage.

## 2. Product Principles

1. The app must stay invisible until needed.
2. Recording feedback must be immediate and unmistakable.
3. The recording HUD must never steal focus from the active app.
4. The user must always know which stage the app is in:
   - idle
   - recording
   - transcribing
   - cleaning
   - pasting
   - error
5. The paste behavior must remain the primary UX:
   - speak
   - release
   - text appears exactly where the cursor already was
6. Settings should be simple for beginners, but deep enough for power users.
7. API-provider support must be modular, not hard-coded around one vendor.

## 3. UX Inspiration Pulled Into Scope

Relevant patterns from the reviewed inspirations:

- Superwhisper exposes a dedicated recording window and mini window with waveform feedback, status visibility, and settings access from compact surfaces.
- Superwhisper also treats shortcut customization as a first-class feature.
- The provided Superwhisper screenshots establish the preferred information architecture:
  - `Home`
  - `Modes`
  - `Vocabulary`
  - `Configuration`
  - `Sound`
  - `History`
- The provided screenshots also confirm the preferred layout language:
  - compact left navigation
  - dense but readable settings cards
  - inline toggles and dropdowns
  - bottom-center mini recording HUD
  - blurred/translucent overlays for advanced popovers
- FreeFlow explicitly supports separate hold and toggle shortcuts, and allows the toggle shortcut to extend the hold shortcut for latching behavior.

References:

- Superwhisper recording window: https://superwhisper.com/docs/get-started/interface-rec-window
- Superwhisper keyboard shortcuts: https://superwhisper.com/docs/get-started/settings-shortcuts
- Superwhisper advanced settings: https://superwhisper.com/docs/get-started/settings-advanced
- FreeFlow repository: https://github.com/zachlatta/freeflow

## 4. Recommended UI Stack

Do not try to build the polished animated version in Tkinter.

Recommended direction:

- UI shell: `PySide6 + Qt Quick / QML`
- Core engine: keep the current Python dictation pipeline
- Packaging: continue with PyInstaller, but package Qt assets with the app

Why this is the right direction:

- Python stays the single language for the shipped app
- QML handles bottom-overlay HUDs, translucent windows, waveform animation, and smooth state transitions much better than Tkinter
- the core dictation engine can stay mostly unchanged
- tray, settings, onboarding, history, and overlay can all live in one desktop shell

What not to do unless there is a strong reason:

- do not move to Electron only for animation polish
- do not split the app into a Python engine plus a separate web stack unless the team is explicitly choosing IPC complexity

Tkinter should be treated as the transitional settings surface, not the long-term product shell.

## 5. Target Interaction Model

### 5.1 Shortcut Model

The product should support these shortcut actions:

- Hold to talk
- Toggle recording start/stop
- Cancel current recording
- Open settings
- Re-paste last result

Default recommendation:

- Hold to talk: `Ctrl+Shift+Space`
- Toggle recording: `Ctrl+Shift+Alt+Space`
- Cancel recording: `Esc`
- Open settings: tray/menu only at first

Important Windows note:

- allow `Windows` key combos only as an advanced option
- do not make `Win`-based shortcuts the default, because they frequently collide with OS or vendor shortcuts

### 5.2 Shortcut UX

The shortcut editor should:

- capture combinations directly from the keyboard
- validate conflicts
- warn when a combination is risky on Windows
- allow reset to defaults
- show whether the shortcut is:
  - available
  - conflicting
  - reserved by Windows

### 5.3 Hold and Toggle Behavior

Support both interaction styles:

- hold mode:
  - press and hold
  - release to process
- toggle mode:
  - press once to start
  - press again to stop

Advanced convenience:

- if the toggle shortcut extends the hold shortcut, allow latching from hold mode into toggle mode without dropping the recording

That behavior is directly inspired by FreeFlow and is worth carrying over.

## 6. Recording HUD Direction

### 6.1 Window Placement

Use a small bottom-center overlay window:

- centered on the active monitor
- 12 to 20 px above the taskbar safe area
- always-on-top
- non-activating
- click-through while passive

### 6.2 HUD States

The overlay should have these visual states:

1. `idle-hidden`
   - no visible UI

2. `idle-mini`
   - optional small docked indicator
   - single pulse or dot
   - hover reveals quick actions

3. `recording`
   - microphone icon
   - live waveform or level-reactive bars
   - elapsed timer
   - mode label

4. `processing-transcription`
   - waveform settles into a soft motion state
   - label changes to `Transcribing`

5. `processing-cleanup`
   - label changes to `Cleaning`
   - subtle shimmer or flowing line, not a generic spinner

6. `pasting`
   - very brief confirmation state
   - optional cursor or send animation

7. `success`
   - quick confirmation
   - fades out within 500 to 700 ms

8. `error`
   - warm color shift
   - short error copy
   - optional action: `Open logs` or `Retry paste`

### 6.3 Animation Language

The animations should feel restrained and precise, not playful.

Recommended rules:

- use easing that feels physical, not bouncy
- animate opacity, scale, blur, and wave amplitude
- avoid giant zooms or large panel slides
- all state transitions should complete within 120 to 240 ms except success fade

### 6.4 Waveform Recommendation

Do not render the full audio waveform in real time.

Recommended approach:

- compute RMS + peak from live microphone frames
- smooth values over 40 to 80 ms
- drive 3 to 7 animated bars or a soft blob wave

This gives the impression of responsive audio without the complexity of waveform history rendering.

### 6.5 Optional Mini Indicator

Superwhisper’s mini-window concept is worth adopting on Windows:

- optional always-visible mini indicator
- sits near bottom-center or user-selected corner
- on hover, reveals:
  - start recording
  - settings
  - expand HUD

This should be optional, off by default.

## 7. Settings and Navigation Direction

The app should evolve from a single settings panel into a proper small desktop app shell.

Recommended information architecture:

### 7.0 Navigation Shell

Match the screenshot direction closely without cloning it:

- left rail navigation
- compact title/header bar
- one main content area
- settings shown as grouped cards, not giant forms

Recommended first-level navigation:

- `Home`
- `Modes`
- `Vocabulary`
- `Configuration`
- `Sound`
- `History`

This structure is correct for FlowType as well.

### 7.1 General

- launch at login
- tray behavior
- recording HUD enabled
- mini indicator enabled
- paste after cleanup
- clipboard-only fallback behavior

### 7.2 Shortcuts

- hold-to-talk
- toggle recording
- cancel recording
- re-paste last result
- optional mode-switch shortcut
- inline shortcut capture UI with reset buttons
- allow push-to-talk and toggle-record shortcuts to coexist

### 7.3 AI Providers

- provider selection
- API key
- endpoint/base URL where applicable
- model selection
- temperature and cleanup strictness only in advanced mode
- `Test connection` button

OpenRouter deserves a first-class curated picker:

- show recommended free models
- show recommended paid models
- show simple capability tags:
  - `Fast`
  - `Balanced`
  - `Best Quality`
  - `Free`
  - `Paid`
- show short descriptions, not raw model IDs by default
- allow an advanced override field for manual model IDs

Do not dump the entire OpenRouter catalog into the default picker.

The right default behavior is:

- curated list first
- advanced custom model second
- raw endpoint editing in advanced settings

Do not show fake benchmark numbers. If quality indicators are shown, they must be framed as:

- `Recommended for speed`
- `Recommended for quality`
- `Low cost`
- `High context`

Only show numeric accuracy if FlowType owns a real benchmark.

### 7.4 Dictation

- transcription model
- language
- max duration
- silence handling
- filler-word removal intensity
- auto-paste toggle
- paste result text toggle
- playback / sound-effects behavior when recording
- microphone source selection
- recording window style:
  - `Classic`
  - `Mini`

### 7.5 Advanced

- paste delay
- clipboard restore
- logging level
- debug overlay
- fallback behavior
- app activation / context discovery toggle
- per-app activation rules
- per-app mode mapping

### 7.6 History

- recent transcripts
- raw transcript vs cleaned output
- paste success/failure
- re-copy / re-paste / export

History is not required for the next build, but the shell should leave space for it.

### 7.7 Modes

Modes should be promoted to a first-class concept, as shown in the screenshots.

A mode should encapsulate:

- name
- provider
- cleanup model
- optional transcription model
- language
- cleanup style or preset
- app activation rules
- vocabulary scope

Recommended starter modes:

- `Default`
- `Message`
- `Email`
- `Note`
- `Meeting`

### 7.8 Vocabulary

Vocabulary is worth shipping early because it materially improves daily-use quality.

Vocabulary should support:

- names
- company terms
- product names
- acronyms
- custom spellings
- optional spoken-to-written replacements

Examples:

- spoken: `open router`
  written: `OpenRouter`
- spoken: `anti gravity`
  written: `AntiGravity`
- preserve exact term: `Faster-Whisper`

Vocabulary should be attachable:

- globally
- per mode
- per app

## 8. Prompt and Context Assembly Direction

The cleanup prompt must become dynamic and composable.

It should not stay as one static string forever.

Recommended prompt assembly order:

1. base system rules
   - preserve meaning
   - remove filler words only when appropriate
   - fix punctuation and grammar
   - return only cleaned text

2. active mode instructions
   - email style
   - notes style
   - message style
   - meeting style

3. vocabulary guidance
   - protected spellings
   - preferred spellings
   - spoken-to-written mappings

4. app/context hints
   - active application
   - optional website/domain
   - optional detected field type

5. user transcript

Recommended internal model:

```python
@dataclass
class PromptContext:
    base_rules: str
    mode_rules: str
    vocabulary_rules: list[str]
    app_rules: list[str]
    raw_text: str
```

This allows the UI to control configuration without hard-coding prompt strings in random places.

### 8.1 Context Discovery

The screenshots show app-activation and website-specific behavior. That is worth preserving.

FlowType should eventually support:

- active app detection
- optional website/domain matching
- per-app mode activation
- per-app vocabulary injection

This should remain optional and privacy-respecting:

- no remote logging of app names
- local-only app detection
- no cloud service required for context lookup

## 9. Provider Architecture Direction

Provider support should be broader than OpenRouter.

Recommended first-class providers:

- OpenRouter
- OpenAI
- Anthropic
- xAI
- Ollama
- Custom OpenAI-compatible endpoint

### 8.1 Why This Set

- OpenRouter remains the easiest gateway for cost-conscious users
- OpenAI is the default mainstream direct provider
- Anthropic is a common direct preference
- xAI/Grok matters for users who want it directly
- Ollama covers fully local cleanup
- Custom OpenAI-compatible covers many future vendors without dedicated code

### 8.2 Provider Transport Types

Implement the provider layer around transport families, not individual brands.

Suggested transport families:

- `openai_compatible_chat`
- `anthropic_messages`
- `ollama_chat`

Examples:

- OpenRouter: `openai_compatible_chat`
- OpenAI: `openai_compatible_chat`
- xAI: `openai_compatible_chat`
- Anthropic: native `anthropic_messages`
- Ollama: native `ollama_chat`
- Custom gateway: `openai_compatible_chat`

### 8.3 Recommended Interface

```python
class CleanupProvider(Protocol):
    def validate(self, credentials: ProviderCredentials) -> ValidationResult: ...
    def clean_text(self, request: CleanupRequest) -> CleanupResult: ...
```

Suggested request shape:

```python
@dataclass
class CleanupRequest:
    raw_text: str
    prompt: str
    model: str
    temperature: float
    max_tokens: int
```

### 8.4 Provider Notes

- Anthropic has a native Messages API and also documents OpenAI SDK compatibility. Use the native adapter for correctness, not the compatibility layer as the primary path.
- xAI documents chat completions at `https://api.x.ai/v1/chat/completions`, but calls that a legacy endpoint, so the adapter should keep the transport swappable.
- Ollama documents a local `POST /api/chat` endpoint and should be treated as the no-key local provider path.

References:

- Anthropic Messages API: https://platform.claude.com/docs/en/build-with-claude/working-with-messages
- Anthropic OpenAI compatibility: https://platform.claude.com/docs/en/api/openai-sdk
- xAI chat completions: https://docs.x.ai/developers/model-capabilities/legacy/chat-completions
- Ollama chat API: https://docs.ollama.com/api/chat

### 8.5 Credential Storage

Do not keep long-term API keys in plaintext config as the polished default.

Recommended direction:

- use Windows Credential Manager via `keyring`
- keep non-secret provider settings in config
- keep only a pointer or provider ID in config, not the raw secret where possible

The current TOML-based API-key storage is acceptable only as an interim implementation.

## 10. Windows-Specific UX Requirements

These are mandatory for the polished version:

- single-instance app lock
- no focus stealing from the active app
- per-monitor DPI awareness
- overlay appears on the monitor that currently owns the active window/cursor
- topmost overlay that does not intercept typing
- graceful fallback for elevated apps where simulated paste is blocked
- optional startup on login

Known Windows risks to account for:

- elevated targets can block simulated paste
- password fields and secure inputs may reject or ignore automation
- `Win` shortcuts can be intercepted before the app sees them
- IME/language-switch shortcuts can conflict with dictation shortcuts

## 11. Current Core Boundaries To Preserve

Another engineer should preserve these boundaries:

- `audio.py`: capture audio and emit level telemetry
- `transcriber.py`: local transcription only
- `cleanup.py`: provider abstraction entry point
- `output.py`: clipboard + paste delivery
- `pipeline.py`: orchestration only
- UI layer: consumes state, never owns business logic
- prompt assembly layer: composes mode + vocabulary + app context into cleanup instructions

Do not let the UI rewrite the transcription and cleanup logic.

## 12. First Personal-Use Milestone

Your stated goal is to use this yourself first before packaging it for others.

That means the next build should optimize for a stable single-user Windows beta before broad release polish.

The first personal-use milestone should include:

- polished `PySide6 + QML` shell
- bottom recording HUD
- hold + toggle shortcuts
- OpenRouter curated model picker
- direct OpenAI support
- modes
- vocabulary
- auto-paste configuration
- stable Windows paste behavior
- local logs and easy diagnostics

That is enough to become your daily driver.

The public-release milestone can come after that with:

- secure credential storage
- fuller provider matrix
- installer refinement
- onboarding polish
- history and export

## 13. Recommended Next Build Order

### Phase A: UI shell foundation

- adopt `PySide6 + QML`
- replace tray/settings shell
- add single-instance guard
- add state/event bridge from pipeline to UI

### Phase B: recording HUD

- bottom overlay
- waveform animation
- processing states
- success/error transitions

### Phase C: shortcut system

- hold / toggle / cancel shortcuts
- shortcut editor
- conflict detection

### Phase D: provider abstraction

- OpenAI-compatible adapter
- Anthropic adapter
- Ollama adapter
- settings UI for providers
- connection tests
- curated OpenRouter picker
- direct OpenAI picker
- advanced custom-model entry

### Phase E: secure secrets + history

- Windows Credential Manager
- history panel
- re-paste / copy / diagnostics

## 14. Acceptance Criteria For The Polished Version

The next-phase product is successful when:

- the user can configure providers and keys entirely from the app
- the user can customize shortcuts without touching config files
- recording shows a bottom overlay with live audio motion
- releasing the hotkey reliably pastes into the current text field
- the app never steals focus during dictation
- the app feels visually deliberate, not like a utility script
- modes and vocabulary actually influence cleanup behavior through the prompt assembly layer
- OpenRouter users get a curated, understandable model picker instead of raw provider clutter
- the application remains local-first and does not introduce a FlowType-hosted backend

## 15. Explicit Non-Goals For The Next UI Pass

- do not add a giant full-screen dashboard
- do not add browser-style navigation unless history truly requires it
- do not prioritize theme systems before the recording HUD is excellent
- do not try to support every provider with one-off hacks; use transport families
- do not replace the local transcription core
- do not require a FlowType cloud account
- do not make the app depend on a vendor-hosted backend controlled by FlowType
