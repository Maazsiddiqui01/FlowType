from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4


@dataclass(slots=True, frozen=True)
class HistoryEntry:
    entry_id: str
    created_at: str
    final_text: str
    raw_text: str
    mode: str
    provider: str
    model: str
    used_fallback: bool
    pasted: bool

    @property
    def word_count(self) -> int:
        return len(self.final_text.split())


class HistoryStore:
    def __init__(self, path: Path, max_items: int) -> None:
        self.path = path
        self.max_items = max_items

    def load(self) -> list[HistoryEntry]:
        if not self.path.exists():
            return []

        payload = json.loads(self.path.read_text(encoding="utf-8"))
        entries = []
        for item in payload:
            if not isinstance(item, dict):
                continue
            entries.append(
                HistoryEntry(
                    entry_id=str(item.get("entry_id", "")).strip() or uuid4().hex,
                    created_at=str(item.get("created_at", "")),
                    final_text=str(item.get("final_text", "")),
                    raw_text=str(item.get("raw_text", "")),
                    mode=str(item.get("mode", "default")),
                    provider=str(item.get("provider", "none")),
                    model=str(item.get("model", "")),
                    used_fallback=bool(item.get("used_fallback", False)),
                    pasted=bool(item.get("pasted", False)),
                )
            )
        return entries[: self.max_items]

    def append(self, entry: HistoryEntry) -> list[HistoryEntry]:
        entries = [entry, *self.load()]
        trimmed = entries[: self.max_items]
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(
            json.dumps([asdict(item) for item in trimmed], indent=2),
            encoding="utf-8",
        )
        return trimmed

    def clear(self) -> None:
        if self.path.exists():
            self.path.unlink()


def build_history_entry(
    final_text: str,
    raw_text: str,
    mode: str,
    provider: str,
    model: str,
    used_fallback: bool,
    pasted: bool,
) -> HistoryEntry:
    return HistoryEntry(
        entry_id=uuid4().hex,
        created_at=datetime.now(timezone.utc).isoformat(timespec="microseconds"),
        final_text=final_text,
        raw_text=raw_text,
        mode=mode,
        provider=provider,
        model=model,
        used_fallback=used_fallback,
        pasted=pasted,
    )
