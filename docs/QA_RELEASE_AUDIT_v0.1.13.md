# FlowType QA Release Audit v0.1.13

This audit captures the final release hardening pass performed on April 4, 2026.

## Scope

- installer and packaged app validation
- shortcut flexibility and suppression behavior
- transcription and cleanup runtime reliability
- output recovery and history safety
- release hygiene and package trimming

## Release Targets

- Repo: `https://github.com/Maazsiddiqui01/FlowType`
- Release tag: `v0.1.13`
- Installer: `FlowType-Beta-0.1.13.exe`

## Automated Validation

- `python -m pytest` -> `55 passed`
- `python -m compileall src tests scripts` -> passed
- `python scripts/validate_dist.py --version 0.1.13 --expect-installer` -> passed

Coverage highlights:

- single-key and modifier-only recording shortcuts
- unsafe repaste shortcuts rejected
- result-card persistence and recent-results behavior
- pipeline busy-state protection
- history append uniqueness
- output delivery fallback to clipboard-only
- proactive CPU fallback persistence after CUDA failure

## Packaged App Validation

- installer built successfully with Inno Setup
- installed EXE version verified after local upgrade
- packaged `--warmup-only` smoke test passed
- local release hygiene maintained with only the latest release and one fallback retained

## Runtime Findings

### 1. CUDA runtime on this machine is not healthy

The machine can load the Whisper model on CUDA, but actual CUDA runtime support is incomplete because `cublas64_12.dll` is missing.

Mitigation shipped in `v0.1.13`:

- proactive CUDA runtime probe before choosing CUDA
- immediate CPU `int8` fallback when CUDA runtime is unavailable
- persistence of CPU fallback to user config so future dictations avoid the broken path

Result:

- FlowType now prefers a reliable CPU path immediately on this machine instead of discovering the failure during the first real dictation

### 2. Cleanup speed default improved

Older configs could still carry `openrouter/free`, which was slower and less predictable.

Mitigation shipped:

- load-time normalization to a speed-first curated OpenRouter model
- normalized config is now written back to disk so stale values do not linger invisibly

## Synthetic End-to-End Benchmark

Input:

- generated speech WAV
- duration: about `292.5s`

Observed result after hardening:

- warm-up: about `4.32s`
- transcription: about `7.86s`
- cleanup: about `6.09s`
- total processing after recording stop: about `13.95s`
- device used: `cpu`
- cleanup fallback: `False`

This is slower than premium cloud-first commercial tools on the same hardware, but it is now reliable and bounded on this machine.

## Product Readiness Assessment

### Ready

- packaged install/upgrade path
- tray + single-instance behavior
- transcription fallback safety
- cleanup fallback safety
- output recovery when original target cannot be restored
- recent-results access from the result surface
- safer global shortcut customization

### Watch Items

- first-launch SmartScreen reputation warning still applies to unsigned or low-reputation downloads
- real microphone behavior should still be spot-checked on at least one clean external Windows machine before broader public promotion
- CPU fallback is reliable, but users with healthy CUDA setups will still benefit from a GPU-capable benchmark pass before future performance marketing claims

## Recommended Next Features

These were intentionally not added in the final hardening pass, but they are the highest-value next steps if FlowType needs to compete more directly with Wispr Flow or Superwhisper on perceived speed and trust:

1. Speed profiles
   - `Fast`, `Balanced`, `Best cleanup`
   - switch both Whisper model and cleanup model together

2. Local rolling transcript preservation
   - write partial transcript checkpoints while long recordings process
   - prevents “all or nothing” anxiety on longer dictations

3. Paste confidence indicator
   - explicitly show `Pasted back`, `Copied only`, or `Needs manual paste`

4. First-run performance diagnostic
   - detect broken CUDA runtime or clipboard restrictions during onboarding
   - explain the fallback instead of letting users discover it later

5. Signed releases
   - code-sign EXE and installer
   - reduces SmartScreen friction and improves trust at download time
