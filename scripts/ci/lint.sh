#!/usr/bin/env bash
set -euo pipefail

echo "[lint] Starting"

# Basic repository hygiene checks.
if rg -n "\s+$" game mvp design decisions .github >/tmp/trailing_ws.txt; then
  echo "Trailing whitespace detected:"
  cat /tmp/trailing_ws.txt
  exit 1
fi

# Ensure shell scripts are executable when present.
for f in scripts/ci/*.sh; do
  test -x "$f"
done

echo "[lint] Complete"
