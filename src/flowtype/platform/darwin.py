"""macOS platform backend (pyobjc).

NOTE: This is the first-pass macOS implementation. It is written against the documented
PyObjC / AppKit APIs but has NOT yet been run on a Mac — it is exercised only when the
app runs on darwin, and is validated by the macOS CI build + on-device testing (see
MACOS_PORT_PLAN.md, Phases 1-5). All AppKit access is import-guarded so a missing pyobjc
degrades to no-ops rather than crashing.

Out of scope here (handled elsewhere):
- The Cmd+V paste keystroke lives in output.py (Ctrl->Cmd swap there).
- The non-activating HUD panel is configured via the overlay-panel hook (Phase 2).
- Accessibility / Input-Monitoring / Microphone permission prompts (Phase 3).
- Native vibrancy (NSVisualEffectView) is deferred to Phase 5; chrome calls no-op here.
"""
from __future__ import annotations

import logging

from flowtype.platform._common import ForegroundWindowSnapshot

logger = logging.getLogger("flowtype.platform.darwin")

APP_USER_MODEL_ID = "AntiGravity.FlowType"


def is_windows() -> bool:
    return False


# ── window chrome: no native styling in v1 (Qt theme + system appearance only) ──
def set_app_user_model_id(app_id: str = APP_USER_MODEL_ID) -> None:
    return None  # macOS identity comes from the .app Info.plist bundle id


def set_native_title_bar_colors(hwnd: int, caption_hex: str, text_hex: str, border_hex: str | None = None) -> None:
    return None


def supports_mica() -> bool:
    return False  # Windows concept; macOS vibrancy is handled separately (deferred)


def set_window_backdrop_material(hwnd: int, dark: bool, material: str = "mica") -> bool:
    return False


def enable_acrylic_blur(hwnd: int, tint_argb: int = 0x140A0E14) -> bool:
    return False


def set_native_window_icon(hwnd: int, icon_path: str) -> None:
    return None  # icon comes from the .icns in the bundle


# ── foreground capture / restore (NSWorkspace + NSRunningApplication) ──
def snapshot_foreground_window() -> ForegroundWindowSnapshot | None:
    """Capture the frontmost app at record-start so we can deliver text back to it.

    On macOS we identify the target app by PID + bundle id (there is no portable, non-
    Accessibility way to get the focused *window*); that's enough to re-activate it and
    paste, and the bundle id doubles as the per-app Modes key.
    """
    try:
        from AppKit import NSWorkspace

        app = NSWorkspace.sharedWorkspace().frontmostApplication()
        if app is None:
            return None
        return ForegroundWindowSnapshot(
            hwnd=0,
            title=str(app.localizedName() or ""),
            process_id=int(app.processIdentifier()),
            process_name=str(app.bundleIdentifier() or ""),
        )
    except Exception as exc:  # pyobjc missing or AppKit error
        logger.debug("snapshot_foreground_window failed: %s", exc)
        return None


def restore_foreground_window(snapshot: ForegroundWindowSnapshot | None) -> bool:
    """Re-activate the captured app before pasting. Requires the Accessibility grant to
    reliably steal focus; without it macOS may ignore the activation (silent)."""
    if snapshot is None or not snapshot.process_id:
        return False
    try:
        from AppKit import NSRunningApplication

        app = NSRunningApplication.runningApplicationWithProcessIdentifier_(snapshot.process_id)
        if app is None:
            return False
        # activateWithOptions_(0) is the broadly-compatible call. macOS 14+ prefers the
        # cooperative activateFromApplication_options_, to be adopted once verified on HW.
        return bool(app.activateWithOptions_(0))
    except Exception as exc:
        logger.debug("restore_foreground_window failed: %s", exc)
        return False


def is_fullscreen_app_foreground() -> bool:
    # v1: let the HUD ride over fullscreen apps; a proper CGWindow check is a later refinement.
    return False


# ── HUD overlay: make the QML window a non-activating panel so it floats over other apps
#    WITHOUT stealing keyboard focus (otherwise every paste target would be lost). ──
def configure_overlay_panel(window) -> bool:
    """Reconfigure a Qt overlay window's underlying NSWindow as a non-activating,
    always-visible status panel. Called after the window is shown (and on screen change).
    Best-effort: any failure leaves the Qt flags in place and returns False."""
    try:
        import ctypes

        import objc
        from AppKit import (
            NSFloatingWindowLevel,
            NSWindowCollectionBehaviorCanJoinAllSpaces,
            NSWindowCollectionBehaviorFullScreenAuxiliary,
            NSWindowCollectionBehaviorStationary,
            NSWindowStyleMaskNonactivatingPanel,
        )

        handle = int(window.winId())
        if not handle:
            return False
        view = objc.objc_object(c_void_p=ctypes.c_void_p(handle))
        ns_window = view.window()
        if ns_window is None:
            return False

        ns_window.setStyleMask_(ns_window.styleMask() | NSWindowStyleMaskNonactivatingPanel)
        ns_window.setLevel_(NSFloatingWindowLevel)
        ns_window.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces
            | NSWindowCollectionBehaviorStationary
            | NSWindowCollectionBehaviorFullScreenAuxiliary
        )
        ns_window.setHidesOnDeactivate_(False)
        return True
    except Exception as exc:
        logger.debug("configure_overlay_panel failed: %s", exc)
        return False


def prime_permissions() -> None:
    """Proactively surface the Accessibility permission prompt at startup so the user is
    guided to grant it (synthetic paste + focus restore need it). Input Monitoring is
    registered when the pynput listener starts; Microphone prompts on first capture.
    Best-effort and silent on failure."""
    try:
        from ApplicationServices import AXIsProcessTrustedWithOptions
        from CoreFoundation import kCFBooleanTrue

        # kAXTrustedCheckOptionPrompt is a CFString constant; the string value is stable.
        AXIsProcessTrustedWithOptions({"AXTrustedCheckOptionPrompt": kCFBooleanTrue})
    except Exception as exc:
        logger.debug("prime_permissions failed: %s", exc)


def accessibility_trusted() -> bool:
    """True if the app has been granted macOS Accessibility (needed to paste + restore focus)."""
    try:
        from ApplicationServices import AXIsProcessTrusted

        return bool(AXIsProcessTrusted())
    except Exception:
        return False
