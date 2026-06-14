"""Unit testy runstate.py — RunState mutátory + read pohledy. Obal je MUTABILNÍ nad `st`
dictem (úložiště) → tady ověřujeme sémantiku metod, ne serializaci (tu drží selftest)."""
from runstate import RunState


# ── inicializace / ensure ───────────────────────────────────────────────────────
def test_fresh_result_defaults():
    st = RunState.fresh_result("r1")
    assert st["run"] == "r1" and st["status"] == "in_progress"
    assert st["completed"] == [] and st["outcomes"] == {} and st["graph"] == "delivery"


def test_ensure_result_keys():
    rs = RunState({})
    rs.ensure_result_keys()
    for k in ("completed", "outcomes", "frontier", "skipped", "flags", "findings",
              "return_payload", "model_overrides"):
        assert k in rs.st
    assert rs.st["epoch"] == 0
    assert rs.st["type_versions"] == {} and rs.st["node_versions"] == {}
    assert rs.st["awaiting_human"] == []


def test_ensure_drive_keys():
    rs = RunState({})
    rs.ensure_drive_keys()
    assert rs.st["frontier"] == [] and rs.st["completed"] == []
    assert rs.st["outcomes"] == {} and rs.st["return_payload"] == {} and rs.st["model_overrides"] == {}


def test_coerce_awaiting_human():
    rs = RunState({"awaiting_human": "gate1"})
    rs.coerce_awaiting_human()
    assert rs.st["awaiting_human"] == ["gate1"]            # skalár → list
    rs2 = RunState({"awaiting_human": None})
    rs2.coerce_awaiting_human()
    assert rs2.st["awaiting_human"] == []                  # None → []


# ── completion / verze ──────────────────────────────────────────────────────────
def test_mark_completed_idempotent():
    rs = RunState({"completed": []})
    rs.mark_completed("a")
    rs.mark_completed("a")
    assert rs.completed == ["a"]


def test_set_outcome():
    rs = RunState({"outcomes": {}})
    rs.set_outcome("a", "PASS")
    assert rs.outcomes == {"a": "PASS"}


def test_stamp_monotone_epoch():
    rs = RunState({})
    rs.ensure_result_keys()
    rs.stamp("a", ["code"])
    assert rs.st["epoch"] == 1 and rs.st["node_versions"]["a"] == 1 and rs.st["type_versions"]["code"] == 1
    rs.stamp("b", ["spec"])
    assert rs.st["epoch"] == 2 and rs.st["node_versions"]["b"] == 2   # monotónní napříč uzly


def test_clear_payload():
    rs = RunState({"return_payload": {"a": ["sig"]}})
    rs.clear_payload("a")
    assert "a" not in rs.st["return_payload"]


# ── re-flow (return) ────────────────────────────────────────────────────────────
def test_uncomplete_removes_everywhere():
    rs = RunState({"completed": ["a", "b"], "outcomes": {"a": "PASS", "b": "PASS"},
                   "frontier": ["a"], "awaiting_human": ["a"]})
    rs.uncomplete("a")
    assert "a" not in rs.st["completed"] and "a" not in rs.st["outcomes"]
    assert "a" not in rs.st["frontier"] and "a" not in rs.st["awaiting_human"]
    assert rs.st["completed"] == ["b"]                    # ostatní netknuté


def test_bump_counter():
    rs = RunState({})
    assert rs.bump_counter("qa", "backend") == ("qa->backend", 1)
    assert rs.bump_counter("qa", "backend") == ("qa->backend", 2)


def test_add_payload_dedup():
    rs = RunState({"return_payload": {}})
    rs.add_payload("backend", "sig1")
    rs.add_payload("backend", "sig1")                     # dedup
    rs.add_payload("backend", "sig2")
    assert rs.st["return_payload"]["backend"] == ["sig1", "sig2"]


def test_add_finding():
    rs = RunState({"findings": []})
    rs.add_finding("vitek", "advisory", None, "dup ctor")
    assert rs.st["findings"] == [
        {"node": "vitek", "severity": "advisory", "returns_to": None, "signature": "dup ctor"}]


# ── frontier / gates ────────────────────────────────────────────────────────────
def test_inflight_add_remove_dedup():
    rs = RunState({"frontier": [], "awaiting_human": []})
    rs.add_inflight("a")
    rs.add_inflight("a")                                  # dedup
    assert rs.st["frontier"] == ["a"]
    rs.remove_inflight("a")
    assert rs.st["frontier"] == []


def test_awaiting_add_remove_dedup():
    rs = RunState({"frontier": [], "awaiting_human": []})
    rs.add_awaiting("g")
    rs.add_awaiting("g")
    assert rs.st["awaiting_human"] == ["g"]
    rs.remove_awaiting("g")
    assert rs.st["awaiting_human"] == []


def test_clear_halt_if():
    rs = RunState({"halt_gate": "g"})
    rs.clear_halt_if("other")
    assert rs.st["halt_gate"] == "g"                      # jiný gate → netknuto
    rs.clear_halt_if("g")
    assert rs.st["halt_gate"] is None


# ── envelope merge ──────────────────────────────────────────────────────────────
def test_merge_flags_coerce():
    rs = RunState({"flags": {}})
    rs.merge_flags({"has_db": "true", "design_source": "author"})
    assert rs.st["flags"]["has_db"] is True               # bool-ish → bool
    assert rs.st["flags"]["design_source"] == "author"    # value-flag verbatim


def test_merge_models_lowercased():
    rs = RunState({"model_overrides": {}})
    rs.merge_models({"backend": "HAIKU"})
    assert rs.st["model_overrides"]["backend"] == "haiku"


# ── scalar pole + read ──────────────────────────────────────────────────────────
def test_scalar_properties():
    rs = RunState({})
    rs.status, rs.note, rs.active_node, rs.halt_gate = "blocked", "x", "a", "g"
    assert (rs.status, rs.note, rs.active_node, rs.halt_gate) == ("blocked", "x", "a", "g")


def test_read_roundtrip(tmp_path):
    p = tmp_path / "current-run.md"
    p.write_text("# run\n\n```yaml\nrun: r1\ncompleted:\n- a\nstatus: in_progress\n```\n",
                 encoding="utf-8")
    rs, txt, m = RunState.read(str(p))
    assert rs.st["run"] == "r1" and rs.completed == ["a"] and m is not None


def test_read_missing_file(tmp_path):
    rs, txt, m = RunState.read(str(tmp_path / "nope.md"))
    assert rs.st == {} and txt is None and m is None
