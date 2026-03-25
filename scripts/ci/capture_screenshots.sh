#!/usr/bin/env bash
# capture_screenshots.sh — run all screen captures headlessly and save to /tmp/game_screenshots/
# Usage: bash scripts/ci/capture_screenshots.sh

set -euo pipefail

echo "[screenshots] Starting capture run"

mkdir -p /tmp/game_screenshots

godot4 --headless --path game -s res://scripts/tools/screenshot_capture.gd

echo "[screenshots] Done. Files in /tmp/game_screenshots/"
ls -lh /tmp/game_screenshots/
