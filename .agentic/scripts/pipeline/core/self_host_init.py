#!/usr/bin/env python3
"""self_host_init.py — deterministicky seedne PRODUCT vrstvu pro self-host (z self-host-init.sh).

Self-host = framework je svým vlastním projektem (repo JE zdroj `.agentic/`, nemůže klonovat
sám do sebe). Watson umí greenfield/transition, ale ne tenhle self-reference case — proto
mechanická část (seed PRODUCT vrstvy) je tady jako SKRIPT (scripts-not-LLM); rozhodnutí
(targets/stack + §Vize a mise) doplní Watson/Vision do TODO značek. Inverze structure_check.py
(ten TVAR ověřuje, tenhle ho VYTVOŘÍ) — po seedu projde `structure-check.sh`.

Idempotentní: seedne JEN chybějící artefakty (existující nepřepíše). Na už-self-hostnutém repu = no-op.

CLI:   python3 self_host_init.py [--name <project>] [--dry-run]
Závislost: python3 + PyYAML. Exit: 0 = OK (seednuto/nic) | 1 = není to framework | 2 = chyba.
"""
import argparse
import os
import sys
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import find_graph
from graph import Graph

# TOOL vrstva, která MUSÍ být na rootu, aby šlo o framework (self-host) — ne projekt, co ho konzumuje.
TOOL_MARKERS = ["constitution.md", "agents", "pipeline", "scripts/pipeline/core"]


def is_self_host() -> tuple[bool, str]:
    """Je root framework (TOOL vrstva přítomná) a NEkonzumuje jiný (.agentic/ chybí)?"""
    missing = [m for m in TOOL_MARKERS if not os.path.exists(m)]
    if missing:
        return False, f"není to framework — chybí TOOL vrstva na rootu: {missing} (pro projekt použij greenfield/transition)"
    if os.path.isdir(".agentic"):
        return False, "root má `.agentic/` → je to PROJEKT konzumující framework, ne self-host (použij transition/pickup)"
    return True, "framework (TOOL na rootu, bez .agentic/)"


def derive_roles(graph: Graph) -> list[str]:
    """active_roles = node-id každého uzlu s `agent` (= role). Všechny active; target/deploy-gating
    + user úprava řeší zbytek. Deterministicky z grafu (žádné hádání)."""
    return [nid for nid, n in graph.nodes.items() if n.agent]


def project_config_md(name: str, roles: list[str]) -> str:
    roles_block = "\n".join(f"  {r}: active" for r in roles)
    return f"""---
cache_key: project-config-{name}-v1.0
framework_version: self
last_updated: {date.today().isoformat()}
spec_language: cs
code_language: en
status: ACTIVE
---

# Project Config — {name}

Self-hostovaný projekt (vyseedováno `self-host-init`). TOOL vrstva na rootu (repo JE zdroj `.agentic/`).
TODO značky doplní Watson/Vision (interview = rozhodovací část; tohle byl deterministický seed).

## Projekt
```yaml
project_name: {name}
project_type: self-host
vision: >
  TODO — §Vize a mise v PROJECT-CONSTITUTION.md (Watson/Vision interview).
stage: TODO
audience: TODO
```

## Targets
```yaml
# TODO (Watson rozhodnutí): jaké targety má produkt + stack. Prázdné = žádný client target.
# has_server/has_db/has_deploy se odvodí z backend/db/deploy sub-klíčů (frontier.load_project_config).
active_targets: {{}}
```

## Project flags
```yaml
# Project-level flagy se odvozují z active_targets; explicitní override sem (např. has_deploy: false).
flags: {{}}
```

## Active roles
```yaml
# Odvozeno z grafu (uzly s agentem). Uprav per-need (inactive = vypnuto; target-gating řeší zbytek).
active_roles:
{roles_block}
```

## Fyzické cesty (logical → physical)
```yaml
project_constitution: PROJECT-CONSTITUTION.md
project_state: STATE.md
backlog: backlog/
handoffs: handoffs/
graph: pipeline/delivery.yaml
engine: scripts/pipeline/core/
```

## Klíčové invarianty (load-bearing)
```yaml
load_bearing: []
```

## Git
```yaml
note: "self-host; TOOL vrstva (agents/pipeline/scripts/templates/constitution/flow) = zdroj .agentic/ (agentic-sync)."
```
"""


def project_constitution_md(name: str) -> str:
    return f"""# {name} — Project Constitution

Projektová ústava. Doplňuje universal `constitution.md` o to, CO tento projekt je.
Self-hostovaný (vyseedováno `self-host-init`); TODO sekce doplní Vision/Tony/Ted.

## Vize a mise   <!-- vlastní Vision -->
TODO — 1–3 věty: co projekt dělá, proč, dlouhodobý cíl. (Watson/Vision interview — LLM část initu.)

## Hodnoty   <!-- Vision + Tony -->
- TODO

## Cílová skupina   <!-- Vision -->
TODO

## Co projekt JE / NENÍ   <!-- Vision -->
**Je:** TODO
**Není:** TODO

## Nefunkční požadavky (NFR)   <!-- Tony + Ted -->
- TODO

## Doménová security pravidla   <!-- Tony, Heimdall -->
TODO

## Delivery topologie   <!-- Tony + Ted -->
TODO

## Doménové hard rules
- TODO
"""


def state_md(name: str) -> str:
    return f"""# {name} — State

Živý stav projektu. Edituje Watson (handoff mode) a orchestrátor.

## Aktuální fokus

Self-host vyseedován (`self-host-init`). PRODUCT vrstva založena; TODO: doplnit
`PROJECT-CONSTITUTION §Vize a mise` + `project-config §Targets` (Watson interview).

## Open Items

- [ ] **Vize + targety** — doplnit TODO v PROJECT-CONSTITUTION + project-config (Watson/Vision).
"""


def seed(name: str, roles: list[str], dry_run: bool) -> list[str]:
    """Seedne chybějící PRODUCT artefakty (idempotentně). Vrátí log akcí."""
    plan: list[tuple[str, str]] = [
        ("project-config.md", project_config_md(name, roles)),
        ("PROJECT-CONSTITUTION.md", project_constitution_md(name)),
        ("STATE.md", state_md(name)),
        ("current-run.md", _current_run_idle()),
    ]
    log: list[str] = []
    for path, content in plan:
        if os.path.exists(path):
            log.append(f"  skip   {path} (existuje)")
            continue
        log.append(f"  {'would-create' if dry_run else 'create'} {path}")
        if not dry_run:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(content)
    for d in ("backlog", "handoffs"):
        if os.path.isdir(d):
            log.append(f"  skip   {d}/ (existuje)")
        else:
            log.append(f"  {'would-mkdir' if dry_run else 'mkdir'} {d}/")
            if not dry_run:
                os.makedirs(d, exist_ok=True)
    return log


def _current_run_idle() -> str:
    return """# current-run.md — strojový stav běhu pipeline

Strojově čitelný stav grafu. Po uzavření wave se archivuje do handoffu a resetuje na idle.

```yaml
run: null
graph: delivery
status: idle
class: null
active_node: null
frontier: []
completed: []
outcomes: {}
skipped: []
counters: {}
epoch: 0
type_versions: {}
node_versions: {}
findings: []
return_payload: {}
model_overrides: {}
awaiting_human: []
halt_gate: null
last_outcome: null
flags: {}
note: null
```

## Lidský přehled

Idle. Self-host vyseedován; doplň TODO (vize/targety) a hoď první issue do `backlog/`.
"""


def main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--name", default=os.path.basename(os.path.abspath(".")))
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)

    ok, reason = is_self_host()
    print(f"detekce: {reason}")
    if not ok:
        sys.exit(1)

    graph_file = find_graph()
    if not graph_file:
        print("CHYBA: nenalezen pipeline/delivery.yaml (TOOL vrstva).", file=sys.stderr)
        sys.exit(2)
    roles = derive_roles(Graph.load(graph_file))
    print(f"active_roles odvozeno z grafu: {len(roles)} rolí")

    log = seed(args.name, roles, args.dry_run)
    print("\n".join(log))

    created = any("create" in line or "mkdir" in line for line in log)
    if args.dry_run:
        print("\n(dry-run — nic nezapsáno)")
    elif created:
        print("\nPRODUCT vrstva vyseedována. Dál: doplň TODO (§Vize a mise + §Targets) přes Watson/Vision,"
              " ověř `structure-check.sh`, hoď issue do backlog/.")
    else:
        print("\nNic k seedování — projekt už má PRODUCT vrstvu. Ověř `structure-check.sh`.")
    sys.exit(0)


if __name__ == "__main__":
    main()
