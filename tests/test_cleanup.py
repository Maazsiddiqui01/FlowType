from __future__ import annotations

import logging
from dataclasses import replace

from flowtype.cleanup import TextCleaner
from flowtype.config import CleanupConfig


class FakeResponse:
    def __init__(self, payload, status_code: int = 200) -> None:
        self._payload = payload
        self.status_code = status_code

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            error = RuntimeError(f"HTTP {self.status_code}")
            error.response = self
            raise error

    def json(self):
        return self._payload


class FakeClient:
    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = 0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def post(self, url, headers, json):
        del url, headers, json
        response = self.responses[self.calls]
        self.calls += 1
        if isinstance(response, Exception):
            raise response
        return response


class FakeHttpxModule:
    def __init__(self, responses):
        self._responses = responses
        self.client = None
        self.timeout = None

    def Client(self, timeout):
        self.timeout = timeout
        self.client = FakeClient(self._responses)
        return self.client


def build_settings() -> CleanupConfig:
    return CleanupConfig(
        provider="openrouter",
        api_key="test-key",
        model="demo-model",
        prompt="Clean the text",
        temperature=0.1,
        max_tokens=128,
        timeout_seconds=5,
        max_retries=3,
        retry_backoff_seconds=0.0,
        min_word_count=3,
    )


def test_clean_returns_model_output(monkeypatch) -> None:
    module = FakeHttpxModule(
        [
            FakeResponse(
                {
                    "choices": [
                        {"message": {"content": "This is cleaned text."}},
                    ]
                }
            )
        ]
    )
    cleaner = TextCleaner(build_settings(), logger=logging.getLogger("test.cleanup"))
    monkeypatch.setattr(cleaner, "_load_httpx", lambda: module)

    result = cleaner.clean("um this is cleaned text")

    assert result.text == "This is cleaned text."
    assert result.used_fallback is False
    assert result.attempts == 1


def test_clean_falls_back_after_failures(monkeypatch) -> None:
    module = FakeHttpxModule([RuntimeError("boom"), RuntimeError("boom"), RuntimeError("boom")])
    cleaner = TextCleaner(build_settings(), logger=logging.getLogger("test.cleanup"))
    monkeypatch.setattr(cleaner, "_load_httpx", lambda: module)

    result = cleaner.clean("This should fall back to raw text")

    assert result.text == "This should fall back to raw text"
    assert result.used_fallback is True
    assert result.attempts == 1


def test_clean_skips_short_inputs() -> None:
    cleaner = TextCleaner(build_settings(), logger=logging.getLogger("test.cleanup"))

    result = cleaner.clean("Thanks")

    assert result.text == "Thanks"
    assert result.used_fallback is False
    assert result.attempts == 0


def test_build_payload_adds_hard_constraints() -> None:
    cleaner = TextCleaner(build_settings(), logger=logging.getLogger("test.cleanup"))

    payload = cleaner._build_payload("repeat repeat repeat")

    system_message = payload["messages"][0]["content"]
    assert "Do not summarize, shorten, or deduplicate repeated phrases or sentences." in system_message


def test_cleanup_supports_gemini_endpoint_and_headers() -> None:
    cleaner = TextCleaner(
        replace(build_settings(), provider="gemini", model="gemini-2.5-flash"),
        logger=logging.getLogger("test.cleanup"),
    )

    assert cleaner._endpoint_for_provider() == "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
    headers = cleaner._headers_for_provider()
    assert headers["Authorization"] == "Bearer test-key"
    assert headers["x-goog-api-client"] == "flowtype/1.0"


def test_cleanup_supports_xai_endpoint() -> None:
    cleaner = TextCleaner(
        replace(build_settings(), provider="xai", model="grok-3-fast"),
        logger=logging.getLogger("test.cleanup"),
    )

    assert cleaner._endpoint_for_provider() == "https://api.x.ai/v1/chat/completions"


def test_cleanup_omits_temperature_for_gpt5_models() -> None:
    cleaner = TextCleaner(
        replace(build_settings(), provider="openai", model="gpt-5-mini"),
        logger=logging.getLogger("test.cleanup"),
    )

    payload = cleaner._build_payload("test")

    assert "temperature" not in payload


def test_cleanup_falls_back_when_httpx_runtime_is_missing(monkeypatch) -> None:
    cleaner = TextCleaner(build_settings(), logger=logging.getLogger("test.cleanup"))
    monkeypatch.setattr(cleaner, "_load_httpx", lambda: (_ for _ in ()).throw(RuntimeError("missing httpx")))

    result = cleaner.clean("This should still be returned")

    assert result.text == "This should still be returned"
    assert result.used_fallback is True
    assert result.attempts == 0


def test_cleanup_caps_cloud_timeout_and_retries(monkeypatch) -> None:
    settings = replace(build_settings(), timeout_seconds=20, max_retries=3, model="openrouter/free")
    module = FakeHttpxModule([RuntimeError("boom")])
    cleaner = TextCleaner(settings, logger=logging.getLogger("test.cleanup"))
    monkeypatch.setattr(cleaner, "_load_httpx", lambda: module)

    result = cleaner.clean("This should fall back quickly")

    assert module.client is not None
    assert module.timeout == 8
    assert module.client.calls == 1
    assert result.used_fallback is True
