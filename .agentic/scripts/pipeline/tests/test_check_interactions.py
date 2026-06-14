"""Unit testy check.py C10 produces-validace (P5 human-interaction registry).

Ověřuje typované I/O interakcí: každá `produces` = { artifact: ∈artifacts } | { outcome: ∈vocab }.
delegate-or-provide je platný kind."""
from check import INTERACTION_KINDS, _check_produces

ARTIFACTS = {"mockup": {}, "spec": {}}


def test_delegate_or_provide_is_valid_kind():
    assert "delegate-or-provide" in INTERACTION_KINDS


def test_produces_artifact_ok():
    assert _check_produces("i", {"produces": {"artifact": "mockup"}}, ARTIFACTS) == []


def test_produces_artifact_unknown():
    assert _check_produces("i", {"produces": {"artifact": "ghost"}}, ARTIFACTS) == \
        ["C10 interakce 'i': produces.artifact 'ghost' není v artifacts.yaml"]


def test_produces_outcome_ok():
    assert _check_produces("i", {"produces": {"outcome": "ACK"}}, ARTIFACTS) == []


def test_produces_outcome_unknown():
    out = _check_produces("i", {"produces": {"outcome": "BOGUS"}}, ARTIFACTS)
    assert out and "produces.outcome 'BOGUS'" in out[0]


def test_produces_missing():
    assert _check_produces("i", {}, ARTIFACTS) == \
        ["C10 interakce 'i': chybí typovaný 'produces' (artifact|outcome)"]


def test_produces_neither_artifact_nor_outcome():
    out = _check_produces("i", {"produces": {"foo": "bar"}}, ARTIFACTS)
    assert out and "musí mít 'artifact' nebo 'outcome'" in out[0]


def test_produces_artifact_skip_when_no_registry():
    # artifacts=None (SKIP režim) → artifact se neověřuje
    assert _check_produces("i", {"produces": {"artifact": "anything"}}, None) == []
