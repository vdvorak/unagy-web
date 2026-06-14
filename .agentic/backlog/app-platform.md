# Backlog: Node-editor platforma → FOUNDED jako samostatný projekt

**Třída:** feature (epická) · **Stav:** FOUNDED (`2026-06-13`) → `~/dev/AI/dream-team-app` · **Priorita:** north-star

## Stav

**Projekt založen jako samostatné repo `~/dev/AI/dream-team-app`** — staví se **vlastním dream-team
flow** („flow staví svoje budoucí UI"). Plná vize, project-config (greenfield, web target
python-fastapi+solidjs+postgres+docker-compose), backlog (8 featur) a roadmapa tam. **Detailní scope
už NEŽIJE tady** — viz `dream-team-app/PROJECT-CONSTITUTION.md` + `dream-team-app/backlog/00-roadmap.md`.

První featura: **live-view** (čte `current-run.md` přes engine `core`). Pořadí: live-view → done-endpoint
→ node-editor → issue-board → ai-callable-todos → in-app-interaction → token-gating → agent-authoring.

## Co tady zůstává: engine-side kontrakt (akceptační kritérium DREAM-TEAM změn)

App = „stejný engine, dvě UI": app **importuje** `core/`, NEreimplementuje. To klade povinnost na
**tenhle** repo (engine), ne na appku: **engine MUSÍ zůstat app-ready** — vše v souborech, typované
I/O, strukturované `/done` přechody. To je akceptační kritérium **každé** engine změny tady, ne až
starost appky. Crosswalk, co app v enginu čte (a co tedy engine musí držet stabilní):

| Souborový artefakt (engine teď) | App reprezentace (dream-team-app) |
|---|---|
| `pipeline/delivery.yaml` (graf, typované I/O) | node editor (spojí jen kompatibilní I/O) |
| `current-run.md` (stav běhu) | live-view — co flow zrovna dělá |
| node-result obálka + handoff (`result.sh`/`core.result`) | `/done` endpoint: výstupy → vstupy dalšího kroku |
| `human-gate` uzel + `interactions.yaml` | in-app interakce přes typed interface (ne terminál) |
| `project-config` + issues v souborech | projektový board + issues přes API |
| token model `vtodo` (`../Trabajario`) | token-gated přístup — každý actor sahá jen na své |

Když se kterýkoli z těchto artefaktů v enginu mění, musí zůstat čitelný/importovatelný appkou
(otypovaný, souborový, deterministický) — jinak se rozbije druhé UI.
