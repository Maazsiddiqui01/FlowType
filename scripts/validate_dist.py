from __future__ import annotations

import argparse
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate the built FlowType distribution.")
    parser.add_argument("--version", required=True, help="Expected application version.")
    parser.add_argument("--expect-installer", action="store_true", help="Also verify the installer output exists.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project_root = Path(__file__).resolve().parent.parent
    app_dir = project_root / "dist" / "FlowType"
    exe_path = app_dir / "FlowType.exe"
    if not exe_path.exists():
        raise SystemExit(f"Missing packaged executable: {exe_path}")

    required_assets = [
        "logo-mark.png",
        "tray-ready.png",
        "tray-recording.png",
        "tray-processing.png",
        "tray-error.png",
    ]
    for asset_name in required_assets:
        if not _find_packaged_asset(app_dir, asset_name):
            raise SystemExit(f"Missing packaged branding asset: {asset_name}")

    build_branding = project_root / "build" / "branding"
    if not (build_branding / "app-icon.ico").exists():
        raise SystemExit("Missing generated build icon at build/branding/app-icon.ico")
    if not (project_root / "build" / "version_info.txt").exists():
        raise SystemExit("Missing generated version resource at build/version_info.txt")

    # Load-bearing runtime files. Their absence is the #1 "works in dev, dead on a
    # clean machine" failure, and the build host masks it because these DLLs also
    # exist system-wide on PATH. Fail the build hard instead of shipping a broken app.
    required_binaries = ["ctranslate2.dll", "libiomp5md.dll"]
    for binary_name in required_binaries:
        if not _find_packaged_file(app_dir, binary_name):
            raise SystemExit(
                f"Missing native transcription backend DLL: {binary_name}. "
                "ctranslate2/faster_whisper native libraries were not bundled (check flowtype.spec)."
            )

    if not _find_packaged_file(app_dir, "qwindows.dll"):
        raise SystemExit("Missing Qt platform plugin qwindows.dll; the desktop shell will not launch.")

    if not _find_packaged_file(app_dir, "Main.qml"):
        raise SystemExit("Missing bundled QML (Main.qml); the desktop shell will not render.")

    if args.expect_installer:
        installer = project_root / "dist-installer" / f"FlowType-Beta-{args.version}.exe"
        if not installer.exists():
            raise SystemExit(f"Missing installer output: {installer}")

    return 0


def _find_packaged_asset(app_dir: Path, asset_name: str) -> bool:
    candidates = [
        app_dir / "flowtype" / "assets" / "branding" / asset_name,
        app_dir / "_internal" / "flowtype" / "assets" / "branding" / asset_name,
    ]
    return any(candidate.exists() for candidate in candidates)


def _find_packaged_file(app_dir: Path, file_name: str) -> bool:
    """True if file_name exists anywhere in the packaged tree (onedir or _internal)."""
    return any(app_dir.rglob(file_name))


if __name__ == "__main__":
    raise SystemExit(main())
