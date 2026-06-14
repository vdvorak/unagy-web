# Backlog: bootstrap skeleton ↔ structure-check drift

**Třída:** bugfix (engine/founding) · **Stav:** OPEN · **Priorita:** vysoká (každý nový projekt to potká)
**Nalezeno:** `2026-06-13` při foundingu `dream-team-app` (musel jsem project-config psát ručně, skeleton by neprošel).

## Problém

`scripts/setup/setup-claude-code.sh` (generátor skeletonu project-config) a `core/structure_check.py`
(validátor PRODUCT-tvaru, přidaný později) **se rozešly**. Čerstvě bootstrapnutý projekt **NEPROJDE**
`structure-check`:

| structure-check vyžaduje | skeleton generuje | výsledek |
|---|---|---|
| S1 sekce `## Project flags` | — chybí | **FAIL** |
| S1 sekce `## Active roles` (`active_roles:` keyed **rolí**/node-id) | `## Active agents` (`agents:` keyed **agent-short**) | **FAIL** |
| S2 `Fyzické cesty: graph` (na disku) | klíč chybí | **FAIL** |
| S2 `Fyzické cesty: engine` (na disku) | klíč chybí | **FAIL** |
| S4 `active_roles` klíče ∈ uzly grafu | n/a (sekce chybí) | **FAIL** |

(setup-claude-code.sh ř. 204–250: `## Active agents` / `agents:` keyed `vision-po,ted-architect…`;
`## Fyzické cesty` bez `graph`/`engine`; žádné `## Project flags`.)

## Proč to vadí

structure-check je guard, co se uplatní hned po foundingu. Když generátor produkuje tvar, co guard
odmítne, je každý nový projekt rozbitý už od bootstrapu — buď Watson/člověk přepisuje ručně (co jsem
musel u dream-team-app), nebo guard hlásí false-negativy. Inverze „vytvoří ↔ ověří" (jako u
self_host_init round-trip) tu NEdrží: **bootstrap → structure-check NEprojde.**

## Fix (scripts-not-LLM — generátor je deterministický)

Sjednotit generátor s validátorem. V `setup-claude-code.sh`:
1. `## Active agents`(agent-keyed) → **`## Active roles`** s `active_roles:` keyed **rolí** (= node-id
   grafu): `product/feasibility/architecture/db-schema/backend/web/ux-design/ui-system/design-intake/
   qa/spec-audit/security/code-quality/design-audit/devops/...` se stavy `active|inactive|done`.
2. Přidat sekci **`## Project flags`** (`flags: {}` — odvozují se z `active_targets`).
3. `## Fyzické cesty`: přidat **`graph: .agentic/pipeline/delivery.yaml`** + **`engine:
   .agentic/scripts/pipeline/core/`**.
4. Sladit i Watson interview recept (mapuje agent↔role) — Watson plní stejný tvar.

## Akceptace (round-trip, jako self_host_init)

```
create-project.sh <name> --claude  →  structure-check  →  RESULT: OK
```
Bootstrap musí produkovat tvar, co guard přijme. + selftest scénář „fresh bootstrap projde structure-check".

## Pozn.

Jediný self_host_init.py (self-host seeder) **už** správný tvar generuje (Active roles + Project flags +
graph/engine) — drift je jen v `setup-claude-code.sh` (normální greenfield/transition cesta). Vzít
formát z self_host_init jako kanonický a setup-claude-code k němu narovnat (jeden zdroj tvaru).
