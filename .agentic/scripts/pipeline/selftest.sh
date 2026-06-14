#!/usr/bin/env bash
# selftest.sh — end-to-end smoke test pipeline runneru.
#
# Protáhne celou smyčku v dočasném adresáři: start → done (více uzlů) → status →
# next → summary → check. Ověří, že scripty (run/state/next/result/ledger/check) do
# sebe integrují. Regression guard; nemodifikuje repo (běží v mktemp).
#
# Usage: bash scripts/pipeline/selftest.sh
# Exit:  0 = vše prošlo | 1 = nějaký assert selhal

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export PIPELINE_GRAPH="$REPO/pipeline/delivery.yaml"
RUN="$REPO/scripts/pipeline/run.sh"

FAILS=0
ok()  { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; FAILS=$((FAILS+1)); }

WORK="$(mktemp -d)"; cd "$WORK"
RID="selftest"

node_done() {  # 1=node 2=outcome 3=model 4=outputs(inline yaml)
  cat > _e.yaml <<EOF
run: $RID
node: $1
outcome: $2
outputs: $4
cost: { model: $3, input_tokens: 10000, output_tokens: 4000 }
time: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:06:00Z }
EOF
  bash "$RUN" done _e.yaml >/dev/null 2>&1
}

echo "== pipeline selftest =="

bash "$RUN" start "$RID" >/dev/null 2>&1 && grep -q "active_node: intake" current-run.md \
  && ok "start → active_node=intake" || bad "start"

bash "$RUN" next --from intake --class feature 2>/dev/null | grep -q "product" \
  && ok "next intake (feature) → product" || bad "next intake→product"

node_done product PASS sonnet "[{type: spec},{type: acceptance},{type: has_ui}]"
bash "$RUN" status 2>/dev/null | grep -q "product" \
  && ok "done product → completed obsahuje product" || bad "done product"

bash "$RUN" next --from feasibility --outcome PASS 2>/dev/null | grep -q "architecture" \
  && ok "next feasibility(PASS) → architecture" || bad "next tony→architecture"

node_done feasibility PASS opus "[{type: gate-output}]"
node_done architecture PASS opus "[{type: contract},{type: reuse-decision}]"
node_done backend PASS sonnet "[{type: server-code},{type: unit-tests}]"

# nevalidní typ musí být odmítnut (loop integrity)
cat > _bad.yaml <<EOF
run: $RID
node: backend
outcome: PASS
outputs: [{type: server-kod}]
time: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }
EOF
bash "$RUN" done _bad.yaml >/dev/null 2>&1 && bad "nevalidní typ NEodmítnut" || ok "nevalidní typ odmítnut (C8/C9)"

# fail-closed slovník (vocabulary.yaml): neznámá severity / fault = nevalidní envelope (ne tichý fallback)
printf 'run: %s\nnode: backend\noutcome: FAIL\nseverity: critical\nreturns_to: architecture\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' "$RID" > _sev.yaml
bash "$RUN" done _sev.yaml >/dev/null 2>&1 && bad "neznámá severity NEodmítnuta" || ok "fail-closed: neznámá severity 'critical' odmítnuta (vocabulary)"
printf 'run: %s\nnode: architecture\noutcome: FAIL\nfault: typo-domain\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' "$RID" > _flt.yaml
bash "$RUN" done _flt.yaml >/dev/null 2>&1 && bad "neznámý fault NEodmítnut" || ok "fail-closed: neznámý fault 'typo-domain' odmítnut (vocabulary)"

# B1 (phantom PASS): output deklaruje path, který na disku NEexistuje → odmítnout
# (stub ledger nesmí potvrdit artefakt, který nikdy nevznikl — flow-finish #4).
cat > _phantom.yaml <<EOF
run: $RID
node: backend
outcome: PASS
outputs: [{type: server-code, path: server/src/does-not-exist.py}]
time: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }
EOF
bash "$RUN" done _phantom.yaml >/dev/null 2>&1 && bad "phantom path NEodmítnut" || ok "phantom path odmítnut (B1 path-existence)"

# B1 pozitivní strana: reálně existující path projde validací (--check-only)
mkdir -p server/src && : > server/src/real.py
cat > _real.yaml <<EOF
run: $RID
node: backend
outcome: PASS
outputs: [{type: server-code, path: server/src/real.py}]
time: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }
EOF
bash "$RUN" done _real.yaml --check-only >/dev/null 2>&1 && ok "existující path projde (B1)" || bad "existující path NEprošel"

[[ -f "runs/$RID/ledger.yaml" ]] && ok "ledger.yaml existuje" || bad "ledger chybí"

bash "$RUN" summary "$RID" 2>/dev/null | grep -q "kredity" \
  && ok "summary → cost+čas report" || bad "summary"
[[ -f "runs/$RID/summary.md" ]] && ok "summary.md zapsán" || bad "summary.md chybí"

# ── drive frontier-executor end-to-end (regression guard: F2 frontier rewrite, F3
#    outcomes/re-flow, join auto-advance, flow-finish #1 human-gate continuation,
#    flow-finish #2 T3-post release path, F5 fork-paralelita, confluence barrier) ──
# Protáhne celý happy-path z fresh stavu deterministicky; workery dispatchne (done PASS),
# non-blocking gaty odpoví dle interactions.yaml, blocking gate (HALT) APPROVED.
CUR_RID=""
dn() {  # done <node> — generic work uzel: PASS + gate-output (typ ∈ artifacts stačí)
  printf 'run: %s\nnode: %s\noutcome: PASS\noutputs: [{type: gate-output}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' "$CUR_RID" "$1" > _d.yaml
  bash "$RUN" done _d.yaml >/dev/null 2>&1
}
dn_gate() {  # done <gate> <outcome> — human-gate: BEZ typovaného outputu, outcome z interakce
  printf 'run: %s\nnode: %s\noutcome: %s\noutputs: []\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' "$CUR_RID" "$1" "$2" > _d.yaml
  bash "$RUN" done _d.yaml >/dev/null 2>&1
}
done_intake() {  # router intake → klasifikace feature (class persistovaná do stavu)
  printf 'run: %s\nnode: intake\noutcome: PASS\nclass: feature\noutputs: []\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' "$CUR_RID" > _d.yaml
  bash "$RUN" done _d.yaml >/dev/null 2>&1
}
seed_vision() {  # seed <run-id> <has_deploy> <has_ui> [active_targets-yaml]
  CUR_RID="$1"
  bash "$RUN" start "$CUR_RID" >/dev/null 2>&1
  if [[ -n "${4:-}" ]]; then
    printf '```yaml\nflags: { has_server: true, has_db: true, has_deploy: %s }\nactive_targets: %s\n```\n' "$2" "$4" > project-config.md
  else
    printf '```yaml\nflags: { has_server: true, has_db: true, has_deploy: %s }\n```\n' "$2" > project-config.md
  fi
  done_intake                                  # intake (router) → DECIDE → done + class
  printf 'run: %s\nnode: product\noutcome: PASS\noutputs: [{type: spec},{type: acceptance}]\nflags: {has_ui: %s}\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:06:00Z }\n' "$CUR_RID" "$3" > _v.yaml
  bash "$RUN" done _v.yaml >/dev/null 2>&1
}
# Protáhne frontier executor z aktuálního stavu k terminalu/bloku. Každý FRONTIER krok:
# workery dispatchne (done PASS) PARALELNĚ, non-blocking gaty odpoví (l2-review/design ACK),
# blocking gate (HALT) APPROVED, judgment (ui-system) dispatchne. Globály: DRV_DONE,
# DRV_GATES (dosažené gaty), DRV_NODES (pořadí dispatchů), DRV_R1 (akce 1. frontieru).
drive_loop() {
  DRV_DONE=0; DRV_GATES=""; DRV_NODES=""; DRV_R1=""
  for _ in $(seq 1 80); do
    DROUT="$(bash "$RUN" drive 2>&1)"
    HEAD="$(printf '%s\n' "$DROUT" | grep -oE '^(FRONTIER|DONE|HALT|DECIDE|BLOCKED|INFLIGHT)' | head -1)"
    case "$HEAD" in
      DONE)             DRV_DONE=1; break;;
      BLOCKED|INFLIGHT) break;;
      HALT)
        G="$(printf '%s' "$DROUT" | grep -oP 'blocking gate\): \K\S+')"
        DRV_GATES="$DRV_GATES $G"; DRV_NODES="$DRV_NODES $G"; dn_gate "$G" APPROVED;;
      DECIDE)
        if printf '%s' "$DROUT" | grep -q 'ui-system'; then dn ui-system; DRV_NODES="$DRV_NODES ui-system"
        elif printf '%s' "$DROUT" | grep -q 'intake'; then done_intake
        else break; fi;;
      FRONTIER)
        [[ -z "$DRV_R1" ]] && DRV_R1="$DROUT"
        for n in $(printf '%s' "$DROUT" | grep -oP '^\s*DISPATCH \K\S+'); do dn "$n"; DRV_NODES="$DRV_NODES $n"; done
        for g in $(printf '%s' "$DROUT" | grep -oP '^\s*HUMAN-GATE \K\S+'); do
          case "$g" in deploy-approve) dn_gate "$g" APPROVED;; *) dn_gate "$g" ACK;; esac
          DRV_GATES="$DRV_GATES $g"; DRV_NODES="$DRV_NODES $g"
        done;;
    esac
  done
}

# Scénář A — has_deploy=false, has_ui=false: fresh → … → l2-review (ACK) → done (terminal).
seed_vision drivetest false false
drive_loop
printf '%s' "$DRV_GATES" | grep -q "l2-review" \
  && ok "drive frontier: fresh → human-gate l2-review (F2 loop closed)" || bad "drive frontier nedosáhl l2-review (F2)"
{ [[ "$DRV_DONE" == 1 ]] && grep -q "status: done" current-run.md && grep -qE "awaiting_human: \[\]" current-run.md; } \
  && ok "human-gate continuation: gate(ACK) → drive pokračuje → DONE (flow-finish #1)" \
  || bad "human-gate continuation neproběhla (flow-finish #1)"
grep -q "audit-join" current-run.md \
  && ok "join auto-advance: audit-join v completed (F2)" || bad "join auto-advance (F2)"

# Scénář B — has_deploy=true: T3-post release path (blocking L3 gate deploy-approve = HALT).
#   l2-review(ACK) → devops → deploy-approve(APPROVED) → production → monitor(PASS) → done.
seed_vision deploytest true false
drive_loop
{ printf '%s' "$DRV_GATES" | grep -q "l2-review" && printf '%s' "$DRV_GATES" | grep -q "deploy-approve"; } \
  && ok "T3-post: l2-review(ACK, non-blocking) + deploy-approve(APPROVED, HALT/L3)" || bad "T3-post gaty nedosaženy"
{ [[ "$DRV_DONE" == 1 ]] && grep -q "active_node: done" current-run.md \
    && grep -q "production" current-run.md && grep -q "monitor" current-run.md; } \
  && ok "T3-post release path: devops→deploy-approve→production→monitor→done (flow-finish #2)" \
  || bad "T3-post release path neproběhla (flow-finish #2)"

# Scénář C — has_ui=true, web target, design_source=author (default): fork (tony ∥ ux-design),
#   confluence (web čeká architecture+ui-system), design-audit 5. auditor → DONE. (F5 / acceptance #2).
seed_vision uitest false true "{ web: true }"
drive_loop
{ printf '%s' "$DRV_R1" | grep -q 'feasibility' && printf '%s' "$DRV_R1" | grep -q 'ux-design'; } \
  && ok "frontier fork: 1. krok dispatchne tony ∥ ux-design paralelně (author, bez gate) (F5)" || bad "frontier fork paralelní (F5)"
[[ "$(printf '%s' "$DRV_NODES" | grep -oE 'ui-system|web' | head -1)" == "ui-system" ]] \
  && ok "confluence barrier: web dispatchnut až PO ui-system (čeká architecture+ui-system)" || bad "confluence barrier (web před ui-system)"
{ [[ "$DRV_DONE" == 1 ]] && grep -q "design-audit" current-run.md && grep -q "ui-system" current-run.md && grep -q "web" current-run.md; } \
  && ok "has_ui=true end-to-end: design-audit 5. auditor, ui-system+web → DONE (acceptance #2)" \
  || bad "has_ui=true end-to-end nedoběhl do DONE (acceptance #2)"
rm -f project-config.md _v.yaml _d.yaml _i.yaml

# ── REJECTED halt: deploy-approve (L3) zamítnut → běh zastaven, production neprosákne ──
CUR_RID=rejtest
printf '```yaml\nrun: rejtest\nstatus: in_progress\nclass: feature\nactive_node: deploy-approve\nfrontier: [deploy-approve]\ncompleted: [intake, product, feasibility, architecture, backend, qa, performance, spec-audit, security, code-quality, audit-join, l2-review, devops]\noutcomes: {devops: PASS, l2-review: ACK}\nskipped: []\ncounters: {}\nawaiting_human: []\nhalt_gate: deploy-approve\nflags: {has_server: true, has_db: true, has_deploy: true, has_ui: false}\n```\n' > current-run.md
dn_gate deploy-approve REJECTED
DR="$(bash "$RUN" drive 2>&1)"
{ grep -q 'status: blocked' current-run.md && printf '%s' "$DR" | grep -q '^BLOCKED' && printf '%s' "$DR" | grep -qi 'REJECTED'; } \
  && ok "REJECTED halt: deploy-approve REJECTED → drive BLOCKED, běh zastaven (constitution §8)" \
  || bad "REJECTED halt (drive nezastavil čistě)"
! grep -qw 'production' current-run.md \
  && ok "REJECTED halt: production se NEspustil (žádný deploy bez souhlasu)" || bad "REJECTED: production prosákl"
rm -f current-run.md _d.yaml

# ── F3 (Fáze 2): FAIL+return un-completne JEN cíl; downstream zůstává (lazy přes staleness) ──
# Dřív eager forward_closure (un-complete cíl + celý downstream). Fáze 2: jen cíl (backend) →
# downstream (qa) ZŮSTÁVÁ completed, re-run ho řeší až version-staleness (next.sh, Fáze 3),
# když cíl po re-runu reálně změní jeho vstupní typ. architecture (upstream) se netýká.
printf '```yaml\nrun: retest\nstatus: in_progress\nactive_node: security\nfrontier: []\ncompleted: [intake, product, feasibility, architecture, backend, qa, security, performance, spec-audit, code-quality]\noutcomes: {backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nawaiting_human: []\n```\n' > current-run.md
printf 'run: retest\nnode: security\noutcome: FAIL\nreturns_to: backend\noutputs: [{type: gate-output}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _f.yaml
bash "$RUN" done _f.yaml >/dev/null 2>&1
CMP="$(bash "$RUN" status 2>/dev/null | grep '^completed:')"
{ printf '%s' "$CMP" | grep -q 'architecture' && ! printf '%s' "$CMP" | grep -qw 'backend' && printf '%s' "$CMP" | grep -qw 'qa'; } \
  && ok "FAIL+return Fáze 2: un-complete JEN cíl (backend); qa/downstream zůstává (lazy), architecture netčen" \
  || bad "FAIL+return lazy un-complete (Fáze 2)"
grep -q 'security->backend' current-run.md \
  && ok "FAIL+return: counter security->backend bumpnut (3× = BLOCKER)" || bad "FAIL+return counter (F3)"
rm -f current-run.md _f.yaml

# ── E1: advisory FAIL = finding bez re-flow (severity gating deterministicky ze vstupu) ──
# Gate najde non-blocking nález → uzel HOTOV (join pokračuje), zapsán do findings, NIC se
# neun-completne. Odděluje kosmetický nález (spec-audit) od blocking (security) bez úsudku drive.
printf '```yaml\nrun: advtest\nstatus: in_progress\nactive_node: spec-audit\nfrontier: [spec-audit]\ncompleted: [intake, product, feasibility, architecture, backend, qa, security, performance, code-quality]\noutcomes: {backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nfindings: []\nreturn_payload: {}\n```\n' > current-run.md
printf 'run: advtest\nnode: spec-audit\noutcome: FAIL\nseverity: advisory\nreturns_to: product\nsignature: spec names impl detail\noutputs: [{type: gate-output}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _a.yaml
bash "$RUN" done _a.yaml >/dev/null 2>&1
CMP="$(bash "$RUN" status 2>/dev/null | grep '^completed:')"
{ printf '%s' "$CMP" | grep -qw 'spec-audit' && printf '%s' "$CMP" | grep -qw 'architecture' && printf '%s' "$CMP" | grep -qw 'backend'; } \
  && ok "E1 advisory: uzel completed, ŽÁDNÝ re-flow (architecture/backend zůstali) [severity gating]" || bad "E1 advisory: re-flow nečekaně proběhl"
grep -q 'severity: advisory' current-run.md \
  && ok "E1 advisory: finding zaznamenán do findings ledgeru" || bad "E1 advisory: finding nezapsán"
rm -f current-run.md _a.yaml

# ── E1: blocking FAIL nese failure-signature do re-dispatch (payload-carry), pak ji smaže ──
# returns_to vrací řízení, signature jede do return_payload[cíl] → drive ji deterministicky
# vytiskne při re-dispatchi (re-běh nezávisí na paměti orchestrátora). Po úspěšném re-běhu se smaže.
printf '```yaml\nrun: paytest\nstatus: in_progress\nclass: feature\nactive_node: code-quality\nfrontier: [code-quality]\ncompleted: [intake, product, feasibility, architecture, db-schema, backend, qa, security, performance, spec-audit]\noutcomes: {backend: PASS, qa: PASS, architecture: PASS}\nskipped: []\ncounters: {}\nfindings: []\nreturn_payload: {}\nflags: {has_server: true, has_db: true, has_ui: false}\n```\n' > current-run.md
printf 'run: paytest\nnode: code-quality\noutcome: FAIL\nseverity: blocking\nreturns_to: backend\nsignature: MISSING_TYPE user_id UUID\noutputs: [{type: gate-output}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _p.yaml
bash "$RUN" done _p.yaml >/dev/null 2>&1
grep -q 'MISSING_TYPE user_id UUID' current-run.md \
  && ok "E1 payload-carry: signature uložena do return_payload" || bad "E1 payload-carry: signature chybí ve stavu"
DP="$(bash "$RUN" drive 2>&1)"
{ printf '%s' "$DP" | grep -q 'DISPATCH backend' && printf '%s' "$DP" | grep -q 'MISSING_TYPE user_id UUID'; } \
  && ok "E1 payload-carry: drive re-dispatch backend NESE finding deterministicky" || bad "E1 payload-carry: drive nevytiskl finding"
printf 'run: paytest\nnode: backend\noutcome: PASS\noutputs: [{type: server-code}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:02:00Z }\n' > _p2.yaml
bash "$RUN" done _p2.yaml >/dev/null 2>&1
# return_payload (actionable) se smaže; findings (audit ledger) si signature ZÁMĚRNĚ nechá.
{ grep -q 'return_payload: {}' current-run.md && grep -q 'severity: blocking' current-run.md; } \
  && ok "E1 payload-carry: po PASS return_payload smazán, findings ledger nález drží" || bad "E1 payload-carry: payload/ledger lifecycle špatně"
rm -f current-run.md _p.yaml _p2.yaml

# ── B3: Tony triage model-override → drive čte override místo statického grafu (determinismus) ──
# Graf má backend: model: sonnet; Tony triage řekne XS→haiku. Override jde do stavu → drive ho
# honoruje deterministicky (ne ruční překlad orchestrátorem). Hvězdička = rozhodl triage.
printf '```yaml\nrun: b3test\nstatus: in_progress\nclass: feature\nfrontier: [feasibility]\ncompleted: [intake, product]\noutcomes: {intake: PASS, product: PASS}\nskipped: []\ncounters: {}\nfindings: []\nreturn_payload: {}\nmodel_overrides: {}\nflags: {has_server: true, has_db: true, has_ui: false}\n```\n' > current-run.md
printf 'run: b3test\nnode: feasibility\noutcome: PASS\noutputs: [{type: gate-output}]\nmodels: {backend: haiku}\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _t.yaml
bash "$RUN" done _t.yaml >/dev/null 2>&1
grep -q 'backend: haiku' current-run.md \
  && ok "B3: Tony triage override zapsán do model_overrides" || bad "B3: override nezapsán"
printf 'run: b3test\nnode: architecture\noutcome: PASS\noutputs: [{type: contract}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _t2.yaml
bash "$RUN" done _t2.yaml >/dev/null 2>&1
printf 'run: b3test\nnode: db-schema\noutcome: PASS\noutputs: [{type: db-schema}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _t3.yaml
bash "$RUN" done _t3.yaml >/dev/null 2>&1
DB3="$(bash "$RUN" drive 2>&1)"
printf '%s' "$DB3" | grep -E 'DISPATCH backend ' | grep -q 'haiku\*' \
  && ok "B3: drive DISPATCH backend nese triage model haiku* (ne grafový sonnet)" || bad "B3: drive nehonoroval override"
printf 'run: b3test\nnode: feasibility\noutcome: PASS\noutputs: [{type: gate-output}]\nmodels: {backend: gpt4}\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _t4.yaml
bash "$RUN" done _t4.yaml >/dev/null 2>&1 && bad "B3: nevalidní model NEodmítnut" || ok "B3: nevalidní model-override odmítnut (∉ haiku/sonnet/opus)"
rm -f current-run.md _t.yaml _t2.yaml _t3.yaml _t4.yaml

# ── Incremental rebuild Fáze 1: completion stampuje epoch + type/node verze (additivní) ──
# Default (chybí `changed`) = output-typy uzlu z grafu → type_versions; node_versions[node]=epoch.
# `changed: none` → bumpne JEN node verzi (clear staleness), žádný type (bez propagace).
# Routing verze zatím NEČTE (Fáze 3) → tohle je čistý zápisový kontrakt, chování beze změny.
printf '```yaml\nrun: stamptest\nstatus: in_progress\ncompleted: [intake]\noutcomes: {intake: PASS}\nfrontier: [product]\nepoch: 0\ntype_versions: {}\nnode_versions: {}\n```\n' > current-run.md
printf 'run: stamptest\nnode: product\noutcome: PASS\noutputs: [{type: spec},{type: acceptance}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:06:00Z }\n' > _s.yaml
bash "$RUN" done _s.yaml >/dev/null 2>&1
python3 - <<'PY'
import yaml,re,sys
st=yaml.safe_load(re.search(r"```yaml\s*\n(.*?)\n```", open("current-run.md",encoding="utf-8").read(), re.S).group(1)) or {}
tv, nv, ep = st.get("type_versions",{}), st.get("node_versions",{}), st.get("epoch",0)
# default changed = product graf outputs [spec, acceptance, has_ui]
sys.exit(0 if (ep>=1 and nv.get("product")==ep and tv.get("spec")==ep and tv.get("acceptance")==ep and tv.get("has_ui")==ep) else 1)
PY
[[ $? -eq 0 ]] && ok "Fáze 1 stamp: default changed = graf outputs (spec/acceptance/has_ui + node_versions[product]=epoch)" \
  || bad "Fáze 1 stamp: default stamping nezapsal verze správně"

printf 'run: stamptest\nnode: architecture\noutcome: PASS\nchanged: none\noutputs: [{type: contract}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _s2.yaml
bash "$RUN" done _s2.yaml >/dev/null 2>&1
python3 - <<'PY'
import yaml,re,sys
st=yaml.safe_load(re.search(r"```yaml\s*\n(.*?)\n```", open("current-run.md",encoding="utf-8").read(), re.S).group(1)) or {}
tv, nv, ep = st.get("type_versions",{}), st.get("node_versions",{}), st.get("epoch",0)
# architecture changed:none → node_versions[architecture]=epoch (≥2), ale contract NENÍ v type_versions (žádná propagace)
sys.exit(0 if (ep>=2 and nv.get("architecture")==ep and "contract" not in tv) else 1)
PY
[[ $? -eq 0 ]] && ok "Fáze 1 stamp: changed:none → jen node_versions[architecture], žádný type bump (bez propagace)" \
  || bad "Fáze 1 stamp: changed:none chybně (type bumpnut / node verze nezapsána)"
rm -f current-run.md _s.yaml _s2.yaml

# ── F3: minimal envelope → auto-derive z grafu (deterministický most handoff→envelope) ──
# Orchestrátor dodá jen JUDGMENT {run, node, outcome}; result.sh doplní output typy, agent,
# phase z grafu (zdroj pravdy) + time→seconds=0 (honest „neměřeno"). Konec ručního mapování
# outputů na typy (divergence-zdroj: dva orchestrátoři → různé envelopy ze stejného výstupu).
printf '```yaml\nrun: f3test\nstatus: in_progress\ncompleted: [intake, product, feasibility, architecture, db-schema]\noutcomes: {}\nfrontier: [backend]\nepoch: 5\ntype_versions: {}\nnode_versions: {}\n```\n' > current-run.md
printf 'run: f3test\nnode: backend\noutcome: PASS\n' > _f3.yaml
bash "$RUN" done _f3.yaml >/dev/null 2>&1
python3 - <<'PY'
import yaml, sys
docs = [d for d in yaml.safe_load_all(open("runs/f3test/ledger.yaml", encoding="utf-8")) if d]
e = docs[-1]   # poslední ledger doc = backend envelope (auto-derived)
types = {o.get("type") for o in (e.get("outputs") or [])}
ok = (e.get("agent") == "bob-backend" and e.get("phase") == "T2"
      and types == {"server-code", "unit-tests"} and (e.get("time") or {}).get("seconds") == 0)
sys.exit(0 if ok else 1)
PY
[[ $? -eq 0 ]] && ok "F3: minimal envelope {run,node,outcome} → auto-derive outputs(server-code,unit-tests)+agent+phase z grafu" \
  || bad "F3: auto-derive z grafu nesedí (outputs/agent/phase/time)"
python3 - <<'PY'
import yaml, re, sys
st = yaml.safe_load(re.search(r"```yaml\s*\n(.*?)\n```", open("current-run.md", encoding="utf-8").read(), re.S).group(1)) or {}
sys.exit(0 if "backend" in (st.get("completed") or []) else 1)
PY
[[ $? -eq 0 ]] && ok "F3: minimal envelope posunul stav (backend completed)" \
  || bad "F3: minimal envelope neposunul stav"
# explicitní outputs s path PŘEBIJÍ auto-derive → B1 path-check drží (phantom odmítnut)
printf '```yaml\nrun: f3btest\nstatus: in_progress\ncompleted: [intake, product, feasibility, architecture, db-schema]\noutcomes: {}\nfrontier: [backend]\n```\n' > current-run.md
printf 'run: f3btest\nnode: backend\noutcome: PASS\noutputs: [{type: server-code, path: nonexistent-xyz/}]\n' > _f3b.yaml
bash "$RUN" done _f3b.yaml >/dev/null 2>&1 \
  && bad "F3: explicitní phantom path NEodmítnut (B1 obejito auto-derivem)" \
  || ok "F3: explicitní outputs s path přebijí auto-derive → B1 phantom path odmítnut"
rm -f current-run.md _f3.yaml _f3b.yaml; rm -rf runs/f3test runs/f3btest

# ── F1: frontier computation (dataflow ready-rule) — regression guard ──
# Čistá funkce nad current-run+graf: ready = aktivní uzly se splněnými producenty.
# Guarduje fork-paralelitu (F5) i confluence barrier, nezávisle na drive (F2 přijde později).
frd() { bash "$RUN" next --emit frontier "$@" 2>/dev/null; }
rdnodes() { python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(x['node'] for x in d['ready']))"; }

printf '```yaml\ncompleted: []\noutcomes: {}\nfrontier: []\n```\n' > current-run.md
[[ "$(frd --class feature | rdnodes)" == "intake" ]] \
  && ok "frontier: fresh → ready=[intake]" || bad "frontier fresh"

# design_source politika (author|intake|derive) — routuje deterministicky, NE per-feature gate.
# „Kdo dodá mockup" je projektová politika; engine ji čte z flagu, člověk nedostává prompt.
printf '```yaml\ncompleted: [intake, product]\noutcomes: {intake: PASS, product: PASS}\nfrontier: []\n```\n' > current-run.md
FR="$(frd --class feature --flag has_ui=true --flag has_server=true --flag has_db=true --targets web | rdnodes)"
{ printf '%s' "$FR" | grep -q 'feasibility' && printf '%s' "$FR" | grep -qw 'ux-design' && ! printf '%s' "$FR" | grep -qw 'design-intake'; } \
  && ok "design_source author (default): fork tony ∥ ux-design, ŽÁDNÝ gate prompt [F5]" || bad "design_source author: [$FR]"
FR="$(frd --class feature --flag has_ui=true --flag has_server=true --flag has_db=true --flag design_source=intake --targets web | rdnodes)"
{ printf '%s' "$FR" | grep -qw 'design-intake' && ! printf '%s' "$FR" | grep -qw 'ux-design'; } \
  && ok "design_source intake: gate design-intake (upload), ux-design až po něm" || bad "design_source intake: [$FR]"
FR="$(frd --class feature --flag has_ui=true --flag has_server=true --flag has_db=true --flag design_source=derive --targets web | rdnodes)"
{ printf '%s' "$FR" | grep -qw 'ui-system' && ! printf '%s' "$FR" | grep -qw 'ux-design' && ! printf '%s' "$FR" | grep -qw 'design-intake'; } \
  && ok "design_source derive: product → ui-system (UI ze specu), ŽÁDNÁ ux-design ani gate" || bad "design_source derive: [$FR]"

# active_roles — aktivace gatuje ROLI (node-id), ne agenta (zpětně kompat s agents:). Deaktivace
# role v project-config → uzel inactive. (Engine routuje přes roli; agent je jen binding.)
printf '```yaml\ncompleted: [intake, product]\noutcomes: {intake: PASS, product: PASS}\nfrontier: []\n```\n' > current-run.md
printf '```yaml\nflags: { has_server: true, has_db: true, has_ui: false }\nactive_roles: { feasibility: inactive }\n```\n' > project-config.md
FR="$(frd --class feature | rdnodes)"
! printf '%s' "$FR" | grep -qw 'feasibility' \
  && ok "active_roles: role 'feasibility' inactive → uzel vyfiltrován (gating přes node-id/roli)" \
  || bad "active_roles deaktivace role nesedí (feasibility ready): [$FR]"
rm -f project-config.md

printf '```yaml\ncompleted: [intake, product, feasibility, architecture, ux-design]\noutcomes: {architecture: PASS}\nfrontier: []\n```\n' > current-run.md
FR="$(frd --class feature --flag has_ui=true --flag has_server=true --flag has_db=false --targets web | rdnodes)"
printf '%s' "$FR" | grep -qw 'web' \
  && bad "frontier confluence: web ready bez ui-system (barrier nedrží)" \
  || ok "frontier: confluence web čeká na architecture+ui-system [F5]"

# judged-skip (slabé místo #2): orchestrátor řekne „ui-system netřeba" → skip → web
# se odblokuje (ui-system vyloučen z peterových dep-edges), ui-system zmizí z judgment.
printf '```yaml\ncompleted: [intake, product, feasibility, architecture, ux-design]\noutcomes: {architecture: PASS, ux-design: PASS}\nfrontier: []\nskipped: [ui-system]\nflags: {has_ui: true}\n```\n' > current-run.md
FR="$(frd --class feature --flag has_ui=true --flag has_server=true --flag has_db=false --targets web | rdnodes)"
printf '%s' "$FR" | grep -qw 'web' \
  && ok "frontier skip: ui-system skipnut → web ready (judgment-skip odblokoval confluence)" \
  || bad "frontier skip: web zůstal blokovaný i po skip ui-system"
rm -f current-run.md

# ── E2: downward-closure self-heal → frontier order-independent (determinismus) ──
# Stale completed (backend completed, ale jeho producent architecture CHYBÍ — simuluje concurrent
# reflow+completion resurrection) → ready-rule backend zneplatní: qa (downstream) se NEspustí,
# místo toho se re-derivuje mezera (architecture ready). Bez self-healu by qa nesprávně prosákl.
printf '```yaml\ncompleted: [intake, product, feasibility, db-schema, backend]\noutcomes: {intake: PASS, product: PASS, feasibility: PASS, db-schema: PASS, backend: PASS}\nfrontier: []\nskipped: []\n```\n' > current-run.md
FR="$(frd --class feature --flag has_server=true --flag has_db=true --flag has_ui=false | rdnodes)"
{ printf '%s' "$FR" | grep -qw 'architecture' && ! printf '%s' "$FR" | grep -qw 'qa'; } \
  && ok "E2 self-heal: stale backend (architecture chybí) zneplatněn → architecture re-derived, qa NEready [order-indep]" \
  || bad "E2 self-heal: downward-closure nedrží (qa prosákl / architecture nere-derivován): [$FR]"
rm -f current-run.md

# ── B2: touches_db (feature-level DB flag, Ted) → read-only feature prořízne chandlera ──
# Static graf aktivuje chandlera na has_db; Ted (zodpovědný architekt) u read-only featury
# nastaví touches_db=false → db-schema odpadne, backend jde z architecture přímo (mine migrations). Runtime
# úsudek agenta přebíjí statický graf (zrcadlí B3). Default = has_db (fail-safe: db-schema běží).
printf '```yaml\ncompleted: [intake, product, feasibility, architecture]\noutcomes: {intake: PASS, product: PASS, feasibility: PASS, architecture: PASS}\nfrontier: []\nskipped: []\n```\n' > current-run.md
FR="$(frd --class feature --flag has_server=true --flag has_db=true --flag touches_db=false | rdnodes)"
{ printf '%s' "$FR" | grep -qw 'backend' && ! printf '%s' "$FR" | grep -qw 'db-schema'; } \
  && ok "B2: touches_db=false → db-schema prořezán, backend ready přímo z architecture (read-only feature)" \
  || bad "B2: touches_db=false routing nesedí (čekám backend, ne db-schema): [$FR]"
# backward-compat: touches_db nedeklarováno → default = has_db (true) → db-schema aktivní, backend čeká
FR="$(frd --class feature --flag has_server=true --flag has_db=true | rdnodes)"
{ printf '%s' "$FR" | grep -qw 'db-schema' && ! printf '%s' "$FR" | grep -qw 'backend'; } \
  && ok "B2: touches_db default=has_db → db-schema aktivní (backward-compat, backend čeká na migrations)" \
  || bad "B2: touches_db default nesedí (čekám db-schema, ne backend): [$FR]"
rm -f current-run.md

# ── Fáze 4: incremental rebuild naostro (verzová cesta staleness) ────────────────
# Konzistentní verzovaný completed stav (forward běh: epoch = pořadí dokončení; každý
# uzel orazítkoval své outputy). Mutace simuluje re-run a ověří SCOPED staleness.
allf() { python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(x['node'] for k in ('ready','judgment','waiting') for x in d[k]))"; }
BASE_TV='type_versions: {spec: 2, acceptance: 2, has_ui: 2, gate-output: 7, contract: 4, error-codes: 4, reuse-decision: 4, db-schema: 5, migrations: 5, server-code: 6, unit-tests: 6}'
BASE_NV='node_versions: {intake: 1, product: 2, feasibility: 3, architecture: 4, db-schema: 5, backend: 6, qa: 7}'

# (A) scoped re-flow — product re-run s changed:[spec] (doc-only): spec-konzumenti (architecture,
# db-schema, tony) STALE → re-scheduled; backend+qa (nečtou spec) ZŮSTÁVAJÍ completed. Jádro E1-depth.
printf '```yaml\nrun: scopetest\nstatus: in_progress\nclass: feature\nfrontier: [product]\ncompleted: [intake, feasibility, architecture, db-schema, backend, qa]\noutcomes: {intake: PASS, feasibility: PASS, architecture: PASS, db-schema: PASS, backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nflags: {has_server: true, has_db: true, has_ui: false}\nepoch: 7\n%s\n%s\n```\n' "$BASE_NV" "$BASE_TV" > current-run.md
printf 'run: scopetest\nnode: product\noutcome: PASS\nchanged: [spec]\noutputs: [{type: spec}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _sc.yaml
bash "$RUN" done _sc.yaml >/dev/null 2>&1
AF="$(frd --class feature --flag has_server=true --flag has_db=true --flag has_ui=false | allf)"
{ printf '%s' "$AF" | grep -qw 'architecture' && printf '%s' "$AF" | grep -qw 'db-schema' \
    && ! printf '%s' "$AF" | grep -qw 'qa' && ! printf '%s' "$AF" | grep -qw 'backend'; } \
  && ok "Fáze 4 (A) scoped re-flow: changed:[spec] → architecture/db-schema stale, qa/backend zůstávají (E1-depth fix)" \
  || bad "Fáze 4 (A) scoped re-flow: [$AF]"
rm -f current-run.md _sc.yaml

# (B) default-all — product re-run BEZ `changed` → default = graf outputy [spec,acceptance,has_ui]:
# bumpne i acceptance → qa (čte acceptance) STALE taky. Kontrast k (A) = plný re-flow (lazily).
printf '```yaml\nrun: deftest\nstatus: in_progress\nclass: feature\nfrontier: [product]\ncompleted: [intake, feasibility, architecture, db-schema, backend, qa]\noutcomes: {intake: PASS, feasibility: PASS, architecture: PASS, db-schema: PASS, backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nflags: {has_server: true, has_db: true, has_ui: false}\nepoch: 7\n%s\n%s\n```\n' "$BASE_NV" "$BASE_TV" > current-run.md
printf 'run: deftest\nnode: product\noutcome: PASS\noutputs: [{type: spec},{type: acceptance}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _df.yaml
bash "$RUN" done _df.yaml >/dev/null 2>&1
AF="$(frd --class feature --flag has_server=true --flag has_db=true --flag has_ui=false | allf)"
{ printf '%s' "$AF" | grep -qw 'architecture' && printf '%s' "$AF" | grep -qw 'qa'; } \
  && ok "Fáze 4 (B) default-all: product bez changed → bumpne acceptance → qa STALE taky (plný re-flow)" \
  || bad "Fáze 4 (B) default-all: qa nezestárl (default ≠ plný re-flow): [$AF]"
rm -f current-run.md _df.yaml

# (C) version order-independence — contract byl reprodukován (architecture re-run → contract v8). Jeho
# konzumenti db-schema(v5)+backend(v6) jsou STALE (8>verze) → re-scheduled (db-schema ready, backend čeká
# na chandlera) — tranzitivní cascade přes verze. qa (čte server-code v6, ne contract) ZŮSTÁVÁ
# — lazy. Bez ohledu na pořadí envelopů: monotonní verze → pozdě zpracovaná completion neresurektne.
printf '```yaml\nrun: oitest\nstatus: in_progress\nclass: feature\nfrontier: []\ncompleted: [intake, product, feasibility, architecture, db-schema, backend, qa]\noutcomes: {intake: PASS, product: PASS, feasibility: PASS, architecture: PASS, db-schema: PASS, backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nflags: {has_server: true, has_db: true, has_ui: false}\nepoch: 8\nnode_versions: {intake: 1, product: 2, feasibility: 3, architecture: 8, db-schema: 5, backend: 6, qa: 7}\ntype_versions: {spec: 2, acceptance: 2, has_ui: 2, gate-output: 7, contract: 8, error-codes: 8, reuse-decision: 8, db-schema: 5, migrations: 5, server-code: 6, unit-tests: 6}\n```\n' > current-run.md
AF="$(frd --class feature --flag has_server=true --flag has_db=true --flag has_ui=false | allf)"
{ printf '%s' "$AF" | grep -qw 'backend' && printf '%s' "$AF" | grep -qw 'db-schema' && ! printf '%s' "$AF" | grep -qw 'qa'; } \
  && ok "Fáze 4 (C) version order-indep: contract v8 → db-schema+backend stale (tranzitivně), qa zůstává (lazy)" \
  || bad "Fáze 4 (C) version order-indep: cascade přes verze nesedí: [$AF]"
rm -f current-run.md

# ── Fáze 4 (D): CLI frontier emit MUSÍ číst per-feature flagy z run-stavu ──────────
# Regression guard pro flag-leak bug (přesná reprodukce live nálezu): web-target projekt
# (active_targets.web), feature has_ui:false/touches_db:false s re-flow historií (verze).
# `next --emit frontier` BEZ explicitních --flag — flagy jdou JEN z run-stavu (jako live
# orchestrátor volá). Pre-fix CLI nemergoval st.flags → has_ui/touches_db UNKNOWN → flag-
# gated-off UI/DB uzly (ux-design/ui-system/web/db-schema/design-audit) LEAKLY do
# ready/waiting (web: targets.web=true && has_ui=UNKNOWN → UNKNOWN → uzel „aktivní").
# Po fixu has_ui=false → web `targets.web && has_ui` = FALSE → inactive; všechny pryč.
printf '```yaml\nflags: { has_deploy: false }\nactive_targets: { web: { backend: x, db: y } }\n```\n' > project-config.md
printf '```yaml\nrun: leaktest\nstatus: in_progress\nclass: feature\nactive_node: null\nfrontier: [devops]\ncompleted: [intake, product, feasibility, architecture, backend, qa]\noutcomes: {intake: PASS, product: PASS, feasibility: PASS, architecture: PASS, backend: PASS, qa: PASS}\nskipped: []\ncounters: {}\nawaiting_human: []\nflags: {has_ui: false, touches_db: false}\nepoch: 6\nnode_versions: {intake: 1, product: 2, feasibility: 3, architecture: 4, backend: 5, qa: 6}\ntype_versions: {spec: 2, acceptance: 2, has_ui: 2, contract: 4, server-code: 5}\n```\n' > current-run.md
AF="$(bash "$RUN" next --emit frontier 2>/dev/null | allf)"
{ ! printf '%s' "$AF" | grep -qw 'ux-design' && ! printf '%s' "$AF" | grep -qw 'ui-system' \
    && ! printf '%s' "$AF" | grep -qw 'web' && ! printf '%s' "$AF" | grep -qw 'db-schema' \
    && ! printf '%s' "$AF" | grep -qw 'design-audit'; } \
  && ok "Fáze 4 (D) flag-leak guard: CLI frontier čte st.flags → has_ui/touches_db:false → ŽÁDNÝ UI/DB uzel ve frontieru" \
  || bad "Fáze 4 (D) flag-leak: UI/DB uzly leakly do CLI frontieru (st.flags nemergovány): [$AF]"
# status.py transparency (Option 3): recompute frontier + stale-reopened + terminal_reached
ST="$(bash "$RUN" status 2>/dev/null)"
{ printf '%s' "$ST" | grep -q '^frontier-ready:' && printf '%s' "$ST" | grep -q '^stale-reopened:' \
    && printf '%s' "$ST" | grep -q '^terminal_reached:' \
    && ! printf '%s' "$ST" | grep -E '^frontier-ready:|^stale-reopened:' | grep -qw 'web'; } \
  && ok "Fáze 4 (D) status transparency: recompute tiskne frontier-ready/stale-reopened/terminal_reached (bez UI leaku)" \
  || bad "Fáze 4 (D) status transparency: chybí recompute řádky nebo UI leak: [$ST]"
rm -f current-run.md project-config.md

# ── Joey diagnostika (role fix): Joey FAIL routuje JEN na Teda, ne hádá vlastníka ──
# Joey je zkoušeč naslepo (vidí příznak, ne příčinu) → selhání diagnostikuje Ted (architekt).
JFAIL="$(bash "$RUN" next --from qa --outcome FAIL --emit json 2>/dev/null | python3 -c "import sys,json;print(','.join(sorted(c['node'] for c in json.load(sys.stdin)['candidates'])))")"
[[ "$JFAIL" == "architecture" ]] \
  && ok "Joey FAIL → jen Ted (diagnostik), žádné přímé hádání vlastníka" || bad "Joey FAIL routing: [$JFAIL] (čekáno: architecture)"

# ── Ted diagnostik: fault doména → graf přeloží na uzel (flow-blind routing) ──
# Ted jmenuje DOMÉNU vady (fault: db-schema), ne kolegu; result.sh resolve cíl z grafu → re-flow.
printf '```yaml\nrun: faulttest\nstatus: in_progress\nclass: feature\nactive_node: architecture\nfrontier: [architecture]\ncompleted: [intake, product, feasibility, architecture, db-schema, backend, qa]\noutcomes: {product: PASS, architecture: PASS}\nskipped: []\ncounters: {}\nflags: {has_server: true, has_db: true}\n```\n' > current-run.md
printf 'run: faulttest\nnode: architecture\noutcome: FAIL\nfault: db-schema\nsignature: chybi sloupec\noutputs: [{type: gate-output}]\ntime: { started: 2026-06-10T10:00:00Z, ended: 2026-06-10T10:01:00Z }\n' > _fa.yaml
bash "$RUN" done _fa.yaml >/dev/null 2>&1
CMP="$(bash "$RUN" status 2>/dev/null | grep '^completed:')"
{ ! printf '%s' "$CMP" | grep -qw 'db-schema' && grep -q 'architecture->db-schema' current-run.md; } \
  && ok "Ted fault=db-schema → re-flow na chandlera (doména→uzel přes graf, flow-blind)" || bad "Ted fault routing: [$CMP]"
rm -f current-run.md _fa.yaml

# ── target-gating: deklarované prázdné active_targets = backend-only → klienti OFF ──
# E2E nález: NEdeklarované active_targets → klient „unknown" → aktivní (spurious dispatch);
# deklarované-prázdné (i `{}`) je autoritativní → web/mobile/desktop vyfiltrovány.
printf '```yaml\nflags: { has_server: true, has_db: true }\nactive_targets: {}\n```\n' > project-config.md
printf '```yaml\ncompleted: [intake, product, feasibility, architecture, db-schema]\noutcomes: {architecture: PASS, db-schema: PASS}\nfrontier: []\nflags: {has_ui: false}\n```\n' > current-run.md
FR="$(frd --class feature | rdnodes)"
{ ! printf '%s' "$FR" | grep -qw 'web' && ! printf '%s' "$FR" | grep -qw 'mobile' && ! printf '%s' "$FR" | grep -qw 'desktop'; } \
  && ok "target-gating: declared active_targets:{} → klienti vyfiltrováni (backend-only)" \
  || bad "target-gating: klient prosákl i s declared-empty active_targets: [$FR]"
rm -f project-config.md current-run.md

bash "$RUN" check "$PIPELINE_GRAPH" >/dev/null 2>&1 \
  && ok "check graf C1–C12 OK" || bad "check"

# Negativní test: rozbitý graf musí spustit C11 (orphan) + C12 (requires) + C14 (neznámý flag/
# enum) + C15 (neznámý type/kind). vocabulary.yaml zkopírován k broken grafu (jinak C14/15 SKIP).
cp "$REPO/pipeline/vocabulary.yaml" vocabulary.yaml
python3 - "$PIPELINE_GRAPH" <<'PY'
import yaml, sys
g = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
g["nodes"]["audit-join"]["requires"].append("qa")          # C12: nadbytečný requires
g["nodes"]["ghost"] = {"type": "agent", "agent": "bob-backend", "phase": "T2"}
g["edges"].append({"from": "qa", "to": "ghost", "when": "FAIL", "kind": "return"})  # C11: jen return
g["nodes"]["badtype"] = {"type": "gateway"}                # C15: neznámý node type
g["edges"].append({"from": "product", "to": "badtype", "when": "has_databse"})       # C14: typo flag
g["edges"].append({"from": "product", "to": "badtype", "when": "design_source == authour"})  # C14: enum
g["edges"].append({"from": "product", "to": "badtype", "kind": "branch"})            # C15: neznámý kind
yaml.safe_dump(g, open("broken.yaml", "w"), sort_keys=False, allow_unicode=True)
PY
CHK="$(bash "$RUN" check broken.yaml 2>&1)"
{ printf '%s' "$CHK" | grep -q 'C11 dataflow-orphan' && printf '%s' "$CHK" | grep -q 'C12 audit-join'; } \
  && ok "check negativní: C11 (orphan) + C12 (requires divergence) chyceny" || bad "C11/C12 nezachytily rozbitý graf"
{ printf '%s' "$CHK" | grep -q 'has_databse' && printf '%s' "$CHK" | grep -q 'authour'; } \
  && ok "check negativní: C14 chytil typo flagu i neznámou enum hodnotu (fail-closed slovník)" || bad "C14 nechytil neznámý flag/hodnotu"
{ printf '%s' "$CHK" | grep -q "gateway" && printf '%s' "$CHK" | grep -q "kind 'branch'"; } \
  && ok "check negativní: C15 chytil neznámý node type i edge kind" || bad "C15 nechytil neznámý type/kind"
rm -f broken.yaml vocabulary.yaml

cd "$REPO"; rm -rf "$WORK"

# structure-check (S1–S4 PRODUCT-layer tvar) — běží z $REPO (cwd-relativní path/layout checky).
bash "$HERE/structure-check.sh" >/dev/null 2>&1 \
  && ok "structure-check: framework má správný PRODUCT-layer tvar (S1–S4)" || bad "structure-check framework neprošel"
SC_BROKEN="$(mktemp)"
sed 's/^  product: active/  ghost-role: active/' project-config.md > "$SC_BROKEN"
printf '%s' "$(bash "$HERE/structure-check.sh" "$SC_BROKEN" 2>&1)" | grep -q "neznámá role 'ghost-role'" \
  && ok "structure-check negativní: S4 chytil neznámou roli (∉ graf)" || bad "S4 nechytil neznámou roli"
rm -f "$SC_BROKEN"

# self-host-init: round-trip (TOOL přes symlinky, žádný PRODUCT → seed → structure-check projde).
SH_TMP="$(mktemp -d)"
( cd "$SH_TMP" && for m in constitution.md agents pipeline scripts templates; do ln -s "$REPO/$m" "$m"; done \
  && python3 "$REPO/scripts/pipeline/core/self_host_init.py" --name shtest >/dev/null 2>&1 \
  && python3 "$REPO/scripts/pipeline/core/structure_check.py" >/dev/null 2>&1 )
[ $? -eq 0 ] && ok "self-host-init: seed PRODUCT vrstvy → structure-check projde (round-trip)" || bad "self-host-init round-trip selhal"
rm -rf "$SH_TMP"

echo "== $([ $FAILS -eq 0 ] && echo 'VŠE PROŠLO' || echo "$FAILS SELHALO") =="
exit $([ $FAILS -eq 0 ] && echo 0 || echo 1)
