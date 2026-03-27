# GEMINI.md

## 1. Purpose

This system exists to provide a **local, reliable, low-cost voice dictation application** for Windows that transforms spoken language into clean, structured, and ready-to-use written text.

It serves:

- professionals drafting emails, messages, and notes
- operators who need fast text input without manual typing
- automation-focused users who require system-wide dictation

The system enables:

- seamless **press-to-talk → clean text output** workflows
- removal of friction in writing tasks
- transformation of raw speech into **polished, human-quality text**

This system behaves as a **personal writing assistant layer** on top of speech input, not just a transcription tool.

Success is achieved when:

- users can dictate naturally
- output requires minimal to zero editing
- the system is fast, reliable, and consistent across applications

---

## 2. Success Criteria

The system is successful when:

- Dictation latency is under **3 seconds** for typical inputs
- Transcription accuracy exceeds **95% for clear speech**
- LLM cleanup produces:
  - grammatically correct sentences
  - proper punctuation
  - removal of filler words
- System supports **continuous dictation up to 5 minutes without failure**
- Output is directly usable for:
  - emails
  - documentation
  - messaging
- System maintains:
  - zero crashes during normal operation
  - consistent hotkey responsiveness
- Monthly operating cost remains under **$2**

---

## 3. Inputs & Context

## Inputs

- Microphone audio (real-time capture)
- User-triggered hotkey events
- Raw transcription text from Whisper model
- Optional configuration:
  - LLM provider (OpenRouter, OpenAI)
  - model selection
  - cleanup preferences

## External Dependencies

- Faster-Whisper (local GPU transcription)
- OpenRouter API (LLM cleanup)
- Python runtime environment
- OS-level input/output hooks

## Environment Assumptions

- Windows OS
- GPU available (recommended but optional)
- Stable internet connection for LLM cleanup
- User has API keys configured

## Source of Truth

- Whisper output = ground truth transcription
- LLM output = refined version (must not alter meaning)

---

## 4. Operating Model

The system must behave as a disciplined, structured operator:

1. Capture input before acting
2. Transcribe deterministically
3. Apply cleanup as a transformation layer
4. Deliver output without altering user intent

Behavior rules:

- Always process audio fully before cleanup
- Never truncate user input
- Never fabricate missing words
- Preserve meaning over stylistic changes
- Prefer minimal transformation over aggressive rewriting

The AI must:

- explain reasoning when debugging
- not silently change system behavior
- prioritize reliability over cleverness

---

## 5. Core Capabilities

## 5.1 Audio Processing

- Capture microphone input via push-to-talk
- Support variable input durations (up to 5+ minutes)
- Handle buffering and chunking safely

## 5.2 Transcription

- Use Faster-Whisper for deterministic transcription
- Prefer GPU acceleration when available
- Fall back to CPU if needed
- Ensure complete transcription without loss

## 5.3 LLM Cleanup

Transform raw text into polished output:

- remove filler words (um, uh, like)
- correct grammar
- apply punctuation
- restructure into readable sentences
- maintain original intent

## 5.4 Output Delivery

- Copy cleaned text to clipboard
- Paste into active window automatically
- Ensure compatibility across all applications

## 5.5 System Integration

- Global hotkey handling
- Background execution
- Low resource overhead

## 5.6 Debugging & Diagnostics

- log transcription time
- log API response times
- detect failures in:
  - audio capture
  - transcription
  - API calls

## 5.7 Improvement

- refine prompts
- optimize model selection
- improve latency and reliability

---

## 6. Execution Guidelines

- Prefer local transcription (Faster-Whisper) over API transcription
- Use APIs only for cleanup, not core logic
- Never rely solely on LLMs for deterministic tasks
- Validate all API responses before use
- Retry failed API calls with exponential backoff
- Keep execution pipeline linear and predictable

Tool usage rules:

- Audio capture: sounddevice or pyaudio
- Hotkey detection: keyboard or pynput
- Clipboard: pyperclip
- HTTP: requests or equivalent

Never:

- hallucinate API behavior
- assume undocumented features
- skip error handling

---

## 7. Safety Rules & Constraints

- Never delete or overwrite user data without confirmation
- Never fabricate transcription content
- Never modify meaning during cleanup
- Always preserve original intent
- Maintain logs for debugging
- Ensure fallback behavior if API fails:
  - return raw transcription

System constraints:

- Must work offline for transcription
- Must degrade gracefully if LLM unavailable
- Must not crash on long inputs

---

## 8. Self Improving Loop

The system must continuously improve via:

## Feedback Loop

1. Capture failure cases:
   - incorrect transcription
   - poor formatting
   - slow response
2. Diagnose root cause:
   - model issue
   - prompt issue
   - execution bottleneck
3. Apply fixes:
   - adjust prompt
   - change model
   - optimize pipeline
4. Update directive with learning
5. Prevent recurrence

## Learning Storage

- maintain prompt improvements
- log common errors
- refine cleanup strategies

## Adaptation

- update to new Whisper models
- switch LLM providers if needed
- optimize based on user usage patterns

---

## 9. Best Practices

## Dictation Design

- use push-to-talk (not always-on)
- segment long audio if needed
- avoid over-processing small inputs

## Prompt Engineering

- keep cleanup prompts deterministic
- avoid creative rewriting
- enforce “preserve meaning” constraint

## Performance

- prioritize GPU inference
- minimize API calls
- batch operations when possible

## Reliability

- always return output (never fail silently)
- implement retries
- maintain logs

## Code Design

- modular pipeline (audio → transcription → cleanup → output)
- avoid tightly coupled logic
- isolate external dependencies

---

## 10. Response Style

When operating or assisting:

1. Diagnosis  
   - identify issue or requirement clearly  

2. Proposed Solution  
   - explain approach before execution  

3. Implementation  
   - provide concrete code or steps  

4. Explanation  
   - clarify why solution works  

5. Optimization  
   - suggest improvements  

Tone:

- precise
- practical
- non-generic
- focused on execution

---

## 11. Summary

This system is a **local-first AI dictation engine** that transforms speech into clean, structured text with minimal latency and cost.

It combines:

- deterministic transcription (Faster-Whisper)
- intelligent refinement (LLM cleanup)
- seamless system integration (hotkey + paste)

It behaves as a **personal writing assistant**, continuously improving through feedback, optimization, and evolving directives.

The long-term role of this system is to eliminate typing friction and enable **fast, reliable, and intelligent text generation from speech**.

---

## 12. Changelog

## 2026-03-26

- Confirmed `pynput` for both global hotkey handling and `Ctrl+V` paste simulation.
- Confirmed `%APPDATA%\\FlowType\\` as the runtime location for config, logs, and Whisper model cache in packaged Windows installs.
- Confirmed `compute_type = "auto"` so CUDA uses `float16` and CPU uses `int8` without manual edits.
- Confirmed cleanup must always fall back to the raw transcript when the provider is unavailable, misconfigured, or times out.
- Confirmed a hard recording cap and minimum-duration guard are required for daily-use reliability.
- Confirmed model download should happen on first run and should not be bundled into the installer.
- Confirmed the current transcription pipeline is fixed to `16000 Hz` and `int16` input until explicit resampling support is added.
- Confirmed API-key entry and core setup should be available from an in-app settings surface, not only from manual file edits.
- Confirmed the recorder should pass normalized audio arrays directly to the transcriber to avoid redundant in-memory WAV serialization.
- Confirmed modes and vocabulary must feed the cleanup prompt assembly layer instead of living as UI-only placeholders.
- Confirmed desktop-shell saves must reload the live runtime immediately so shortcuts and provider changes apply without restart.
- Confirmed the packaged app must ship the QML shell resources explicitly; relying on implicit discovery is not acceptable for Windows builds.
- Confirmed CUDA model warm-up alone is not a sufficient health check; automatic CPU retry is required when first inference fails under `device = "auto"`.
- Confirmed cleanup instructions must explicitly forbid deduplicating repeated sentences, because some models otherwise compress long repeated dictation despite a generic no-summary rule.

## 2026-03-27

- Confirmed the packaged Windows app must behave as a background utility: close-to-tray by default, tray quit for full exit, and single-instance activation instead of duplicate launches.
- Confirmed startup-at-login needs a real per-user Windows Run-key integration and should launch minimized in the tray when enabled.
- Confirmed branding is part of the product contract, not decoration; the EXE, window, tray, taskbar, Start Menu, and installer all need FlowType-native assets instead of generic Python or placeholder icons.
- Confirmed `assets\\branding\\logo-mark.svg` is the current brand source file and generated runtime/installer assets should be reproducible from it.
- Confirmed the packaged beta path must include validation of the frozen `.exe`, installer generation, silent install, silent uninstall, and branded artifact checks before calling a build release-ready.
