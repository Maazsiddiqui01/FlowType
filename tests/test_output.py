from __future__ import annotations

import logging

from flowtype.config import OutputConfig
from flowtype.output import OutputDelivery
from flowtype.windows import ForegroundWindowSnapshot


class FakePyperclip:
    def __init__(self) -> None:
        self.value = ""

    def copy(self, text: str) -> None:
        self.value = text

    def paste(self) -> str:
        return self.value


def test_deliver_clipboard_only(monkeypatch) -> None:
    output = OutputDelivery(
        OutputConfig(
            paste_method="clipboard_only",
            paste_delay_ms=0,
            restore_clipboard=False,
        ),
        logger=logging.getLogger("test.output"),
    )
    fake_pyperclip = FakePyperclip()
    monkeypatch.setattr(output, "_load_pyperclip", lambda: fake_pyperclip)
    monkeypatch.setattr("flowtype.output.time.sleep", lambda *_args, **_kwargs: None)

    result = output.deliver("Hello world")

    assert fake_pyperclip.value == "Hello world"
    assert result.copied is True
    assert result.pasted is False
    assert result.delivery_state == "copied_only"


def test_deliver_ctrl_v_reports_paste(monkeypatch) -> None:
    output = OutputDelivery(
        OutputConfig(
            paste_method="ctrl_v",
            paste_delay_ms=0,
            restore_clipboard=False,
        ),
        logger=logging.getLogger("test.output"),
    )
    fake_pyperclip = FakePyperclip()
    sleep_calls = []
    monkeypatch.setattr(output, "_load_pyperclip", lambda: fake_pyperclip)
    monkeypatch.setattr("flowtype.output.time.sleep", lambda value: sleep_calls.append(value))
    monkeypatch.setattr(output, "_paste_via_keyboard", lambda: True)

    result = output.deliver("Dictated text")

    assert fake_pyperclip.value == "Dictated text"
    assert result.copied is True
    assert result.pasted is True
    assert result.delivery_state == "pasted"
    assert sleep_calls[0] >= 0.18


def test_deliver_falls_back_to_clipboard_when_target_restore_fails(monkeypatch) -> None:
    output = OutputDelivery(
        OutputConfig(
            paste_method="ctrl_v",
            paste_delay_ms=0,
            restore_clipboard=False,
        ),
        logger=logging.getLogger("test.output"),
    )
    fake_pyperclip = FakePyperclip()
    monkeypatch.setattr(output, "_load_pyperclip", lambda: fake_pyperclip)
    monkeypatch.setattr("flowtype.output.time.sleep", lambda *_args, **_kwargs: None)
    monkeypatch.setattr(output, "_restore_target", lambda _target: False)

    result = output.deliver("Dictated text", target=ForegroundWindowSnapshot(hwnd=123, title="Notepad"))

    assert fake_pyperclip.value == "Dictated text"
    assert result.copied is True
    assert result.pasted is False
    assert result.target_restored is False
    assert result.target_title == "Notepad"
    assert result.delivery_state == "copied_only"
    assert "clipboard" in result.failure_reason.lower()
