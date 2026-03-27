from __future__ import annotations

from pathlib import Path

from flowtype.startup import build_launch_command


def test_build_launch_command_uses_module_entrypoint_for_dev_background_launch() -> None:
    command = build_launch_command(Path("C:/Temp/flowtype.toml"), background=True)

    assert command[1:4] == ["-m", "flowtype", "--background"]
    assert command[-2:] == ["--config", "C:\\Temp\\flowtype.toml"]
