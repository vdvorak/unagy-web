---
cache_key: project-config-unagy-web-v1.0
framework_version: "0.37.0"
last_updated: 2026-06-14
spec_language: cs
code_language: en
status: ready
---

# Project Config — unagy-web

## Projekt
```yaml
project_name: unagy-web
project_type: greenfield
vision: >
  Statický landing/referenční web pro mobilní aplikaci Unagy na doméně unagy.cz.
  Obsahuje reference, QR kódy na stažení z Google Play a App Store a odkaz na
  webovou verzi aplikace na app.unagy.cz.
stage: greenfield
```

## Targets
```yaml
active_targets:
  web: static-html   # čisté HTML/CSS, žádný build tool, GitHub Pages + custom doména unagy.cz
```

## Stack
```yaml
frontend: plain HTML/CSS
build_tool: none         # soubory se commitují přesně tak, jak se servírují
hosting: GitHub Pages
domain: unagy.cz
containerized: false
```

## Flags
```yaml
design_source: derive    # solo dev; peter-web staví UI rovnou ze specu, žádný mockup
```

## Active agents
```yaml
profile: solo
agents:
  vision-po: active         # spec autorita / Product Owner
  ted-architect: active     # struktura projektu, HTML architektura
  peter-web: active         # implementace HTML/CSS
  joey-qa: active           # funkční testy (alespoň smoke)
  heimdall-security: active # security (CSP, HTTPS, external links)
  vitek-quality: active     # code quality auditor
  alfred-devops: active     # GitHub Actions / GitHub Pages deploy

  # inactive — žádný backend, žádná DB, žádný design systém
  bob-backend: inactive     # no server
  chandler-db: inactive     # no DB
  leonard-ui: inactive      # design systém je přestřel pro jednoduchý landing
  sheldon-spec: inactive    # solo, bez spec auditu (zapnout při potřebě)
  tony-cto: inactive        # solo, Tony zastupuje uživatel sám
  denisa-ux: inactive       # žádný UX mockup (derive mode)
  edna-design: inactive     # žádný design audit
  optimus-perf: inactive    # statický web, perf není priorita
  mob-mobile: inactive      # no mobile target
  winny-desktop: inactive   # no desktop target
  eywa-meta: inactive       # no agent changes planned
  watson-interviewer: pending
```

## Fyzické cesty (logical → physical)
```yaml
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
```
