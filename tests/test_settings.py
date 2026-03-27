from __future__ import annotations

from pathlib import Path

from flowtype.settings import build_settings_command


def test_build_settings_command_uses_module_invocation() -> None:
    command = build_settings_command(Path("C:/Temp/flowtype.toml"))

    assert command[:3] == [command[0], "-m", "flowtype"]
    assert command[-2:] == ["--config", "C:\\Temp\\flowtype.toml"]
