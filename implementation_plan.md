# FlowType — Implementation Plan

A local-first, Windows-native AI dictation engine. Press a key, speak, get clean text pasted into any application.

> Next-phase product direction for the polished Windows shell now lives in:
> - `docs/NEXT_PHASE_PRODUCT_DIRECTION.md`
> - `docs/UI_IMPLEMENTATION_BACKLOG.md`

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FlowType Process                      │
│                                                          │
│   ┌──────────┐   ┌──────────────┐   ┌──────────────┐   │
│   │  Hotkey   │──▶│ Audio        │──▶│ Transcriber  │   │
│   │  Listener │   │ Recorder     │   │ (Whisper)    │   │
│   └──────────┘   └──────────────┘   └──────┬───────┘   │
│                                             │            │
│   ┌──────────┐   ┌──────────────┐   ┌──────▼───────┐   │
│   │  Output   │◀──│ Clipboard +  │◀──│ LLM Cleanup  │   │
│   │  (Paste)  │   │ Paste        │   │ (OpenRouter)  │   │
│   └──────────┘   └──────────────┘   └──────────────┘   │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │  System Tray UI  (status, settings, quit)        │  │
│   └──────────────────────────────────────────────────┘  │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │  Config + Logging                                │  │
│   └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack Decision

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Language | **Python 3.11+** | Faster-Whisper is Python-native; ecosystem maturity |
| Audio capture | **sounddevice** | Clean API, low latency, well-maintained on Windows |
| Transcription | **faster-whisper** (`base.en` default) | Local GPU/CPU, fast, deterministic |
| LLM cleanup | **OpenRouter API** via `httpx` | Async-capable, cheap models (DeepSeek, Llama) |
| Hotkey | **pynput** | Reliable global hotkey capture on Windows |
| Clipboard + paste | **pyperclip** + `pyautogui` | Cross-app paste via Ctrl+V simulation |
| System tray | **pystray** + **Pillow** | Native Windows tray icon, simple |
| Config | **TOML file** (`config.toml`) | Human-readable, Python 3.11 has `tomllib` built-in |
| Logging | **Python `logging`** | Standard, file-rotated, zero overhead |
| Packaging | **PyInstaller** | Single `.exe` or folder bundle for Windows |
| Installer | **Inno Setup** | Professional Windows installer, free, well-documented |

### Why NOT Electron / Tauri / C#

- The core value lives in the Python pipeline (Whisper + LLM). Wrapping in Electron adds 200MB+ bloat.
- Tauri requires Rust FFI to call Python — unnecessary complexity for an MVP.
- C# would need IPC to Python anyway. Pure Python keeps the stack single-language.
- **pystray** gives us a native system tray icon without a GUI framework.
- PyInstaller produces a real `.exe`. Combined with Inno Setup, we get a proper installer.

---

## 2. Phased Implementation

### Phase 1 — MVP Core Pipeline (Ship first, validate loop)

> **Goal:** Press hotkey → record → transcribe → clean → paste. Console only. No GUI.

| Step | Deliverable | Module |
|------|------------|--------|
| 1.1 | Project scaffold + config system | `config.py`, `config.toml` |
| 1.2 | Audio recorder (push-to-talk) | `audio.py` |
| 1.3 | Whisper transcription | `transcriber.py` |
| 1.4 | LLM cleanup via OpenRouter | `cleanup.py` |
| 1.5 | Clipboard + auto-paste output | `output.py` |
| 1.6 | Hotkey orchestrator (binds all) | `pipeline.py` |
| 1.7 | Main entry point + CLI runner | `main.py` |
| 1.8 | End-to-end manual test | — |

**Exit criteria:** User presses `Ctrl+Shift+Space`, speaks for 30 seconds, releases, and clean text appears at cursor within 3 seconds of release.

---

### Phase 2 — System Tray + Resilience

> **Goal:** Background app with tray icon, graceful error handling, fallback modes.

| Step | Deliverable | Module |
|------|------------|--------|
| 2.1 | System tray icon + menu | `tray.py` |
| 2.2 | Visual feedback (recording/processing indicators) | `tray.py` |
| 2.3 | Fallback: paste raw transcript if LLM fails | `cleanup.py` |
| 2.4 | Retry logic with exponential backoff | `cleanup.py` |
| 2.5 | File-rotated logging | `logger.py` |
| 2.6 | Startup validation (GPU check, API key check) | `config.py` |

**Exit criteria:** App runs from tray, shows status, handles API failures gracefully, logs all operations.

---

### Phase 3 — Packaging + Installer

> **Goal:** Distributable `.exe` with a proper Windows installer.

| Step | Deliverable |
|------|------------|
| 3.1 | PyInstaller spec file + build script | 
| 3.2 | Inno Setup installer script |
| 3.3 | Auto-start on Windows login (optional, user-configurable) |
| 3.4 | First-run config wizard (set API key) |

**Exit criteria:** Download `.exe` installer → install → configure API key → use immediately.

---

### Phase 4 — Polish + Self-Improving Loop

> **Goal:** Production hardening, prompt optimization, usage analytics.

| Step | Deliverable |
|------|------------|
| 4.1 | Prompt tuning based on real usage |
| 4.2 | Model selection optimization |
| 4.3 | Long dictation chunking (5+ minutes) |
| 4.4 | Settings GUI panel (model, hotkey, provider) |
| 4.5 | Update GEMINI.md with learnings |

---

## 3. Separation of Concerns

### Directives (What to do)

Lives in [GEMINI.md](file:///d:/AntiGravity/FlowType/GEMINI.md) and `config.toml`. Defines:
- Cleanup prompt text and constraints
- Model selection and provider
- Hotkey binding
- Behavior rules (fallback, retry, preserve meaning)

These are **configuration**, not code. Changing a prompt or model should never require code changes.

### Orchestration (When to do it)

Lives in `pipeline.py`. The single coordinator that:
1. Listens for hotkey press → starts recording
2. Listens for hotkey release → stops recording
3. Calls transcriber → calls cleanup → calls output
4. Handles errors and fallbacks at each stage
5. Emits status updates to tray icon

This is the **only** module that knows about the full pipeline. Swap any component without touching orchestration.

### Execution (How to do it)

Isolated modules, each with a single responsibility:

| Module | Responsibility | Interface |
|--------|----------------|-----------|
| `audio.py` | Record mic → return WAV bytes | `record_start()`, `record_stop() → bytes` |
| `transcriber.py` | WAV bytes → raw text | `transcribe(audio: bytes) → str` |
| `cleanup.py` | Raw text → clean text | `cleanup(text: str) → str` |
| `output.py` | Text → clipboard + paste | `deliver(text: str)` |
| `tray.py` | System tray lifecycle | `set_status(state)`, `run()` |
| `config.py` | Load/validate config | `load() → Config` |

---

## 4. Detailed Module Specifications

### 4.1 `config.py` + `config.toml`

```toml
[general]
hotkey = "ctrl+shift+space"
log_level = "INFO"
log_file = "~/.flowtype/flowtype.log"

[audio]
sample_rate = 16000
channels = 1
dtype = "int16"

[transcription]
model_size = "base.en"
device = "auto"          # "auto" | "cuda" | "cpu"
compute_type = "float16" # "float16" | "int8" | "float32"

[cleanup]
provider = "openrouter"  # "openrouter" | "openai"
api_key = ""             # user must set this
model = "deepseek/deepseek-chat"
prompt = """Clean up the following dictated text. Fix grammar, punctuation, and remove filler words (um, uh, like, you know). Preserve the original meaning exactly. Do not add, remove, or change any ideas. Return only the cleaned text, nothing else."""
max_tokens = 2048
temperature = 0.1

[output]
paste_method = "ctrl_v"  # "ctrl_v" | "clipboard_only"
paste_delay_ms = 50
```

**Key decisions:**
- `device = "auto"` tries CUDA first, falls back to CPU. No user confusion.
- `model_size = "base.en"` is the sweet spot: fast, accurate for English, small download (~150MB).
- `deepseek/deepseek-chat` on OpenRouter costs ~$0.14/M input tokens. A 5-minute dictation ≈ 1000 words ≈ 1500 tokens ≈ $0.0002 per use. Well under $2/month even with heavy use.
- `temperature = 0.1` keeps cleanup deterministic without being fully greedy.

### 4.2 `audio.py`

```python
# Core API:
class AudioRecorder:
    def start(self) -> None
    def stop(self) -> bytes  # returns WAV-format bytes
    def is_recording(self) -> bool
```

**Implementation notes:**
- Uses `sounddevice.InputStream` with a callback that appends to a `bytearray` buffer.
- On `stop()`, wraps buffer in a WAV header using `wave` module (stdlib).
- No file I/O during recording — everything in memory for speed.
- For 5 minutes at 16kHz mono int16: ~9.6MB buffer. Trivial.

### 4.3 `transcriber.py`

```python
class Transcriber:
    def __init__(self, config: TranscriptionConfig) -> None
        # Loads faster-whisper model once at startup
    
    def transcribe(self, audio_bytes: bytes) -> str
        # Returns full transcription text
```

**Implementation notes:**
- Model loaded **once** at startup, kept in memory. First transcription may take a few seconds; subsequent ones are fast.
- `faster-whisper` accepts numpy arrays directly — convert WAV bytes to numpy, pass to model.
- For 5 minutes of audio with `base.en` on GPU: ~2–4 seconds.
- On CPU: ~8–15 seconds (acceptable for MVP, note in docs).

### 4.4 `cleanup.py`

```python
class TextCleaner:
    async def cleanup(self, raw_text: str) -> str
        # Returns cleaned text, or raw_text on failure
```

**Implementation notes:**
- Uses `httpx.AsyncClient` for non-blocking API calls.
- OpenRouter endpoint: `https://openrouter.ai/api/v1/chat/completions`
- Request format is OpenAI-compatible (same schema).
- **Fallback:** If API call fails after 3 retries, return raw transcript with a log warning.
- Short inputs (< 10 words) skip cleanup entirely — not worth the API call.

### 4.5 `output.py`

```python
class OutputDelivery:
    def deliver(self, text: str) -> None
        # Copy to clipboard + simulate paste
```

**Implementation notes:**
- `pyperclip.copy(text)` — sets clipboard.
- `pyautogui.hotkey('ctrl', 'v')` — simulates paste.
- Small delay (50ms) between clipboard set and paste to ensure OS propagation.
- Saves previous clipboard content and optionally restores it after paste (Phase 2 enhancement).

### 4.6 `pipeline.py`

```python
class DictationPipeline:
    def __init__(self, config, recorder, transcriber, cleaner, output, tray=None)
    
    async def on_hotkey_press(self) -> None
    async def on_hotkey_release(self) -> None
    
    def run(self) -> None  # main loop
```

**Flow:**
1. `on_hotkey_press`: Start recording. Update tray to "Recording…"
2. `on_hotkey_release`: Stop recording. Update tray to "Processing…"
3. Transcribe audio → raw text
4. If raw text is empty, abort (nothing spoken)
5. Clean up text via LLM
6. Deliver to active window
7. Update tray to "Ready"
8. Log all timings

---

## 5. Project Structure

```
d:\AntiGravity\FlowType\
├── GEMINI.md                 # System directive (existing)
├── README.md                 # User-facing docs
├── pyproject.toml            # Project metadata + dependencies
├── config.toml               # Default configuration
├── src/
│   └── flowtype/
│       ├── __init__.py
│       ├── __main__.py       # Entry point: python -m flowtype
│       ├── main.py           # App bootstrap + lifecycle
│       ├── config.py         # Config loading + validation
│       ├── audio.py          # Microphone recording
│       ├── transcriber.py    # Faster-Whisper wrapper
│       ├── cleanup.py        # LLM cleanup via OpenRouter
│       ├── output.py         # Clipboard + paste delivery
│       ├── pipeline.py       # Orchestration
│       ├── tray.py           # System tray (Phase 2)
│       └── logger.py         # Logging setup
├── assets/
│   └── icon.ico              # Tray icon
├── tests/
│   ├── test_config.py
│   ├── test_audio.py
│   ├── test_transcriber.py
│   ├── test_cleanup.py
│   └── test_output.py
├── scripts/
│   ├── build.py              # PyInstaller build script (Phase 3)
│   └── installer.iss         # Inno Setup script (Phase 3)
└── .gitignore
```

---

## 6. Risks, Tradeoffs, and Mitigations

### Risk 1: Faster-Whisper CUDA setup on Windows
- **Problem:** CTranslate2 (underlying library) can be finicky with CUDA versions.
- **Mitigation:** Default to `device = "auto"`. If CUDA fails, fall back to CPU automatically with a warning log. Document CUDA 12.x requirement.
- **Tradeoff:** CPU is 3–5x slower but still usable for short dictations.

### Risk 2: Global hotkey conflicts
- **Problem:** `Ctrl+Shift+Space` may conflict with other apps (e.g., language switchers).
- **Mitigation:** Make hotkey configurable in `config.toml`. Document common alternatives. Validate on startup.
- **Tradeoff:** Minimal — configuration is a one-time effort.

### Risk 3: Paste simulation blocked by some applications
- **Problem:** Some apps (elevated terminals, secure inputs) block simulated keystrokes.
- **Mitigation:** Offer `clipboard_only` mode where text is just copied, not pasted. User manually pastes.
- **Tradeoff:** Minor UX friction in edge cases.

### Risk 4: OpenRouter API latency or downtime
- **Problem:** Adds 0.5–2s latency. If OpenRouter is down, no cleanup.
- **Mitigation:** 
  1. Fallback to raw transcript on failure (always deliver something).
  2. Consider adding local small LLM option in Phase 4 (Phi-3 mini via llama.cpp).
- **Tradeoff:** Acceptable for MVP. Raw transcript is still useful.

### Risk 5: PyInstaller bundle size with Whisper model
- **Problem:** `faster-whisper` + `base.en` model = ~300MB+ bundle.
- **Mitigation:** 
  1. Download model on first run instead of bundling it.
  2. Cache in `~/.flowtype/models/`.
  3. Keep installer small (~30MB), model downloaded separately.
- **Tradeoff:** First-run delay (30s download), but installer stays small.

### Risk 6: Long dictation memory
- **Problem:** 5 minutes at 16kHz = ~9.6MB. Fine. But edge cases with 10+ minutes?
- **Mitigation:** Set a configurable max duration (default 5 min). Warn user at 4:30. Hard stop at max.
- **Tradeoff:** Prevents runaway memory usage.

---

## 7. MVP Definition — What Ships First

**Phase 1 is the MVP.** Specifically:

```
python -m flowtype
```

That's it. A console window stays open. User presses `Ctrl+Shift+Space`, speaks, releases, and cleaned text appears at cursor.

**What's IN the MVP:**
- ✅ Push-to-talk recording
- ✅ Faster-Whisper transcription (GPU or CPU auto-detect)
- ✅ LLM cleanup via OpenRouter
- ✅ Auto-paste to active window
- ✅ Config file support
- ✅ Console logging

**What's NOT in the MVP:**
- ❌ System tray UI
- ❌ Windows installer
- ❌ Auto-start on boot
- ❌ Settings GUI
- ❌ Long dictation chunking

**Why this is the right MVP:** It validates the entire end-to-end pipeline. If the dictation quality is bad, or latency is too high, or the paste doesn't work — we find out in Phase 1, not Phase 3. Everything else is polish.

---

## 8. Directive Evolution Strategy

[GEMINI.md](file:///d:/AntiGravity/FlowType/GEMINI.md) should be updated at the end of each phase:

| Phase | Directive Updates |
|-------|-------------------|
| Phase 1 complete | Add: actual latency benchmarks, model accuracy observations, confirmed tool choices |
| Phase 2 complete | Add: fallback behavior documented, known edge cases, tray interaction patterns |
| Phase 3 complete | Add: packaging constraints, installer behavior, first-run flow |
| Phase 4 complete | Add: prompt iteration history, model comparison results, usage patterns |

**Rules for directive updates:**
1. Never remove constraints — only refine them with evidence
2. Add a `## Changelog` section to GEMINI.md
3. Extract prompt improvements into a dedicated `prompts/` directory if they grow complex
4. Keep the directive actionable — remove anything that doesn't influence behavior

---

## 9. Adjustments to GEMINI.md Direction

> [!IMPORTANT]
> The following are recommended changes to the current directive.

1. **`keyboard` library → `pynput`**: The directive suggests `keyboard` for hotkey detection. `pynput` is more reliable for global hotkeys on Windows and doesn't require admin privileges. **Recommendation: switch to pynput.**

2. **`pyperclip` is clipboard-only**: To auto-paste, we also need `pyautogui` for keystroke simulation. The directive mentions `pyperclip` but not the paste step. **Recommendation: add `pyautogui` to the tool list.**

3. **`requests` → `httpx`**: The directive suggests `requests`. For async LLM calls (non-blocking during UI updates), `httpx` is the better choice. **Recommendation: use `httpx` with async support.**

4. **Model download strategy**: Not addressed in the directive. Bundling a 150MB model in the installer is impractical. **Recommendation: add a model management section to the directive.**

5. **Cost estimate validation**: The directive targets <$2/month. With DeepSeek on OpenRouter at ~$0.14/M input tokens, and assuming 100 dictations/day at 1500 tokens each: ~150K tokens/day = $0.021/day = **$0.63/month**. Well within budget. **This target is achievable.**

---

## 10. Concrete Build Plan for Execution

### Step-by-step, ready for immediate implementation:

```
Phase 1 — Execute in this exact order:
───────────────────────────────────────

1. Create project scaffold
   - pyproject.toml with all dependencies
   - src/flowtype/ package structure
   - config.toml with defaults
   - .gitignore

2. Implement config.py
   - Load config.toml using tomllib
   - Validate required fields (API key)
   - Auto-resolve paths (~/.flowtype/)
   - Dataclass-based Config object

3. Implement logger.py
   - File + console logging
   - Configurable log level
   - Log rotation (1MB max, 3 backups)

4. Implement audio.py
   - AudioRecorder class
   - sounddevice.InputStream with callback
   - Buffer to bytearray, convert to WAV on stop
   - Test: record 5 seconds, save to file, play back

5. Implement transcriber.py
   - Load faster-whisper model at init
   - Auto-detect GPU/CPU
   - Download model to ~/.flowtype/models/ if missing
   - transcribe(wav_bytes) → str
   - Test: transcribe a known WAV file

6. Implement cleanup.py
   - TextCleaner class with httpx async client
   - OpenRouter API integration
   - Retry with exponential backoff (3 attempts)
   - Fallback to raw text on failure
   - Skip cleanup for inputs < 10 words
   - Test: send known text, verify cleanup

7. Implement output.py
   - pyperclip.copy() + pyautogui.hotkey('ctrl', 'v')
   - Configurable paste delay
   - Test: deliver text to Notepad

8. Implement pipeline.py
   - Wire: hotkey → record → transcribe → clean → deliver
   - Use pynput for global hotkey listener
   - Async event loop for non-blocking LLM calls
   - Console status output (Recording... Processing... Done.)

9. Implement main.py + __main__.py
   - Bootstrap config → logger → pipeline
   - Startup validation (API key, model availability)
   - Clean shutdown on Ctrl+C

10. End-to-end integration test
    - Manual: run app, dictate 30 seconds, verify output
    - Verify: latency < 3s, text quality acceptable
```

---

## Verification Plan

### Automated Tests

Since this is a hardware-dependent application (microphone, keyboard, clipboard), **most core testing will be manual**. However, we can unit test isolated logic:

- **`test_config.py`**: Validate config loading, defaults, missing fields
  - Run: `python -m pytest tests/test_config.py -v`
  
- **`test_cleanup.py`**: Mock API responses, verify cleanup logic, retry behavior, fallback
  - Run: `python -m pytest tests/test_cleanup.py -v`

- **`test_transcriber.py`**: Transcribe a bundled test WAV file, verify output is non-empty
  - Run: `python -m pytest tests/test_transcriber.py -v`
  - Requires: a short test WAV file in `tests/fixtures/`

### Manual Verification (Phase 1 Exit)

1. **Setup:** Open a text editor (Notepad) and the FlowType console
2. **Test 1 — Basic dictation:** 
   - Press `Ctrl+Shift+Space`, say "Hello, this is a test of the dictation system", release
   - **Expected:** Clean text appears in Notepad within 3 seconds
3. **Test 2 — Filler word removal:**
   - Dictate "Um, so like, I was thinking that, uh, we should probably, you know, schedule a meeting"
   - **Expected:** "I was thinking that we should probably schedule a meeting" (or similar clean version)
4. **Test 3 — Long dictation:**
   - Speak continuously for 60 seconds
   - **Expected:** Full transcription + cleanup without truncation
5. **Test 4 — API failure fallback:**
   - Set an invalid API key in config.toml, dictate something
   - **Expected:** Raw transcript pasted (no cleanup), warning logged
6. **Test 5 — GPU/CPU detection:**
   - Check console output on startup for "Using device: cuda" or "Using device: cpu"
   - **Expected:** Correct device detected

> [!TIP]
> The user should run these manual tests after Phase 1 implementation is complete. Each test should take less than 1 minute.
