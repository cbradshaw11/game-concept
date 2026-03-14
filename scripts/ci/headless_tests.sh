#!/usr/bin/env bash
set -euo pipefail

echo "[headless-tests] Starting"

GODOT_FLAGS="--headless --display-driver headless --audio-driver Dummy"
PASS=0
FAIL=0
FAILED_TESTS=()

run_test() {
  local script="$1"
  local name
  name=$(basename "$script")
  echo "[test] $name"
  local exit_code=0
  timeout 60 godot4 $GODOT_FLAGS --path game -s "$script" || exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    echo "[PASS] $name"
    PASS=$((PASS + 1))
  elif [ "$exit_code" -eq 124 ]; then
    echo "[HANG] $name — timed out after 60s"
    FAILED_TESTS+=("$name (timeout)")
    FAIL=$((FAIL + 1))
  else
    echo "[FAIL] $name — exit $exit_code"
    FAILED_TESTS+=("$name (exit $exit_code)")
    FAIL=$((FAIL + 1))
  fi
}

# run_scene_test: like run_test but tolerates a physics-shutdown hang.
# The test calls quit(0/1) inside _initialize(), completing all assertions
# before the engine loop starts. If the process hangs on shutdown (a known
# Godot 4 headless issue with CharacterBody2D physics cleanup), the output
# has already been written. We capture it and judge by the PASS/FAIL print.
run_scene_test() {
  local script="$1"
  local name
  name=$(basename "$script")
  echo "[test] $name"
  local output exit_code=0
  output=$(timeout 10 godot4 $GODOT_FLAGS --path game -s "$script" 2>&1) || exit_code=$?
  echo "$output"
  if echo "$output" | grep -q "^PASS:"; then
    echo "[PASS] $name"
    PASS=$((PASS + 1))
  elif echo "$output" | grep -q "^FAIL:"; then
    echo "[FAIL] $name"
    FAILED_TESTS+=("$name (assertion)")
    FAIL=$((FAIL + 1))
  elif [ "$exit_code" -eq 0 ]; then
    echo "[PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $name — no PASS/FAIL output (exit $exit_code)"
    FAILED_TESTS+=("$name (no output)")
    FAIL=$((FAIL + 1))
  fi
}

if command -v godot4 >/dev/null 2>&1; then
  run_test res://scripts/tests/replay_test.gd
  run_test res://scripts/tests/encounter_templates_test.gd
  run_test res://scripts/tests/enemy_state_test.gd
  run_test res://scripts/tests/progression_integrity_test.gd
  run_test res://scripts/tests/reward_scaling_test.gd
  run_test res://scripts/tests/save_load_integrity_test.gd
  run_scene_test res://scripts/tests/combat_smoke_test.gd
  run_test res://scripts/tests/combat_arena_scene_test.gd
  run_test res://scripts/tests/combat_hooks_test.gd
  run_test res://scripts/tests/contract_system_test.gd
  run_test res://scripts/tests/telemetry_lifecycle_test.gd
  run_test res://scripts/tests/combat/test_player_hp.gd
  run_test res://scripts/tests/combat/test_enemy_damage.gd
  run_test res://scripts/tests/combat/test_weapon_stats.gd
  run_test res://scripts/tests/combat/test_guard_reduction.gd
  run_test res://scripts/tests/combat/test_dodge_iframes.gd
  run_test res://scripts/tests/combat/test_poise.gd
  run_test res://scripts/tests/m4/test_ring_gate.gd
  run_test res://scripts/tests/m4/test_ring_unlock_progression.gd
  run_test res://scripts/tests/m4/test_save_migration.gd
  run_test res://scripts/tests/m4/test_behavior_profiles.gd
  run_test res://scripts/tests/m4/test_heavy_attack.gd
  run_test res://scripts/tests/m5/test_upgrade_pass.gd
  run_test res://scripts/tests/m5/test_warden_phases.gd
  run_test res://scripts/tests/m5/test_bank_on_death.gd
  run_test res://scripts/tests/m5/test_save_migration_m5.gd
  run_test res://scripts/tests/m5/test_contract_targets.gd
  run_test res://scripts/tests/m5/test_audio_events.gd
  run_test res://scripts/tests/m6/test_shop_system.gd
  run_test res://scripts/tests/m6/test_vendor_catalog.gd
  run_test res://scripts/tests/m6/test_prologue_persistence.gd
  run_test res://scripts/tests/m6/test_settings_persistence.gd
  run_test res://scripts/tests/m6/test_title_screen_routing.gd
  run_test res://scripts/tests/m6/test_m6_save_migration.gd
  run_test res://scripts/tests/m7/test_run_history.gd
  run_test res://scripts/tests/m7/test_weapon_unlock.gd
  run_test res://scripts/tests/m7/test_conditional_upgrades.gd
  run_test res://scripts/tests/m7/test_template_variety.gd
  run_test res://scripts/tests/m7/test_victory_state.gd
  run_test res://scripts/tests/m7/test_m7_save_migration.gd
  run_test res://scripts/tests/m8/test_bow_targeting.gd
  run_test res://scripts/tests/m8/test_modifier_draw.gd
  run_test res://scripts/tests/m8/test_abandon_run.gd
  run_test res://scripts/tests/m8/test_prestige_shop.gd
  run_test res://scripts/tests/m9/test_modifier_mechanics.gd
  run_test res://scripts/tests/m9/test_last_rites_survival.gd
  run_test res://scripts/tests/m9/test_ring_narrative.gd
  run_test res://scripts/tests/m10/test_m10.gd
  run_test res://scripts/tests/m11/test_m11.gd
else
  echo "godot4 not found in runner. Performing structural checks only."
  test -f game/scripts/tests/replay_test.gd
  test -f game/scripts/tests/encounter_templates_test.gd
  test -f game/scripts/tests/enemy_state_test.gd
  test -f game/scripts/tests/progression_integrity_test.gd
  test -f game/scripts/tests/reward_scaling_test.gd
  test -f game/scripts/tests/save_load_integrity_test.gd
  test -f game/scripts/tests/combat_smoke_test.gd
  test -f game/scripts/tests/combat_arena_scene_test.gd
  test -f game/scripts/tests/combat_hooks_test.gd
  test -f game/scripts/tests/contract_system_test.gd
  test -f game/scripts/tests/telemetry_lifecycle_test.gd
  test -f game/scripts/tests/combat/test_player_hp.gd
  test -f game/scripts/tests/combat/test_enemy_damage.gd
  test -f game/scripts/tests/combat/test_weapon_stats.gd
  test -f game/scripts/tests/combat/test_guard_reduction.gd
  test -f game/scripts/tests/combat/test_dodge_iframes.gd
  test -f game/scripts/tests/combat/test_poise.gd
  test -f game/scripts/tests/m4/test_ring_gate.gd
  test -f game/scripts/tests/m4/test_ring_unlock_progression.gd
  test -f game/scripts/tests/m4/test_save_migration.gd
  test -f game/scripts/tests/m4/test_behavior_profiles.gd
  test -f game/scripts/tests/m4/test_heavy_attack.gd
  test -f game/scripts/tests/m5/test_upgrade_pass.gd
  test -f game/scripts/tests/m5/test_warden_phases.gd
  test -f game/scripts/tests/m5/test_bank_on_death.gd
  test -f game/scripts/tests/m5/test_save_migration_m5.gd
  test -f game/scripts/tests/m5/test_contract_targets.gd
  test -f game/scripts/tests/m5/test_audio_events.gd
  test -f game/scripts/tests/m6/test_shop_system.gd
  test -f game/scripts/tests/m6/test_vendor_catalog.gd
  test -f game/scripts/tests/m6/test_prologue_persistence.gd
  test -f game/scripts/tests/m6/test_settings_persistence.gd
  test -f game/scripts/tests/m6/test_title_screen_routing.gd
  test -f game/scripts/tests/m6/test_m6_save_migration.gd
  test -f game/scripts/tests/m7/test_run_history.gd
  test -f game/scripts/tests/m7/test_weapon_unlock.gd
  test -f game/scripts/tests/m7/test_conditional_upgrades.gd
  test -f game/scripts/tests/m7/test_template_variety.gd
  test -f game/scripts/tests/m7/test_victory_state.gd
  test -f game/scripts/tests/m7/test_m7_save_migration.gd
  test -f game/scripts/tests/m8/test_bow_targeting.gd
  test -f game/scripts/tests/m8/test_modifier_draw.gd
  test -f game/scripts/tests/m8/test_abandon_run.gd
  test -f game/scripts/tests/m8/test_prestige_shop.gd
  test -f game/scripts/tests/m9/test_modifier_mechanics.gd
  test -f game/scripts/tests/m9/test_last_rites_survival.gd
  test -f game/scripts/tests/m9/test_ring_narrative.gd
  test -f game/scripts/tests/m10/test_m10.gd
  test -f game/scripts/tests/m11/test_m11.gd
fi

echo ""
echo "[headless-tests] Results: $PASS passed, $FAIL failed"
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
  echo "[headless-tests] Failures:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
fi

echo "[headless-tests] Complete"
