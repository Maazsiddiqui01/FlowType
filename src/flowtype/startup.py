from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from flowtype.config import AppConfig

RUN_KEY_PATH = r"Software\Microsoft\Windows\CurrentVersion\Run"
RUN_VALUE_NAME = "FlowType"


def build_launch_command(config_path: Path, *, background: bool = False) -> list[str]:
    config_argument = str(Path(config_path).expanduser().resolve())
    if getattr(sys, "frozen", False):
        command = [sys.executable]
    else:
        command = [_preferred_python_launcher(), "-m", "flowtype"]

    if background:
        command.append("--background")
    command.extend(["--config", config_argument])
    return command


def build_launch_command_line(config_path: Path, *, background: bool = False) -> str:
    return subprocess.list2cmdline(build_launch_command(config_path, background=background))


def sync_launch_at_login(config: AppConfig) -> None:
    if os.name != "nt":
        return

    if not config.startup.prompt_completed or not config.startup.launch_at_login:
        disable_launch_at_login()
        return

    command_line = build_launch_command_line(
        config.config_path,
        background=config.startup.start_minimized,
    )
    enable_launch_at_login(command_line)


def enable_launch_at_login(command_line: str) -> None:
    _write_run_value(command_line)


def disable_launch_at_login() -> None:
    if os.name != "nt":
        return
    import winreg

    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, RUN_KEY_PATH, 0, winreg.KEY_SET_VALUE)
    except FileNotFoundError:
        return
    with key:
        try:
            winreg.DeleteValue(key, RUN_VALUE_NAME)
        except FileNotFoundError:
            return


def launch_at_login_command() -> str:
    if os.name != "nt":
        return ""
    import winreg

    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, RUN_KEY_PATH, 0, winreg.KEY_READ)
    except FileNotFoundError:
        return ""
    with key:
        try:
            value, _ = winreg.QueryValueEx(key, RUN_VALUE_NAME)
        except FileNotFoundError:
            return ""
    return str(value)


def _write_run_value(command_line: str) -> None:
    if os.name != "nt":
        return
    import winreg

    with winreg.CreateKey(winreg.HKEY_CURRENT_USER, RUN_KEY_PATH) as key:
        winreg.SetValueEx(key, RUN_VALUE_NAME, 0, winreg.REG_SZ, command_line)


def _preferred_python_launcher() -> str:
    executable = Path(sys.executable)
    if executable.name.lower() == "python.exe":
        pythonw = executable.with_name("pythonw.exe")
        if pythonw.exists():
            return str(pythonw)
    return str(executable)
