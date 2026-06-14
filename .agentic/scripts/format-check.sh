#!/usr/bin/env bash
# format-check.sh — deterministická kontrola formátu + style-lintu per stack.
#
# MECHANISMUS (constitution I4: mechanická konzistence scriptem, ne LLM). Vitek gate
# ji spustí; non-zero = porušení → implementátor pustí `--fix` (taky script). Detekuje
# přítomné stacky a pustí jejich nástroje v CHECK módu:
#   python (ruff) · TS/JS (prettier + eslint) · dart (dart format + analyze) · java (spotless)
#
# Usage: bash .agentic/scripts/format-check.sh [--root DIR] [--fix]
# Exit:  0 = čisto | 1 = nález | 2 = chyba
set -uo pipefail
ROOT="$PWD"; FIX=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2;;
    --fix)  FIX=1; shift;;
    *) echo "Neznámý argument: $1" >&2; exit 2;;
  esac
done
cd "$ROOT" || exit 2
fails=0
RUFF="ruff"; command -v ruff >/dev/null 2>&1 || RUFF="python3 -m ruff"   # PATH nebo modul

# ── python (ruff) ──
while IFS= read -r d; do
  [[ -n "$d" ]] || continue
  echo "[python] $d"
  if [[ $FIX -eq 1 ]]; then (cd "$d" && $RUFF format . && $RUFF check --fix .) || fails=$((fails + 1))
  else (cd "$d" && $RUFF format --check . && $RUFF check .) || fails=$((fails + 1)); fi
done < <(find . -name pyproject.toml -not -path '*/node_modules/*' -not -path '*/.venv/*' -exec dirname {} \; | sort -u)

# ── TS/JS (prettier + eslint) ──
while IFS= read -r d; do
  [[ -n "$d" ]] || continue
  [[ -f "$d/.prettierrc.json" || -f "$d/eslint.config.mjs" ]] || continue
  echo "[ts] $d"
  if [[ $FIX -eq 1 ]]; then (cd "$d" && npx prettier --write "src/**/*.{ts,tsx}" && npx eslint .) || fails=$((fails + 1))
  else (cd "$d" && npx prettier --check "src/**/*.{ts,tsx}" && npx eslint .) || fails=$((fails + 1)); fi
done < <(find . -name package.json -not -path '*/node_modules/*' -exec dirname {} \; | sort -u)

# ── dart/flutter ──
while IFS= read -r d; do
  [[ -n "$d" ]] || continue
  echo "[dart] $d"
  if [[ $FIX -eq 1 ]]; then (cd "$d" && dart format .) || fails=$((fails + 1))
  else (cd "$d" && dart format --output=none --set-exit-if-changed . && dart analyze) || fails=$((fails + 1)); fi
done < <(find . -name pubspec.yaml -not -path '*/.dart_tool/*' -exec dirname {} \; | sort -u)

# ── java (gradle spotless) ──
while IFS= read -r d; do
  [[ -n "$d" ]] || continue
  [[ -f "$d/gradlew" ]] || continue
  echo "[java] $d"
  if [[ $FIX -eq 1 ]]; then (cd "$d" && ./gradlew spotlessApply -q) || fails=$((fails + 1))
  else (cd "$d" && ./gradlew spotlessCheck -q) || fails=$((fails + 1)); fi
done < <(find . -name build.gradle -not -path '*/build/*' -exec dirname {} \; | sort -u)

echo "format-check: fails=$fails"
[[ $fails -eq 0 ]]
