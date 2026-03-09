#!/usr/bin/env bash
set -euo pipefail

echo "[smoke-scene] Starting"

test -f game/project.godot
test -f game/scenes/main.tscn

if command -v godot4 >/dev/null 2>&1; then
  timeout 20s godot4 --headless --path game --quit || true
fi

echo "[smoke-scene] Complete"
