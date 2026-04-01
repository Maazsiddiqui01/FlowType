# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs, collect_submodules


block_cipher = None
project_root = Path.cwd()
branding_dir = project_root / "build" / "branding"
icon_path = branding_dir / "app-icon.ico"
version_path = project_root / "build" / "version_info.txt"

hiddenimports = [
    "faster_whisper",
    "pynput.keyboard",
    "pynput.mouse",
    "pynput.keyboard._win32",
    "pynput.mouse._win32",
    "pynput._util.win32",
    "pystray",
    "pystray._win32",
    "PIL.Image",
    "PIL.ImageDraw",
    "sounddevice",
    "_sounddevice",
    "_sounddevice_data",
    "pyperclip",
    "certifi",
    "idna",
    "sniffio",
    "h11",
]
hiddenimports += collect_submodules("httpx")
hiddenimports += collect_submodules("httpcore")
hiddenimports += collect_submodules("anyio")

binaries = []
binaries += collect_dynamic_libs("sounddevice")

datas = []
datas += collect_data_files("faster_whisper")
datas += collect_data_files("flowtype", includes=["ui/qml/*.qml", "assets/branding/*", "assets/fonts/*"])
datas += collect_data_files("pystray")
datas += collect_data_files("_sounddevice_data")
datas += collect_data_files("certifi")


a = Analysis(
    ["src/flowtype/__main__.py"],
    pathex=["src"],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "pytest",
        "tests",
        "torch",
        "torchaudio",
        "torchvision",
        "transformers",
        "pandas",
        "scipy",
        "fastapi",
        "openai",
        "notebooklm_mcp",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="FlowType",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    icon=str(icon_path) if icon_path.exists() else None,
    version=str(version_path) if version_path.exists() else None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="FlowType",
)
