"""Lightweight per-app dictation usage tracking for the 'learn from behavior' feature.

Records how many times the user has dictated into each foreground app so FlowType can
offer to auto-set a per-app Mode once a pattern is clear. Stored as a small JSON in the
app data dir; never raises into callers (best effort).
"""
from __future__ import annotations

import json
import logging
from pathlib import Path

logger = logging.getLogger("flowtype.usage")

# Offer a per-app Mode suggestion after this many dictations into the same app.
SUGGESTION_THRESHOLD = 4


class UsageStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self._data = self._load()

    def _load(self) -> dict:
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                data.setdefault("counts", {})
                data.setdefault("dismissed", [])
                return data
        except Exception:
            pass
        return {"counts": {}, "dismissed": []}

    def _save(self) -> None:
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self.path.write_text(json.dumps(self._data, indent=2), encoding="utf-8")
        except Exception as exc:  # best effort
            logger.warning("Could not persist usage data: %s", exc)

    def record_dictation(self, app: str) -> int:
        """Increment and return the dictation count for an app (case-insensitive)."""
        key = (app or "").strip().lower()
        if not key:
            return 0
        counts = self._data.setdefault("counts", {})
        counts[key] = int(counts.get(key, 0)) + 1
        self._save()
        return counts[key]

    def count(self, app: str) -> int:
        return int(self._data.get("counts", {}).get((app or "").strip().lower(), 0))

    def is_dismissed(self, app: str) -> bool:
        return (app or "").strip().lower() in self._data.get("dismissed", [])

    def dismiss(self, app: str) -> None:
        key = (app or "").strip().lower()
        if not key:
            return
        dismissed = self._data.setdefault("dismissed", [])
        if key not in dismissed:
            dismissed.append(key)
            self._save()
