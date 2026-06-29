# FlowType Improvement Roadmap

> Generated from a multi-agent audit (reliability / providers / UI design system / UI flows /
> lifecycle / packaging) + competitive research (Wispr Flow, Superwhisper, Aqua Voice, VoiceInk,
> Talon, Windows Voice Access) + local-Whisper technical best-practices. Owner goals: a reliable
> "always records, never times out" dictation tool, a crisp/clean **glassmorphic** UI with dark &
> light mode, freedom to bring your own AI models, Windows-first.

## Executive summary

FlowType is architecturally sound for a beta — it already nails the hard parts most clones miss:
local faster-whisper STT, decoupled bring-your-own-LLM cleanup that always degrades to the raw
transcript, CUDA→CPU fallback, atomic config writes, single-instance, and a disciplined QML design
system. The gaps are concentrated and closable:

1. It does **not yet honor the core promise** ("if someone records it must ALWAYS record"): a silent
   5-minute hard truncation, dropping every record trigger while the previous take is still
   processing, and an in-RAM-only buffer that loses the whole recording on any crash.
2. A **ship-blocking thread-safety bug** — worker/hotkey threads mutate Qt state and start/stop a
   `QTimer` cross-thread, which Qt forbids.
3. A **ship-blocking packaging bug** — ctranslate2's native DLLs are not bundled, so the packaged app
   can fail to transcribe on a clean machine even though it passes the build-machine smoke test.
4. The recording **HUD** (most-seen surface) shows no text state and is click-through (no stop/cancel),
   and there is **zero real glassmorphism** anywhere (no blur/shadow/gradient/translucency).
5. Customization gaps vs. the field: no custom LLM endpoint/`base_url` (blocks true BYO-model), no
   per-app Modes, read-only history with no per-item recovery, plaintext API keys.

## Quick wins (high impact, low effort)

- Bundle the native backend (`collect_dynamic_libs('ctranslate2'/'faster_whisper')`) in `flowtype.spec`.
- Harden `validate_dist.py` to assert native DLLs + Qt plugin + QML exist and run a real 1s CPU transcribe.
- Raise/soften the recording cap and surface `was_truncated` in the result card.
- Install `sys.excepthook` / `threading.excepthook` / `faulthandler` early in `main.cli()`.
- Add `base_url`/custom-endpoint support in cleanup (unlocks vLLM/LM Studio/LiteLLM/remote Ollama).
- Show a status word in the HUD; fix close-to-tray when tray unavailable; replace `np.interp` resampling.
- Reconcile `requirements.txt` with `pyproject` (it omits `keyboard` + `PySide6`).

## Phases

### Phase 1 — Never drop audio + correctness foundations (P0)
Make the core promise true and remove the silent-crash blind spot.
- Marshal **all** pipeline + hotkey callbacks through queued Qt signals (no cross-thread QTimer/property writes).
- Decouple capture from processing — never reject a record trigger while busy (queue captures to a serial worker).
- Stream captured audio to a temp WAV on disk during recording + orphan recovery on next launch.
- Remove/raise the silent 5-minute truncation and surface overflow in the result card + HUD warning.
- Fix thread-safety of shared pipeline state and the cancel flag.
- Fix `_actual_sample_rate` / `_max_frames` races; reset per `start()`.
- Install global exception + crash handling (`faulthandler`, excepthooks).
- Actionable audio-start and model-load failure handling that **preserves the captured audio**.

**Exit:** a 30+ min dictation completes (or is explicitly warned + capped with overflow surfaced);
pressing record while the previous take processes starts a new capture; killing the process mid-record
leaves a recoverable on-disk file offered next launch; all callbacks reach QML via queued signals; an
uncaught exception on any thread is logged + surfaced. Verified on a clean Windows VM.

### Phase 2 — HUD legibility, recovery UX, and the glass visual layer (P0)
- HUD shows distinct legible states (recording/transcribing/cleaning/pasting/error) + stop/cancel.
- Introduce **real glass**: translucent layered surfaces, blur backdrop, elevation/shadow tokens, frosted HUD.
- Repair the dark surface ramp + wire up the dead `glassHighlight` token.
- Keyboard focus rings on all controls; lift low-contrast text tokens to WCAG AA.
- Stop HUD/result-card overlap; error HUD appearance + Retry/Open-Settings recovery actions.
- Shared motion tokens; unify the lossy save model (auto-save on commit, or unsaved-changes bar).

### Phase 3 — Packaging, release trust, and the verification net (P0)
- Bundle ctranslate2/faster_whisper native DLLs in the spec.
- Harden `validate_dist.py` into a real release gate (DLLs + Qt plugin + QML + real CPU transcribe).
- Clean-machine packaged smoke test in CI (PATH scrubbed of system CUDA/MSVC/OpenMP).
- Code-sign EXE + installer; publish `SHA256SUMS`.
- First-run model-download progress + actionable failure UX.
- Tests for audio capture/resample, shortcuts + pynput fallback, and the cross-thread controller bridge.
- Reconcile `requirements.txt` with `pyproject`; pin `ctranslate2`.

### Phase 4 — Customization & power-user surface (P1)
- Custom endpoint / `base_url` for true bring-your-own-model.
- Free-text custom model id for every provider; stop auto-rewriting user model ids.
- Honor (or remove) cloud timeout/retry config; categorized, actionable cleanup errors.
- Per-app Modes that auto-activate by foreground window (model + prompt + formatting).
- Make History a recovery surface (copy / re-paste / delete / re-clean); expose result actions everywhere.
- Store API keys in the OS credential vault (Windows Credential Manager); stop leaking them.
- Harden clipboard restore + foreground restore (Windows paste reliability; ALT-key trick).

### Phase 5 — Latency, long-form streaming, stretch differentiators (P2)
- Tune faster-whisper params (`cpu_threads`, compute types); curate English/accuracy model tiers.
- VAD-segmented chunking for long recordings.
- Streaming SSE cleanup + ~500ms pre-roll capture so the first word is never clipped.
- Remaining low-severity polish (rail icons, layout breakpoints, single-instance TOCTOU, timestamped reset backup).

## Competitive north stars
- **Wispr Flow:** two-stage pipeline, pre-roll ring buffer, warm model, History with one-click Retry,
  per-app context from the foreground window (never screenshot), personal dictionary.
- **Superwhisper / VoiceInk:** Modes = model + prompt + formatting auto-activated per app; local-first;
  BYO-LLM as an optional degrading layer; deep personal dictionary; a voice-command/edit layer.
- **Windows reality:** clipboard+paste default with correct save/restore ordering; treat elevated/secure
  targets as a known failure mode; prefer `RegisterHotKey`; **code-sign** to cut SmartScreen/AV friction;
  don't use Win-key defaults (Ctrl+Shift+Space / Ctrl+Alt+Space are correct).
