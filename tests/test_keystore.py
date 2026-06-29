from __future__ import annotations

import os

import pytest

from flowtype import keystore


def test_protect_passes_through_empty_and_already_protected() -> None:
    assert keystore.protect("") == ""
    token = keystore.SECRET_PREFIX + "abc"
    assert keystore.protect(token) == token


def test_unprotect_passes_through_plaintext() -> None:
    assert keystore.unprotect("plain-value") == "plain-value"
    assert keystore.unprotect("") == ""


@pytest.mark.skipif(os.name != "nt", reason="DPAPI is Windows-only")
def test_protect_unprotect_round_trips_on_windows() -> None:
    secret = "sk-test-1234567890"
    token = keystore.protect(secret)
    assert token.startswith(keystore.SECRET_PREFIX)
    assert secret not in token  # ciphertext, not plaintext
    assert keystore.unprotect(token) == secret
