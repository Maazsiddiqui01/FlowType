from __future__ import annotations

import importlib
import logging
import time
from dataclasses import dataclass
from typing import Any

from flowtype.config import CleanupConfig


@dataclass(slots=True, frozen=True)
class CleanupResult:
    text: str
    used_fallback: bool
    attempts: int
    provider: str


class TextCleaner:
    def __init__(self, settings: CleanupConfig, logger: logging.Logger | None = None) -> None:
        self.settings = settings
        self.logger = logger or logging.getLogger("flowtype.cleanup")

    def clean(self, raw_text: str) -> CleanupResult:
        stripped = raw_text.strip()
        if not stripped:
            return CleanupResult("", False, 0, self.settings.provider)

        if self.settings.provider == "none":
            return CleanupResult(stripped, False, 0, self.settings.provider)

        if len(stripped.split()) < self.settings.min_word_count:
            return CleanupResult(stripped, False, 0, self.settings.provider)

        if self.settings.provider != "ollama" and not self.settings.api_key:
            self.logger.warning("Cleanup skipped because no API key is configured")
            return CleanupResult(stripped, True, 0, self.settings.provider)

        httpx = self._load_httpx()
        url = self._endpoint_for_provider()
        headers = self._headers_for_provider()
        payload = self._build_payload(stripped)

        attempts = 0
        with httpx.Client(timeout=self.settings.timeout_seconds) as client:
            for attempt in range(1, self.settings.max_retries + 1):
                attempts = attempt
                try:
                    response = client.post(url, headers=headers, json=payload)
                    response.raise_for_status()
                    text = self._extract_text(self.settings.provider, response.json())
                    if text:
                        return CleanupResult(
                            text=text,
                            used_fallback=False,
                            attempts=attempt,
                            provider=self.settings.provider,
                        )
                    raise ValueError("cleanup response did not include text")
                except Exception as exc:
                    should_retry = self._should_retry(exc)
                    self.logger.warning(
                        "Cleanup attempt %s/%s failed: %s",
                        attempt,
                        self.settings.max_retries,
                        exc,
                    )
                    if attempt >= self.settings.max_retries or not should_retry:
                        break
                    delay = self.settings.retry_backoff_seconds * (2 ** (attempt - 1))
                    time.sleep(delay)

        self.logger.warning("Cleanup failed after %s attempts, using raw transcript", attempts)
        return CleanupResult(text=stripped, used_fallback=True, attempts=attempts, provider=self.settings.provider)

    def _load_httpx(self):
        try:
            return importlib.import_module("httpx")
        except ModuleNotFoundError as exc:  # pragma: no cover - dependency issue
            raise RuntimeError("httpx is not installed. Run `python -m pip install -e .` first.") from exc

    def _endpoint_for_provider(self) -> str:
        if self.settings.provider == "openrouter":
            return "https://openrouter.ai/api/v1/chat/completions"
        if self.settings.provider == "openai":
            return "https://api.openai.com/v1/chat/completions"
        if self.settings.provider == "gemini":
            return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        if self.settings.provider == "xai":
            return "https://api.x.ai/v1/chat/completions"
        if self.settings.provider == "groq":
            return "https://api.groq.com/openai/v1/chat/completions"
        if self.settings.provider == "anthropic":
            return "https://api.anthropic.com/v1/messages"
        if self.settings.provider == "ollama":
            # Assuming standard local Ollama OpenAI-compatible endpoint
            return "http://localhost:11434/v1/chat/completions"

        raise ValueError(f"unsupported cleanup provider: {self.settings.provider}")

    def _headers_for_provider(self) -> dict[str, str]:
        if self.settings.provider == "anthropic":
            return {
                "x-api-key": self.settings.api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            }
            
        headers = {"Content-Type": "application/json"}
        if self.settings.provider != "ollama":
            headers["Authorization"] = f"Bearer {self.settings.api_key}"
        if self.settings.provider == "openrouter":
            headers["HTTP-Referer"] = "https://github.com/AntiGravity/FlowType"
            headers["X-Title"] = "FlowType"
        if self.settings.provider == "gemini":
            headers["x-goog-api-client"] = "flowtype/1.0"

        return headers

    def _build_payload(self, text: str) -> dict[str, Any]:
        system_prompt = self._compose_prompt()
        if self.settings.provider == "anthropic":
            return {
                "model": self.settings.model,
                "max_tokens": self.settings.max_tokens or 1024,
                "temperature": self.settings.temperature,
                "system": system_prompt,
                "messages": [
                    {"role": "user", "content": text}
                ]
            }
            
        # Standard OpenAI-compatible format for OpenRouter, OpenAI, Gemini, xAI, Groq, and Ollama
        payload = {
            "model": self.settings.model,
            "max_tokens": self.settings.max_tokens,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": text},
            ],
        }
        if self._supports_temperature():
            payload["temperature"] = self.settings.temperature
        return payload

    def _compose_prompt(self) -> str:
        sections = [self.settings.prompt.strip()]
        sections.append(
            "Hard constraints:\n"
            "- Preserve meaning, tone, and factual content exactly.\n"
            "- Do not summarize, shorten, or deduplicate repeated phrases or sentences.\n"
            "- If the speaker intentionally repeats a sentence, keep the repetition.\n"
            "- You may correct obvious speech-recognition mistakes or homophone errors only when the intended wording is clear from surrounding context.\n"
            "- If a word is uncertain and context does not make the intended wording clear, keep the raw wording instead of guessing.\n"
            "- Only remove filler words when they are verbal fillers rather than meaningful content."
        )

        if self.settings.mode_prompt.strip():
            sections.append(f"Mode guidance:\n{self.settings.mode_prompt.strip()}")

        if self.settings.vocabulary_entries:
            entries = "\n".join(f"- {entry}" for entry in self.settings.vocabulary_entries)
            sections.append(
                "Vocabulary and phrase guidance:\n"
                "Preserve these words, names, brands, or preferred replacements when they appear intentionally.\n"
                f"{entries}"
            )

        return "\n\n".join(section for section in sections if section)

    def _extract_text(self, provider: str, payload: dict[str, Any]) -> str:
        if provider == "anthropic":
            content = payload.get("content", [])
            if content and isinstance(content, list):
                return str(content[0].get("text", "")).strip()
            return ""
            
        # Standard OpenAI extraction
        choices = payload.get("choices") or []
        if not choices:
            return ""

        message = choices[0].get("message") or {}
        content = message.get("content", "")
        if isinstance(content, str):
            return content.strip()
        if isinstance(content, list):
            chunks = []
            for item in content:
                if isinstance(item, dict) and item.get("type") == "text":
                    chunks.append(str(item.get("text", "")))
            return "".join(chunks).strip()
        return ""

    def _should_retry(self, exc: Exception) -> bool:
        response = getattr(exc, "response", None)
        status_code = getattr(response, "status_code", None)
        if status_code is None:
            return True
        return status_code >= 500 or status_code == 429

    def _supports_temperature(self) -> bool:
        model = self.settings.model.strip().lower()
        if model.startswith("gpt-5"):
            return False
        return True
