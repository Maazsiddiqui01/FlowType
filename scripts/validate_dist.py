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


if __name__ == "__main__":
    raise SystemExit(main())
