#!/usr/bin/env bash
# agent-graph-check.sh — Ověří základní integritu agent definic (Eywa tool).
#
# Kontroly (automatizované):
#   1) Každý agent soubor existuje fyzicky v agents/
#   2) Frontmatter má povinná pole (name, role, short, transformations, cache_key)
#   3) Žádné dvě agent definice nemají stejný short
#
# Kontroly MIMO tento script (dělá Eywa sémantickou analýzou):
#   4) Write scope konflikty (dva agenti do stejné cesty) — vyžaduje parsing
#   5) Dosažitelnost handoff targetů — vyžaduje sémantický dispatch parsing
#
# Usage: scripts/agent-graph-check.sh
#
# Spouští se z root projektu (kde je .agentic/) nebo přímo z dream-team/.

set -euo pipefail

AGENTS_DIR=".agentic/agents"
if [[ ! -d "$AGENTS_DIR" ]]; then
  AGENTS_DIR="agents"
  if [[ ! -d "$AGENTS_DIR" ]]; then
    echo "agents/ folder not found" >&2
    exit 2
  fi
fi

found=0
shorts=()

# Iterate agent files (skip INDEX.md)
for f in "$AGENTS_DIR"/*.md; do
  base=$(basename "$f")
  if [[ "$base" == "INDEX.md" ]]; then continue; fi

  # Extract short from frontmatter
  short=$(awk '/^short:/ { print $2; exit }' "$f")
  name=$(awk '/^name:/ { sub(/^name: /, ""); print; exit }' "$f")

  if [[ -z "$short" ]]; then
    echo "WARN: $f has no 'short:' in frontmatter"
    found=1
  fi

  # Check duplicate shorts
  for existing in "${shorts[@]}"; do
    if [[ "$existing" == "$short" ]]; then
      echo "FAIL: duplicate short '$short' in $f"
      found=1
    fi
  done
  shorts+=("$short")

  # Check required frontmatter fields
  for field in role transformations cache_key; do
    if ! grep -q "^${field}:" "$f"; then
      echo "WARN: $f missing frontmatter field '$field'"
      found=1
    fi
  done
done

echo "---"
echo "Agents checked: ${#shorts[@]}"
echo "Shorts: ${shorts[*]}"

if (( found == 0 )); then
  echo "agent-graph: OK"
  exit 0
else
  echo "agent-graph: FINDINGS"
  exit 1
fi
