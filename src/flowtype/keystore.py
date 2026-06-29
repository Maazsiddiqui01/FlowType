"""At-rest protection for secrets (API keys) using Windows DPAPI.

Keys were previously stored as plaintext in config.toml (and copied verbatim into the
reset backup). DPAPI (CryptProtectData) encrypts a secret to the current Windows user
account -- the same mechanism Credential Manager uses -- with no extra dependency.

Stored values are tagged with a prefix so we can tell an encrypted token from a legacy
plaintext value (or an env-var key) and migrate transparently. If encryption is
unavailable (non-Windows, or DPAPI fails), values are stored as-is so the app keeps
working; this module never raises into the caller.
"""
from __future__ import annotations

import base64
import ctypes
import logging
import os
from ctypes import wintypes

logger = logging.getLogger("flowtype.keystore")

SECRET_PREFIX = "dpapi:"


class _DataBlob(ctypes.Structure):
    _fields_ = [("cbData", wintypes.DWORD), ("pbData", ctypes.POINTER(ctypes.c_char))]


def _blob(data: bytes) -> _DataBlob:
    buffer = ctypes.create_string_buffer(data, len(data))
    return _DataBlob(len(data), ctypes.cast(buffer, ctypes.POINTER(ctypes.c_char)))


def _blob_to_bytes(blob: _DataBlob) -> bytes:
    return ctypes.string_at(blob.pbData, blob.cbData)


def is_protected(value: str) -> bool:
    return isinstance(value, str) and value.startswith(SECRET_PREFIX)


def protect(value: str) -> str:
    """Encrypt a secret for storage. Idempotent (already-protected values pass through).

    Returns the value unchanged if empty, already protected, or if DPAPI is unavailable.
    """
    if not value or is_protected(value):
        return value
    if os.name != "nt":
        return value
    try:
        crypt32 = ctypes.windll.crypt32
        kernel32 = ctypes.windll.kernel32
        in_blob = _blob(value.encode("utf-8"))
        out_blob = _DataBlob()
        if not crypt32.CryptProtectData(
            ctypes.byref(in_blob), None, None, None, None, 0, ctypes.byref(out_blob)
        ):
            return value
        try:
            token = base64.b64encode(_blob_to_bytes(out_blob)).decode("ascii")
        finally:
            kernel32.LocalFree(out_blob.pbData)
        return SECRET_PREFIX + token
    except Exception as exc:  # pragma: no cover - host crypto dependent
        logger.warning("Could not encrypt secret at rest: %s", exc)
        return value


def unprotect(value: str) -> str:
    """Decrypt a stored secret. Plaintext/env values (no prefix) pass through."""
    if not value or not is_protected(value):
        return value
    if os.name != "nt":
        # A protected token but no DPAPI to decrypt it: never hand back the raw
        # ciphertext as if it were the key. Callers fall back to env vars.
        return ""
    encoded = value[len(SECRET_PREFIX):]
    try:
        raw = base64.b64decode(encoded.encode("ascii"))
        crypt32 = ctypes.windll.crypt32
        kernel32 = ctypes.windll.kernel32
        in_blob = _blob(raw)
        out_blob = _DataBlob()
        if not crypt32.CryptUnprotectData(
            ctypes.byref(in_blob), None, None, None, None, 0, ctypes.byref(out_blob)
        ):
            return ""
        try:
            return _blob_to_bytes(out_blob).decode("utf-8")
        finally:
            kernel32.LocalFree(out_blob.pbData)
    except Exception as exc:  # pragma: no cover - host crypto dependent
        logger.warning("Could not decrypt stored secret: %s", exc)
        return ""
