#!/usr/bin/env bash
# model-usage.sh — agreguje model-routing log: kde reálně tečou tokeny.
#
# Čte status/model-routing-log.md (orchestrátor ho plní per dispatch — viz
# flow.md §Model routing). Formát datového řádku:
#   YYYY-MM-DD | <wave> | <agent> | <tier> | <model> | <note>
#
# Usage: bash .agentic/scripts/model-usage.sh [cesta-k-logu]
set -euo pipefail

LOG="${1:-status/model-routing-log.md}"

if [[ ! -f "$LOG" ]]; then
  echo "Log nenalezen: $LOG"
  echo "Orchestrátor ho plní per dispatch (flow.md §Model routing). Zatím prázdno."
  exit 0
fi

rows=$(grep -E '^[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*\|' "$LOG" || true)
n=$(printf '%s\n' "$rows" | grep -c . || true)

echo "= Model routing usage ($LOG) ="
echo "dispatchů celkem: $n"
[[ "$n" -eq 0 ]] && exit 0

echo
echo "-- podle modelu --"
printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$5); c[$5]++} END{for(m in c) printf "  %-8s %d\n", m, c[m]}' | sort

echo
echo "-- podle tieru --"
printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$4); c[$4]++} END{for(t in c) printf "  %-4s %d\n", t, c[t]}' | sort

echo
echo "-- relativní cena (haiku=1, sonnet=3, opus=15) --"
printf '%s\n' "$rows" | awk -F'|' '
  {gsub(/ /,"",$5); w=($5=="opus"?15:($5=="sonnet"?3:($5=="haiku"?1:0))); sum+=w; tot++}
  END{ base=tot*15;
       printf "  ~%d jednotek (kdyby vše opus: %d → úspora ~%d%%)\n", sum, base, (base>0?100-(sum*100/base):0) }'
