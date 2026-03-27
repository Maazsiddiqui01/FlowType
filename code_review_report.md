# FlowType Code Review Report

**Reviewer:** Senior System Architect
**Date:** March 26, 2026
**Target:** FlowType Phase 1 MVP (`src/flowtype/`)

## 1. Critical Issues

### 1.1 Audio Format Assumptions in `Transcriber` vs `Audio`
* **What is wrong:** `config.py` allows configuring `sample_rate` and `dtype`. `audio.py` captures and encodes audio dynamically based on these settings. However, `transcriber.py:148` hardcodes decoding: `np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0`. It also implicitly passes the array to Faster-Whisper, which strictly requires a `16000` Hz sample rate. If a user sets `sample_rate = 44100` or `dtype = "float32"` in `config.toml`, `transcriber.py` will misinterpret the bytes, causing Faster-Whisper to hallucinate or crash.
* **Why it matters:** Violates the deterministic transcription requirement. If a user's microphone only supports 48kHz and they change the config, the app breaks.
* **Fix:** Add strict validation in `config.py` enforcing `sample_rate == 16000` and `dtype == "int16"` to guarantee safety. If dynamic sampling rates are needed later, implement `scipy.signal.resample` in `transcriber.py`.

### 1.2 `pynput` Paste Simulation Race Condition
* **What is wrong:** `output.py` uses `pynput.keyboard.Controller` to simulate `Ctrl+V`. When the user releases the push-to-talk hotkey (`Ctrl+Shift+Space`), `pipeline.py` instantly starts processing. If transcription and API cleanup finish in < 200ms (e.g. "Okay"), `output.py` simulates `Ctrl+V` *while the user is still physically lifting their fingers from the Shift or Space keys*.
* **Why it matters:** Simulating `v` while the user's physical `Shift` key is still pressed results in `Ctrl+Shift+V` being sent to the active window instead of `Ctrl+V`. Many applications ignore `Ctrl+Shift+V` or interpret it as an alternative action.
* **Fix:** In `output.py:_paste_via_keyboard()`, explicitly release the hotkey modifier keys (`shift`, `alt`, etc.) using the controller before pressing `v`, or enforce a minimum safety delay before pasting if the dictation was incredibly brief.

## 2. Improvements

### 2.1 Clipboard Restoration Timing
* Currently, if `restore_clipboard = true`, `output.py` waits `100ms` (`time.sleep(0.1)`) after sending `Ctrl+V` before restoring the original clipboard. For heavier Windows applications (like MS Word, IDEs, or Electron apps), `100ms` is too fast. The app may read the clipboard asynchronously at `150ms` and accidentally paste the restored clipboard content instead of the dictated text.
* **Improvement:** If users enable `restore_clipboard`, increase the delay to `500ms`. 

### 2.2 System Tray Graceful Thread Termination
* `pipeline.py` spawns a daemon thread for `_process_capture`. If the user right-clicks the tray and hits "Quit" during a long API call, `pipeline.stop()` joins the thread with a 2-second timeout and forcibly exits.
* **Improvement:** Pass a custom `threading.Event` shutdown flag to `TextCleaner` to abort the `httpx` HTTP request gracefully on quit, preventing hanging connections.

## 3. Suggested Refactors

### 3.1 Unnecessary WAV Serialization
* `audio.py` converts numpy audio chunks to a WAV byte string (`_encode_wav`). `transcriber.py` immediately parses that WAV string back into a numpy array using the python `wave` module.
* **Refactor:** Define `CapturedAudio.audio_array: np.ndarray` (as `float32`) directly from `audio.py`. Bypass the WAV encoding/decoding entirely for in-memory transfers. Only encode to WAV if you explicitly need to dump it to a debug directory. This reduces memory copying during long 5-minute dictations.

## 4. Alignment with GEMINI.md

The MVP is exceptionally well-aligned with the `GEMINI.md` directives:
- **Local Transcription:** Uses `faster-whisper` and correctly implements the changelog requirement: `compute_type = "auto"` automatically maps to `float16` for CUDA and `int8` for CPU without manual user edits (`transcriber.py:141`).
- **Resilience:** Implements a strict recording cap (`300s`) and minimum-duration guard (`250ms`), perfectly matching the new changelog constraints.
- **Fail-safe Cleanup:** `cleanup.py:82` always falls back to the exact raw transcript if the OpenRouter provider times out or the API key is misconfigured. Zero truncation.
- **Dependencies:** Exclusively implements the required tool choices: `sounddevice` (audio), `pynput` (hotkeys & clipboard paste), `faster-whisper` (transcription), and `httpx` (API requests).
- **Paths:** Adheres perfectly to the `%APPDATA%\FlowType\` pathing for configuration, logs, and dynamically downloaded models (`config.py:166`).

## 5. Final Recommendation

**The implementation is excellent. The architecture is clean, highly modular, and heavily respects constraints.**
Once the `16000Hz/int16` format assumption is locked down via config validation and the `Shift+V` race condition is patched, this MVP is fully ready to be packaged via `PyInstaller` for Phase 3 user testing. You've struck a perfect balance between robust failure handling and minimal overhead.
