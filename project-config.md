---
cache_key: project-config-unagy-web-v1.0
framework_version: "0.37.0"
last_updated: 2026-06-14
spec_language: cs
code_language: en
status: SKELETON_NEEDS_WATSON
---

# Project Config — unagy-web

> Auto-generated skeleton. Spusť Watson pro vyplnění:
> `Agent(subagent_type="watson-interviewer", prompt="Refinovat project-config interview módem.")`

## Projekt
```yaml
project_name: unagy-web
project_type: TODO     # greenfield | transition
vision: TODO
stage: TODO
```

## Targets
```yaml
active_targets: {}     # TODO: Watson vyplní dle detekovaného stacku
```

## Active agents
```yaml
# Watson doporučí profil dle složitosti (viz .agentic/agents/INDEX.md
# §Activation profily). Profil = startovní set; vypnutý agent NENÍ smazaný,
# zapne se až ho projekt potřebuje. Default skeleton = standard.
profile: standard            # solo | standard | full
agents:
  vision-po: active
  ted-architect: active
  bob-backend: active
  peter-web: active          # jen pokud web target
  joey-qa: active
  heimdall-security: active
  vitek-quality: active
  sheldon-spec: active
  tony-cto: active
  chandler-db: active        # jen pokud DB
  leonard-ui: active
  alfred-devops: active      # jen pokud deploy
  watson-interviewer: pending
  # off by default ve standard (zapni když projekt potřebuje):
  optimus-perf: inactive
  denisa-ux: inactive
  edna-design: inactive
  eywa-meta: inactive
  mob-mobile: inactive       # jen pokud mobile target
  winny-desktop: inactive    # jen pokud desktop target
```

## Fyzické cesty (logical → physical)
```yaml
# Default: vše v rootu projektu (NE v .agentic — to je jen framework).
project_constitution: PROJECT-CONSTITUTION.md
specs: specs/
contracts: contracts/
rules: rules/
stack: stack/
backlog: backlog/
acceptance: acceptance/
design: design/
improvements: improvements/
status: status/
handoffs: handoffs/
audit: audit/
project_state: STATE.md
# Watson upraví dle reálné struktury.
```
