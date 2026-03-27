# Implementation Notes

## Governing Decisions

- `GEMINI.md` remains the behavior source of truth.
- Claude's architecture was kept, but the runtime was simplified for reliability in a packaged Windows app.

## Adjustments Made Before Implementation

1. Replaced `pyautogui` with `pynput.keyboard.Controller`.
   Reason: one fewer automation dependency, smaller packaged surface area, and enough capability for `Ctrl+V`.

2. Replaced the async cleanup path with a thread-based pipeline.
   Reason: the app only needs one dictation job at a time, so threads keep the runtime simpler for tray mode and PyInstaller.

3. Added Windows app-data bootstrap behavior.
   Reason: packaged apps should read and write config, logs, and model cache from `%APPDATA%\FlowType`, not the install directory.

4. Added a hard recording cap and minimum-duration filter.
   Reason: this protects reliability for long dictation and ignores accidental hotkey taps.

5. Changed transcription `compute_type` default to `auto`.
   Reason: `float16` is correct on CUDA but not a safe default on CPU; the implementation now resolves to `float16` on CUDA and `int8` on CPU.

6. Added lazy Whisper loading with background warm-up.
   Reason: tray startup should be fast, while still keeping the model ready for normal use.

7. Moved API-key setup into a dedicated desktop settings window.
   Reason: editing TOML directly is not acceptable for a daily-use Windows utility; first-run onboarding now happens in-app.

8. Added config hot-reload in tray mode.
   Reason: saving from the settings window should immediately update provider, hotkey, and delivery behavior without manual file edits.

9. Removed the in-memory WAV round-trip.
   Reason: the recorder now hands normalized audio arrays directly to Faster-Whisper, which removes redundant serialization.

10. Replaced the placeholder QML shell with a real desktop UI surface.
   Reason: the previous shell looked interactive but still behaved like a mock-up in several places. The current shell owns provider setup, modes, vocabulary, shortcuts, sound/HUD behavior, and history.

11. Added live runtime reload for the desktop shell.
   Reason: saving shortcuts, cleanup settings, mode rules, or HUD preferences should take effect immediately without restarting the app.

12. Added prompt assembly inputs for modes and vocabulary.
   Reason: these are real product features, not decorative UI; the cleanup prompt now layers base instructions, mode guidance, and vocabulary hints together.

13. Added a local history store.
   Reason: a daily-use dictation app needs a recent-results surface for confidence, re-use, and debugging without introducing any hosted backend.

14. Added automatic CPU retry when CUDA inference fails after model load.
   Reason: live validation showed a machine can successfully warm up Faster-Whisper on CUDA and still fail on first inference because the full cuBLAS runtime is not usable. The app now falls back to CPU automatically when `device = "auto"`.

15. Hardened cleanup instructions against accidental deduplication.
   Reason: live cleanup on a repeated long dictation showed that a model can collapse repeated sentences unless the no-summarization rule explicitly forbids deduping repeated content.

16. Simplified the product shell and made the HUD contextual by default.
   Reason: the earlier six-tab shell wasted space, duplicated low-value settings, and kept an always-visible bottom HUD on screen. The current shell keeps only product-relevant sections at the top level and limits the desktop HUD to recording, processing, or a short optional ready hint.

17. Added first-class transcription language selection in the desktop shell.
   Reason: locking Whisper to the actual spoken language is a practical accuracy and latency win for daily use, and it is a better fit for the product than burying `transcription.language` in raw config.

18. Tightened cleanup behavior for real dictation instead of pure punctuation fixing.
   Reason: the product goal is not just pretty punctuation; the cleaner now explicitly allows correction of obvious ASR mistakes when context is clear while still preserving meaning and avoiding uncertain guesses.

19. Moved first-run setup into the main desktop shell.
   Reason: opening a separate fallback settings window on first launch was the wrong product experience. The app now owns provider setup, API key entry, language selection, and the skip-to-local-only path directly inside the primary UI.

20. Upgraded the HUD from passive indicator to lightweight control surface.
   Reason: the minimal bottom line now expands into a compact ready state with an in-HUD language selector, which is much closer to the intended Wispr Flow style than a permanently visible status card.

21. Added a curated direct-provider layer for Claude, Gemini, and Grok in addition to OpenRouter, OpenAI, Groq, and Ollama.
   Reason: a Windows-ready dictation app should not force everyone through one provider, but it also should not dump every model a vendor exposes into the UI. The app now presents a curated set of relevant models plus a manual override field.

22. Set recommended shortcut defaults for hold-to-talk, toggle recording, and cancel.
   Reason: the runtime already supported toggle recording, but the shipped defaults still behaved like an unfinished tool. Fresh installs now come with a sensible long-dictation path out of the box.

23. Replaced the generic cleanup settings cards with branded provider metadata and a compact curated model picker.
   Reason: the old settings surface exposed raw provider IDs and a plain model text box. The new version makes providers visually distinguishable and keeps model choice understandable.

24. Routed the CLI and runtime settings entrypoint back to the main PySide6 shell.
   Reason: leaving `--settings` and tray-driven settings on the stale Tk path would have undercut the shell rewrite and created inconsistent product behavior.

25. Tightened the mini HUD footprint again.
   Reason: the previous compact HUD was still too large compared with Wispr Flow-style overlays. The idle line, active pill, and processing state are now smaller and calmer.

26. Added Windows-native single-instance activation.
   Reason: the previous desktop shell simply exited if another instance existed. The app now restores or focuses the existing instance, and `--settings` can target the running shell instead of failing silently.

27. Added close-to-tray lifecycle behavior in the desktop shell.
   Reason: a packaged Windows dictation utility should keep running in the background when the main window closes, while still allowing a full quit from the tray menu.

28. Added Windows Run-key integration for startup-at-login.
   Reason: startup behavior must be a real OS integration, not just a config toggle. The app now registers or removes a per-user Run entry based on saved startup settings.

29. Added a branded asset pipeline from the FlowType logo mark.
   Reason: the app, tray, packaged EXE, and installer all need consistent branding. Assets are now generated reproducibly from source branding files instead of being hand-dropped placeholders.

30. Added native Windows app identity hooks.
   Reason: AppUserModelID, embedded EXE icon, window icon, and caption color treatment are required for a packaged app to feel like a real Windows product instead of a Python wrapper.

31. Added an installable Windows beta path with real validation.
   Reason: the repo no longer stops at a prototype bundle. The current implementation has a PyInstaller `onedir` build, an Inno Setup per-user installer, bundle validation, silent install/uninstall smoke tests, and a packaged launch check.

## Packaging Notes

- The bundled app is built as `onedir`, not `onefile`.
- Whisper models are not shipped inside the installer.
- The installer is expected to package the application files only; model download happens after install.
- The PyInstaller spec now explicitly includes the QML files and branding assets used by the desktop shell.
- Branding source files live under `assets\branding\`; generated runtime and installer assets are produced by `scripts\generate_branding_assets.py`.
- The branding generator now renders the source mark directly, so replacing `assets\branding\logo-mark.svg` or `assets\branding\logo-mark.png` updates the window icon, tray icons, installer art, and packaged EXE branding consistently.
- `scripts\build.py` is now the single Windows build entrypoint for the bundle and optional installer.
- `scripts\validate_dist.py` checks the packaged output for required branded assets and expected artifact names.

## Known Constraints

- Elevated windows can block simulated paste from a non-elevated FlowType process.
- Faster-Whisper GPU support on Windows still depends on a compatible CUDA runtime; CPU fallback is built in.
- Clipboard-only mode is the safe fallback for terminals, password fields, and locked-down desktops.
- Live cleanup latency still depends on the chosen provider and network conditions even when transcription remains local.
- The current unsigned beta installer is appropriate for internal testing, but SmartScreen friction should still be expected until code signing is added.
- The Windows bundle remains relatively large because PySide6, AV/FFmpeg, CTranslate2, and ONNX Runtime dominate the packaged footprint even after trimming unrelated dependencies.
