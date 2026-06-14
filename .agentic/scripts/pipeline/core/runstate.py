#!/usr/bin/env python3
"""runstate.py — RunState: doménový obal nad stavem běhu (current-run.md ```yaml blok).

Mechanické mutace stavu (completed/outcomes/frontier/skipped/findings/return_payload/
counters/verze), které dřív ležely rozhozené v result.py a run.py jako přímé sahání do
dictu, jsou tu metody. Obal je MUTABILNÍ a drží syrový `st` dict jako úložiště → serializace
zpět (common.dump_block/write_state) je bajt-identická (žádné přeskládání klíčů).

Čtenáři (Frontier) berou read-only pohledy; zapisovatelé (result/drive) volají mutátory.
"""
import os
import sys
from typing import TYPE_CHECKING, Any

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import coerce_flag, read_state

if TYPE_CHECKING:
    import re


class RunState:
    def __init__(self, st: dict | None) -> None:
        self.st: dict = st if st is not None else {}

    @classmethod
    def read(cls, run_file: str) -> "tuple[RunState, str | None, re.Match | None]":
        """(RunState, txt, match) — zachová okolní text pro in-place zápis (jako read_state)."""
        st, txt, m = read_state(run_file)
        return cls(st), txt, m

    @staticmethod
    def fresh_result(run: str) -> dict:
        """Default stav, když current-run.md neexistuje (pořadí klíčů = původní literal)."""
        return {"run": run, "graph": "delivery", "status": "in_progress", "active_node": None,
                "frontier": [], "completed": [], "outcomes": {}, "skipped": [], "counters": {},
                "awaiting_human": [], "halt_gate": None, "last_outcome": None, "class": None,
                "flags": {}, "note": None}

    # ── inicializace klíčů (pořadí = původní setdefault sekvence; serializace 1:1) ──
    def ensure_result_keys(self) -> None:
        for k, default in (("completed", list), ("outcomes", dict), ("frontier", list),
                           ("skipped", list), ("flags", dict), ("findings", list),
                           ("return_payload", dict), ("model_overrides", dict)):
            self.st.setdefault(k, default())
        self.st.setdefault("epoch", 0)
        self.st.setdefault("type_versions", {})
        self.st.setdefault("node_versions", {})
        self.coerce_awaiting_human()

    def ensure_drive_keys(self) -> None:
        for k in ("frontier", "completed", "outcomes", "return_payload", "model_overrides"):
            self.st.setdefault(k, [] if k in ("frontier", "completed") else {})
        self.coerce_awaiting_human()

    def coerce_awaiting_human(self) -> None:
        aw = self.st.get("awaiting_human")
        if isinstance(aw, list):
            return
        self.st["awaiting_human"] = [aw] if aw else []

    # ── read pohledy (Frontier) ──────────────────────────────────────────────────
    def get(self, key: str, default: Any = None) -> Any:
        return self.st.get(key, default)

    @property
    def completed(self) -> list:
        return self.st.get("completed") or []

    @property
    def inflight(self) -> list:
        return self.st.get("frontier") or []

    @property
    def outcomes(self) -> dict:
        return self.st.get("outcomes") or {}

    @property
    def skipped(self) -> list:
        return self.st.get("skipped") or []

    @property
    def type_versions(self) -> dict:
        return self.st.get("type_versions") or {}

    @property
    def node_versions(self) -> dict:
        return self.st.get("node_versions") or {}

    # ── scalar pole ──────────────────────────────────────────────────────────────
    @property
    def status(self) -> str | None:
        return self.st.get("status")

    @status.setter
    def status(self, v: str | None) -> None:
        self.st["status"] = v

    @property
    def note(self) -> str | None:
        return self.st.get("note")

    @note.setter
    def note(self, v: str | None) -> None:
        self.st["note"] = v

    @property
    def active_node(self) -> str | None:
        return self.st.get("active_node")

    @active_node.setter
    def active_node(self, v: str | None) -> None:
        self.st["active_node"] = v

    @property
    def halt_gate(self) -> str | None:
        return self.st.get("halt_gate")

    @halt_gate.setter
    def halt_gate(self, v: str | None) -> None:
        self.st["halt_gate"] = v

    # ── mutace: completion / verze ───────────────────────────────────────────────
    def mark_completed(self, nid: str) -> None:
        if nid not in self.st["completed"]:
            self.st["completed"].append(nid)

    def set_outcome(self, nid: str, outcome: str) -> None:
        self.st["outcomes"][nid] = outcome

    def stamp(self, nid: str, changed: list[str]) -> None:
        """Incremental rebuild: completion stampuje epoch + node/type verze (monotónně)."""
        self.st["epoch"] = int(self.st.get("epoch", 0)) + 1
        self.st["node_versions"][nid] = self.st["epoch"]
        for T in changed:
            self.st["type_versions"][T] = self.st["epoch"]

    def clear_payload(self, nid: str) -> None:
        self.st["return_payload"].pop(nid, None)

    # ── mutace: re-flow (return) ─────────────────────────────────────────────────
    def uncomplete(self, target: str) -> None:
        """Un-completne return cíl (downstream se přepočítá lazily přes staleness)."""
        if target in self.st["completed"]:
            self.st["completed"].remove(target)
        self.st["outcomes"].pop(target, None)
        if target in self.st["frontier"]:
            self.st["frontier"].remove(target)
        aw = self.st["awaiting_human"]
        if target in aw:
            aw.remove(target)

    def bump_counter(self, node: str, target: str) -> tuple[str, int]:
        """Inkrementuj return counter node->target; vrať (key, count)."""
        counters = self.st.get("counters") or {}
        key = f"{node}->{target}"
        counters[key] = int(counters.get(key, 0)) + 1
        self.st["counters"] = counters
        return key, counters[key]

    def add_payload(self, target: str, signature: str) -> None:
        rp = self.st["return_payload"]
        rp.setdefault(target, [])
        if signature not in rp[target]:
            rp[target].append(signature)

    def add_finding(self, node: str, severity: str, returns_to: str | None, signature: str) -> None:
        self.st["findings"].append({"node": node, "severity": severity,
                                    "returns_to": returns_to, "signature": signature})

    # ── mutace: frontier / gates ─────────────────────────────────────────────────
    def add_inflight(self, nid: str) -> None:
        if nid not in self.st["frontier"]:
            self.st["frontier"].append(nid)

    def remove_inflight(self, nid: str) -> None:
        if nid in self.st["frontier"]:
            self.st["frontier"].remove(nid)

    def add_awaiting(self, nid: str) -> None:
        if nid not in self.st["awaiting_human"]:
            self.st["awaiting_human"].append(nid)

    def remove_awaiting(self, nid: str) -> None:
        if nid in self.st["awaiting_human"]:
            self.st["awaiting_human"].remove(nid)

    def clear_halt_if(self, nid: str) -> None:
        if self.st.get("halt_gate") == nid:
            self.st["halt_gate"] = None

    # ── mutace: envelope merge ───────────────────────────────────────────────────
    def merge_flags(self, flags: dict) -> None:
        for k, v in (flags or {}).items():
            self.st["flags"][k] = coerce_flag(v)

    def merge_models(self, models: dict) -> None:
        for k, v in (models or {}).items():
            self.st["model_overrides"][k] = str(v).strip().lower()
