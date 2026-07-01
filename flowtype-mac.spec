# -*- mode: python ; coding: utf-8 -*-
# macOS build spec. Produces FlowType.app. Run on a macOS runner:
#   pyinstaller --noconfirm flowtype-mac.spec
# See MACOS_PORT_PLAN.md. NOTE: not yet validated on hardware — first green CI run is the check.

from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs, collect_submodules

project_root = Path.cwd()
icon_path = project_root / "build" / "branding" / "app-icon.icns"

hiddenimports = [
    "faster_whisper",
    "ctranslate2",
    # macOS input backends (no `keyboard` lib, no pystray._win32)
    "pynput.keyboard",
    "pynput.keyboard._darwin",
    "pynput.mouse._darwin",
    "pynput._util.darwin",
    # pyobjc frameworks used by flowtype/platform/darwin.py
    "objc",
    "Foundation",
    "AppKit",
    "Quartz",
    "ApplicationServices",
    "CoreFoundation",
    "PIL.Image",
    "PIL.ImageDraw",
    "sounddevice",
    "_sounddevice",
    "_sounddevice_data",
    "pyperclip",
    "keyring",
    "keyring.backends.macOS",
    "certifi",
    "idna",
    "sniffio",
    "h11",
]
hiddenimports += collect_submodules("httpx")
hiddenimports += collect_submodules("httpcore")
hiddenimports += collect_submodules("anyio")
hiddenimports += collect_submodules("ctranslate2")

binaries = []
binaries += collect_dynamic_libs("sounddevice")
# faster-whisper dlopen's ctranslate2's native backend at import time; bundle the dylibs
# (libctranslate2.dylib, libomp/libiomp, etc.) or a clean Mac can't transcribe.
binaries += collect_dynamic_libs("ctranslate2")
binaries += collect_dynamic_libs("faster_whisper")

datas = []
datas += collect_data_files("faster_whisper")
datas += collect_data_files("ctranslate2")
datas += collect_data_files("flowtype", includes=["ui/qml/*.qml", "assets/branding/*", "assets/fonts/*"])
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
        "PySide6.QtPdf",
        "PySide6.QtPdfQuick",
        "PySide6.QtPdfWidgets",
        "PySide6.QtWebChannel",
        "PySide6.QtWebEngineCore",
        "PySide6.QtWebEngineQuick",
        "PySide6.QtWebEngineWidgets",
    ],
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data)

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
app = BUNDLE(
    coll,
    name="FlowType.app",
    icon=str(icon_path) if icon_path.exists() else None,
    bundle_identifier="com.inverisllc.flowtype",
    info_plist={
        "CFBundleName": "FlowType",
        "CFBundleDisplayName": "FlowType",
        "CFBundleShortVersionString": "0.1.13",
        "CFBundleVersion": "0.1.13",
        "LSMinimumSystemVersion": "12.0",
        "NSHighResolutionCapable": True,
        # Dock icon in v1 for easy testing; switch to LSUIElement (menu-bar-only) later.
        "LSUIElement": False,
        "NSMicrophoneUsageDescription": "FlowType records your voice locally to transcribe it into text.",
        "NSInputMonitoringUsageDescription": "FlowType listens for your push-to-talk shortcut to start and stop dictation.",
        "NSAppleEventsUsageDescription": "FlowType pastes cleaned text into the app you were using.",
    },
)
