from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the branded FlowType Windows bundle.")
    parser.add_argument("--installer", action="store_true", help="Compile the Inno Setup installer after PyInstaller finishes.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        from PyInstaller.__main__ import run as pyinstaller_run
    except ModuleNotFoundError as exc:  # pragma: no cover - depends on local environment
        raise SystemExit("PyInstaller is not installed. Run `python -m pip install -e .[build]`.") from exc

    project_root = Path(__file__).resolve().parent.parent
    os.chdir(project_root)
    spec_path = project_root / "flowtype.spec"
    _ensure_branding_assets(project_root)
    version = _read_project_version(project_root)
    _write_version_file(project_root, version)
    pyinstaller_run([str(spec_path), "--noconfirm", "--clean"])
    _validate_dist(project_root, version)

    if args.installer:
        _build_installer(project_root, version)
    return 0


def _ensure_branding_assets(project_root: Path) -> None:
    svg_source = project_root / "assets" / "branding" / "logo-mark.svg"
    png_source = project_root / "assets" / "branding" / "logo-mark.png"
    if not svg_source.exists() and not png_source.exists():
        raise SystemExit("Missing branding source asset at assets/branding/logo-mark.svg or assets/branding/logo-mark.png")
    subprocess.run(
        [os.sys.executable, str(project_root / "scripts" / "generate_branding_assets.py")],
        check=True,
    )


def _read_project_version(project_root: Path) -> str:
    pyproject_path = project_root / "pyproject.toml"
    data = tomllib.loads(pyproject_path.read_text(encoding="utf-8"))
    return str(data["project"]["version"])


def _write_version_file(project_root: Path, version: str) -> None:
    version_tuple = tuple(int(part) for part in version.split(".")[:3])
    while len(version_tuple) < 4:
        version_tuple += (0,)
    version_file = project_root / "build" / "version_info.txt"
    version_file.parent.mkdir(parents=True, exist_ok=True)
    version_file.write_text(
        "\n".join(
            [
                "VSVersionInfo(",
                f"  ffi=FixedFileInfo(filevers={version_tuple}, prodvers={version_tuple}, mask=0x3f, flags=0x0, OS=0x40004, fileType=0x1, subtype=0x0, date=(0, 0)),",
                "  kids=[",
                "    StringFileInfo([",
                "      StringTable(",
                "        '040904B0',",
                "        [",
                "          StringStruct('CompanyName', 'AntiGravity'),",
                "          StringStruct('FileDescription', 'FlowType desktop dictation app'),",
                "          StringStruct('FileVersion', '" + version + "'),",
                "          StringStruct('InternalName', 'FlowType'),",
                "          StringStruct('OriginalFilename', 'FlowType.exe'),",
                "          StringStruct('ProductName', 'FlowType'),",
                "          StringStruct('ProductVersion', '" + version + "')",
                "        ]",
                "      )",
                "    ]),",
                "    VarFileInfo([VarStruct('Translation', [1033, 1200])])",
                "  ]",
                ")",
            ]
        ),
        encoding="utf-8",
    )


def _validate_dist(project_root: Path, version: str) -> None:
    validator = project_root / "scripts" / "validate_dist.py"
    subprocess.run([os.sys.executable, str(validator), "--version", version], check=True)


def _build_installer(project_root: Path, version: str) -> None:
    iscc = _find_iscc()
    if not iscc:
        raise SystemExit("Inno Setup compiler (iscc) is not installed or not on PATH.")

    subprocess.run(
        [
            iscc,
            f"/DMyAppVersion={version}",
            str(project_root / "scripts" / "installer.iss"),
        ],
        check=True,
    )


def _find_iscc() -> str:
    local_appdata = os.getenv("LOCALAPPDATA", "")
    candidates = [
        shutil.which("iscc"),
        str(Path(local_appdata) / "Programs" / "Inno Setup 6" / "ISCC.exe") if local_appdata else "",
        r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        r"C:\Program Files\Inno Setup 6\ISCC.exe",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return str(candidate)
    return ""


if __name__ == "__main__":
    raise SystemExit(main())
