#!/usr/bin/env python3
"""run.py — jednotný vstup do pipeline runneru (deterministický executor) (z run.sh).

Sjednocuje start/active/skip/status/next/drive/done/summary/check/scaffold. „Runner"
executor z VISION §Most (LLM orchestrátor / runner / app = vyměnitelné executory nad
stejným grafem+stavem). `drive` importuje frontier přímo (konec subprocess+JSON).

CLI: python3 run.py <subcommand> [args]
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
import frontier
from common import find_graph, load_graph, read_state, write_state
from graph import Graph
from runstate import RunState

HERE = os.path.dirname(os.path.abspath(__file__))
PARENT = os.path.dirname(HERE)  # scripts/pipeline/ (kde leží .sh shimy)

USAGE = """run.py — jednotný vstup do pipeline runneru.

Subcommands:
  start <run-id>      seedne current-run.md (frontier model)
  active <node>       nastaví active_node (ruční override)
  skip <node>         judged-skip: frontier přestane uzel počítat jako producenta
  status [run-file]   kde běh stojí
  next [args]         další uzel(y) (--emit frontier / --from …)
  drive               frontier executor: READY množina jako akce
  done <envelope>     /done: zaznamenej výstup uzlu, posuň stav
  summary [run-id]    cost + čas per issue
  check               integrita grafu C1–C13
  scaffold [args]     resolve scaffoldu
"""


# ── mutace current-run.md (start/active/skip) ─────────────────────────────────
def mutate_state(mode: str, val: str) -> None:
    graph_file = find_graph()
    entry = "intake"
    if graph_file and os.path.isfile(graph_file):
        entry = (load_graph(graph_file).get("meta", {}) or {}).get("entry", "intake")
    rf = "current-run.md"
    st = read_state(rf)[0]
    if mode == "start":
        st = {"run": val, "graph": "delivery", "status": "in_progress", "active_node": entry,
              "frontier": [], "completed": [], "outcomes": {}, "skipped": [],
              "counters": st.get("counters", {}) if st else {}, "awaiting_human": [],
              "halt_gate": None, "last_outcome": None, "class": None, "flags": {}, "note": None}
    elif mode == "active":
        st["active_node"] = val
        st.setdefault("status", "in_progress")
    elif mode == "skip":
        sk = st.get("skipped") or []
        if val not in sk:
            sk.append(val)
        st["skipped"] = sk
        fr = st.get("frontier") or []   # judged-skip uzel nesmí zůstat inflight (jinak běh visí)
        if val in fr:
            fr.remove(val)
        st["frontier"] = fr
        st.setdefault("status", "in_progress")
    write_state(rf, st)
    print(f"current-run.md: {mode} → run={st.get('run')} active_node={st.get('active_node')}")


# ── drive — frontier executor ─────────────────────────────────────────────────
def partition_ready(ready: list, graph: Graph) -> dict[str, list]:
    """Roztřiď ready uzly dle node.drive_category (polymorfně) místo string-žebříku nad `type`.
    Pořadí v každém kbelíku = pořadí v ready (faithful k dřívějšímu `by(type)` filtru)."""
    cats: dict[str, list] = {"JOIN": [], "TERMINAL": [], "BLOCKING_GATE": [],
                             "FREE_GATE": [], "WORKER": [], "ROUTER": []}
    for r in ready:
        nd = graph.get(r["node"])
        cat = nd.drive_category(r.get("blocking")) if nd else None
        if cat in cats:
            cats[cat].append(r)
    return cats


def print_dispatch(workers: list, g_free: list, state: RunState) -> None:
    """Vytiskni FRONTIER dispatch řádky (workery s modelem + re-flow payloadem, free human-gaty).
    Hlášky MUSÍ zůstat bajt-identické — selftest je parsuje (DISPATCH/HUMAN-GATE/re-flow)."""
    print(f"FRONTIER ({len(workers) + len(g_free)} ready, {len(state.inflight)} inflight):")
    rp = state.get("return_payload") or {}
    mov = state.get("model_overrides") or {}
    for w in workers:
        gm = w.get("model", "-")
        om = mov.get(w["node"])
        model = f"{om}*" if om else gm
        print(f"  DISPATCH {w['node']:18} agent:{w.get('agent', '-'):16} model:{model}")
        for sig in rp.get(w["node"], []):
            print(f"      ↻ re-flow finding: {sig}")
    for g in g_free:
        print(f"  HUMAN-GATE {g['node']:16} level:{g.get('level') or '-'} blocking:false "
              f"interaction:{g.get('interaction') or '-'}")
    print("→ workery dispatchni paralelně; gaty po lidském vstupu. "
          "Po každém: run.py done <envelope>. Pak run.py drive.")


def drive() -> None:
    rf = "current-run.md"
    if not os.path.isfile(rf):
        print("DRIVE: current-run.md chybí — nejdřív `run.py start <run-id>`.", file=sys.stderr)
        sys.exit(2)
    state = RunState(read_state(rf)[0])
    state.ensure_drive_keys()
    graph = Graph.load(common.require_graph())

    def write() -> None:
        write_state(rf, state.st)

    if state.status == "done":
        print("DONE: běh uzavřen.")
        sys.exit(0)
    if state.status == "blocked":
        note = state.note or "běh blokován (REJECTED / 3× counter / BLOCKER)"
        print(f"BLOCKED: {note}. Orchestrátor musí zasáhnout — po vyřešení uprav stav a spusť run.py drive.")
        sys.exit(1)
    if state.halt_gate:
        gate = state.halt_gate
        print(f"HALT (blocking gate): {gate} — destruktivní krok, čeká na explicitní ano/ne. "
              f"Po lidském vstupu: run.py done <envelope> (APPROVED|REJECTED).")
        sys.exit(0)

    for _guard in range(200):
        j = frontier.frontier_for_state(state.st)
        cats = partition_ready(j.get("ready") or [], graph)
        joins, terminals, routers = cats["JOIN"], cats["TERMINAL"], cats["ROUTER"]
        workers = cats["WORKER"]
        g_block, g_free = cats["BLOCKING_GATE"], cats["FREE_GATE"]

        # Prioritní žebřík (joins → terminals → blocking-gate → workers+free-gate → routers →
        # judgment → inflight → terminal_reached → BLOCKED) je POLICY EXECUTORU — explicitní.
        if joins:
            for jn in joins:
                n = jn["node"]
                state.mark_completed(n)
                state.set_outcome(n, "PASS")
                state.active_node = n
            write()
            continue

        if terminals:
            n = terminals[0]["node"]
            state.mark_completed(n)
            state.set_outcome(n, "DONE")
            state.active_node = n
            state.status = "done"
            write()
            print(f"DONE: dosažen terminal '{n}' — běh u konce.")
            sys.exit(0)

        if g_block:
            g = g_block[0]
            n = g["node"]
            state.add_inflight(n)
            state.halt_gate = n
            state.active_node = n
            write()
            print(f"HALT (blocking gate): {n} interaction:{g.get('interaction') or '-'} "
                  f"level:{g.get('level') or '-'} — explicitní ano/ne. Po vstupu: run.py done <envelope>.")
            sys.exit(0)

        if workers or g_free:
            for w in workers + g_free:
                state.add_inflight(w["node"])
            for g in g_free:
                state.add_awaiting(g["node"])
            state.active_node = (workers or g_free)[0]["node"]
            write()
            print_dispatch(workers, g_free, state)
            sys.exit(0)

        if routers:
            n = routers[0]["node"]
            print(f"DECIDE: klasifikuj '{n}' (feature | bugfix | improvement) → "
                  f"run.py done <envelope> (outcome PASS, class: <třída>).")
            sys.exit(0)

        judgment = j.get("judgment") or []
        if judgment:
            print("DECIDE: ready prázdné, čeká úsudek nad judgment hranou — dispatch uzel, nebo run.py skip <node>:")
            for c in judgment:
                print(f"  - {c['node']:18} agent:{c.get('agent', '-'):16} (type:{c.get('type')})")
            sys.exit(0)

        inflight = j.get("inflight") or []
        if inflight:
            print(f"INFLIGHT: čeká na dokončení dispatchnutých uzlů: {', '.join(inflight)}. "
                  f"Po run.py done pokračuj run.py drive.")
            sys.exit(0)
        if j.get("terminal_reached"):
            state.status = "done"
            write()
            print("DONE: běh u konce.")
            sys.exit(0)
        print("BLOCKED: frontier prázdný, nic ready/inflight/judgment a není terminal — "
              "graf drhne (potřeba return / oprava). Zkontroluj outcomes/graf.")
        sys.exit(1)

    print("DRIVE: překročen guard 200 iterací (cyklus v auto-advance?).", file=sys.stderr)
    sys.exit(2)


def main() -> None:
    argv = sys.argv[1:]
    cmd = argv[0] if argv else "help"
    rest = argv[1:]

    if cmd == "start":
        if not rest:
            print("Usage: run.py start <run-id>", file=sys.stderr)
            sys.exit(2)
        mutate_state("start", rest[0])
    elif cmd == "active":
        if not rest:
            print("Usage: run.py active <node>", file=sys.stderr)
            sys.exit(2)
        mutate_state("active", rest[0])
    elif cmd == "skip":
        if not rest:
            print("Usage: run.py skip <node>", file=sys.stderr)
            sys.exit(2)
        mutate_state("skip", rest[0])
    elif cmd == "drive":
        drive()
    elif cmd == "status":
        import status
        status.main(rest)
    elif cmd == "next":
        frontier.main(rest)
    elif cmd == "done":
        import result
        result.main(rest)
    elif cmd == "summary":
        import ledger
        ledger.main(rest)
    elif cmd == "check":
        import check
        check.main(rest)
    elif cmd == "scaffold":
        # resolver (Fáze 3) — zatím přes sourozenecký .sh shim
        sys.exit(subprocess.run(["bash", os.path.join(PARENT, "scaffold.sh"), *rest]).returncode)
    elif cmd in ("help", "-h", "--help"):
        print(USAGE)
    else:
        print(f"Neznámý subcommand: {cmd}", file=sys.stderr)
        print(USAGE, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
