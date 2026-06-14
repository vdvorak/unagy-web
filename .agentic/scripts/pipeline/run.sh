#!/usr/bin/env bash
# run.sh — tenký shim na core/run.py (logika tam). Jednotný vstup do runneru:
# start/active/skip/status/next/drive/done/summary/check/scaffold.
exec python3 "$(dirname "${BASH_SOURCE[0]}")/core/run.py" "$@"
