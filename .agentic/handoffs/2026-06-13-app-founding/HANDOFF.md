---
wave: 2026-06-13-app-founding
from: orchestrator (Watson session)
to: next-session
type: milestone
returns_to: null
timestamp: 2026-06-13T11:25:00+02:00
---

# Handoff: North-star app FOUNDED jako samostatný projekt

## Stav (jak chápu situaci)

Self-hosting byl hotový a ověřený (P5 protekl flow; structure-check + self-host-init guardy). Tahle
session posunula dogfooding z „engine featura / self-host" na **založení prvního reálného produktu**:
node-editor platforma (north-star z `backlog/app-platform.md`) je teď **samostatné repo
`~/dev/AI/dream-team-app`**, které se bude stavět **vlastním dream-team flow** („flow staví svoje
budoucí UI"). Tahle session **NEstavěla featury** appky — jen ji **founderovala** (intent vrstva), aby
Vitek mohl přijít, říct „hej Watsone" a nechat flow implementovat. Engine (tenhle repo) se nezměnil
kódově — jen de-dup backlogu + jeden nález.

## Plán (co jsem udělal)

1. Založil `~/dev/AI/dream-team-app` jako samostatný projekt (Watson greenfield, hrán orchestrátorem).
2. Sepsal plnou vizi + config + backlog appky tam (architektura **engine-reuse**).
3. V dream-teamu: app-platform.md → pointer (de-dup) + zaznamenal bootstrap↔structcheck drift nález.

## Výsledek

**V `dream-team-app` (repo commitnuto `20bed4f`, `263bbae`):**
- `PROJECT-CONSTITUTION.md` — plná vize: app = executor + UI + produktový layer **nad** dream-team
  enginem. Load-bearing: app **importuje** `core/` (graph/frontier/result), NEreimplementuje („stejný
  engine, dvě UI"); `/done` = wrapper nad `core.result`; stav flow v souborech, DB jen produktový layer.
- `project-config.md` — greenfield, web target (python-fastapi+solidjs+postgres+docker-compose),
  role-keyed `active_roles`, `graph`/`engine` cesty do `.agentic/`.
- `backlog/` — 8 featur + roadmapa (live-view → done-endpoint → node-editor → issue-board →
  ai-callable-todos → in-app-interaction → token-gating → agent-authoring).
- `STATE.md`, founding `HANDOFF.md` — Watson session-resume ready.
- `structure-check` S1–S4 **OK**.

**V `dream-team` (tenhle repo, commit `77a2bd8`):**
- `backlog/app-platform.md` — (upraven) → **pointer** na dream-team-app. Zůstal **engine-side kontrakt**:
  „engine MUSÍ zůstat app-ready" (akceptační kritérium engine změn) + crosswalk artefakt→app reprezentace.
- `backlog/bootstrap-structcheck-drift.md` — (vytvořen) **nález**: `setup-claude-code.sh` generuje skeleton
  (`## Active agents`, bez `Project flags`/`Active roles`/`graph`/`engine`), co **NEPROJDE** structure-check
  (S1+S2+S4). Proto se project-config psal ručně. **OPEN.**

## Decided (rozhodnutí, která následná session NEOPAKUJE)

- **App = samostatné repo**, ne součást dream-teamu. Engine se sdílí přes `.agentic/` (klon, agentic-sync).
- **Engine reuse, ne reimplementace** (load-bearing pravidlo appky). Nová logika flow → dream-team, ne app.
- **De-dup hotový** — detailní app scope žije v dream-team-app; tady jen engine-side kontrakt. Nezdvojovat.
- **Scaffold base položí flow appky**, ne founding (scaffold-passing = integrační práce = práce flow).
- **App se staví flow, ne ručně** — orchestrátor v dream-team-app hraje agenty; já (dream-team session)
  app featury nebuduju.

## Next step

**Engine (tenhle repo):** otevřený nález `backlog/bootstrap-structcheck-drift.md` — narovnat
`setup-claude-code.sh` k tvaru `self_host_init` (Active roles + Project flags + graph/engine cesty),
ať `create-project.sh → structure-check` projde (round-trip, jako self_host_init). selftest scénář
„fresh bootstrap projde structure-check".

**Produkt:** práce na appce běží v `~/dev/AI/dream-team-app` přes její flow (live-view #1) — mimo tenhle repo.

## Slabé místo (POVINNÉ)

- **bootstrap-drift nález není opravený, jen zapsaný** — dokud se setup-claude-code.sh nenarovná, každý
  nový bootstrap project-config neprojde structure-check (musí se ručně dopsat, jako teď u dream-team-app).
  Zapsáno do `backlog/bootstrap-structcheck-drift.md` (OPEN) → patří do §Open Items.
- **Scaffold-passing v greenfieldu nebyl ještě naostro otestován** — první featura appky bude první reálný
  test, že backend/web uzel dostane scaffold a položí `server/`/`clients/web/`. Pokud to drhne, je to
  engine gap (dream-team), ne app gap.
