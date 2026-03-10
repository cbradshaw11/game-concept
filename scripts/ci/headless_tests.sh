#!/usr/bin/env bash
set -euo pipefail

echo "[headless-tests] Starting"

if command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path game -s res://scripts/tests/replay_test.gd
  godot4 --headless --path game -s res://scripts/tests/encounter_templates_test.gd
  godot4 --headless --path game -s res://scripts/tests/enemy_state_test.gd
  godot4 --headless --path game -s res://scripts/tests/progression_integrity_test.gd
  godot4 --headless --path game -s res://scripts/tests/reward_scaling_test.gd
  godot4 --headless --path game -s res://scripts/tests/save_load_integrity_test.gd
  godot4 --headless --path game -s res://scripts/tests/combat_arena_scene_test.gd
  godot4 --headless --path game -s res://scripts/tests/combat_hooks_test.gd
  godot4 --headless --path game -s res://scripts/tests/contract_system_test.gd
else
  echo "godot4 not found in runner. Performing structural checks only."
  test -f game/scripts/tests/replay_test.gd
  test -f game/scripts/tests/encounter_templates_test.gd
  test -f game/scripts/tests/enemy_state_test.gd
  test -f game/scripts/tests/progression_integrity_test.gd
  test -f game/scripts/tests/reward_scaling_test.gd
  test -f game/scripts/tests/save_load_integrity_test.gd
  test -f game/scripts/tests/combat_arena_scene_test.gd
  test -f game/scripts/tests/combat_hooks_test.gd
  test -f game/scripts/tests/contract_system_test.gd
fi

echo "[headless-tests] Complete"
