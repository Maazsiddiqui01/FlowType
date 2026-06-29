"""Lightweight per-app dictation usage tracking for the 'learn from behavior' feature.

Records how many times the user has dictated into each foreground app so FlowType can
offer to auto-set a per-app Mode once a pattern is clear. Stored as a small JSON in the
app data dir; never raises into callers (best effort).
"""
from __future__ import annotations

import json
import logging
import os
import threading
from pathlib import Path

logger = logging.getLogger("flowtype.usage")

# Offer a per-app Mode suggestion after this many dictations into the same app.
SUGGESTION_THRESHOLD = 4


class UsageStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        # Callers are GUI-thread today, but a lock keeps record/dismiss safe if a future
        # caller runs off-thread, and pairs with an atomic write to avoid torn files.
        self._lock = threading.Lock()
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
            tmp = self.path.with_suffix(self.path.suffix + ".tmp")
            tmp.write_text(json.dumps(self._data, indent=2), encoding="utf-8")
            os.replace(tmp, self.path)  # atomic on the same volume
        except Exception as exc:  # best effort
            logger.warning("Could not persist usage data: %s", exc)

    def record_dictation(self, app: str) -> int:
        """Increment and return the dictation count for an app (case-insensitive)."""
        key = (app or "").strip().lower()
        if not key:
            return 0
        with self._lock:
            counts = self._data.setdefault("counts", {})
            counts[key] = int(counts.get(key, 0)) + 1
            value = counts[key]
            self._save()
        return value

    def count(self, app: str) -> int:
        with self._lock:
            return int(self._data.get("counts", {}).get((app or "").strip().lower(), 0))

    def is_dismissed(self, app: str) -> bool:
        with self._lock:
            return (app or "").strip().lower() in self._data.get("dismissed", [])

    def dismiss(self, app: str) -> None:
        key = (app or "").strip().lower()
        if not key:
            return
        with self._lock:
            dismissed = self._data.setdefault("dismissed", [])
            if key not in dismissed:
                dismissed.append(key)
                self._save()
