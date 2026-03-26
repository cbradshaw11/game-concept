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
  godot4 --headless --path game -s res://scripts/tests/combat_smoke_test.gd
  godot4 --headless --path game -s res://scripts/tests/combat_arena_scene_test.gd
  godot4 --headless --path game -s res://scripts/tests/combat_hooks_test.gd
  godot4 --headless --path game -s res://scripts/tests/contract_system_test.gd
  godot4 --headless --path game -s res://scripts/tests/telemetry_lifecycle_test.gd
  # M17 Narrative Layer
  godot4 --headless --path game -s res://scripts/tests/m17/m17_narrative_json_structure_test.gd
  godot4 --headless --path game -s res://scripts/tests/m17/m17_narrative_manager_load_test.gd
  godot4 --headless --path game -s res://scripts/tests/m17/m17_narrative_api_test.gd
  godot4 --headless --path game -s res://scripts/tests/m17/m17_lore_fragments_test.gd
  godot4 --headless --path game -s res://scripts/tests/m17/m17_warden_intro_test.gd
  godot4 --headless --path game -s res://scripts/tests/m17/m17_prologue_hooks_test.gd
  # M18 Ring 3 + Warden Boss
  godot4 --headless --path game -s res://scripts/tests/m18/m18_warden_phase_test.gd
  godot4 --headless --path game -s res://scripts/tests/m18/m18_boss_gate_test.gd
  godot4 --headless --path game -s res://scripts/tests/m18/m18_artifact_victory_test.gd
  # M19 Combat Juice & Feel Polish
  godot4 --headless --path game -s res://scripts/tests/m19/hit_feedback_test.gd
  godot4 --headless --path game -s res://scripts/tests/m19/phase_transition_test.gd
  godot4 --headless --path game -s res://scripts/tests/m19/death_screen_test.gd
  # M20 Title Screen & Onboarding
  godot4 --headless --path game -s res://scripts/tests/m20/title_screen_test.gd
  godot4 --headless --path game -s res://scripts/tests/m20/onboarding_flow_test.gd
  godot4 --headless --path game -s res://scripts/tests/m20/how_to_play_test.gd
  # M21 Run Summary & Stats Tracking
  godot4 --headless --path game -s res://scripts/tests/m21/run_stats_test.gd
  godot4 --headless --path game -s res://scripts/tests/m21/run_summary_test.gd
  godot4 --headless --path game -s res://scripts/tests/m21/personal_best_test.gd
  # M22 Upgrade Shop Polish & Economy Balance
  godot4 --headless --path game -s res://scripts/tests/m22/upgrade_data_test.gd
  godot4 --headless --path game -s res://scripts/tests/m22/economy_balance_test.gd
  godot4 --headless --path game -s res://scripts/tests/m22/shop_ui_test.gd
  # M23 Lore Fragment Pickups
  godot4 --headless --path game -s res://scripts/tests/m23/fragment_drop_test.gd
  godot4 --headless --path game -s res://scripts/tests/m23/fragment_state_test.gd
  godot4 --headless --path game -s res://scripts/tests/m23/fragment_ui_test.gd
  # M31 Challenge Runs
  godot4 --headless --path game -s res://scripts/tests/m31/challenge_data_test.gd
  godot4 --headless --path game -s res://scripts/tests/m31/challenge_unlock_test.gd
  godot4 --headless --path game -s res://scripts/tests/m31/challenge_enforcement_test.gd
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
  # M17 Narrative Layer
  test -f game/scripts/tests/m17/m17_narrative_json_structure_test.gd
  test -f game/scripts/tests/m17/m17_narrative_manager_load_test.gd
  test -f game/scripts/tests/m17/m17_narrative_api_test.gd
  test -f game/scripts/tests/m17/m17_lore_fragments_test.gd
  test -f game/scripts/tests/m17/m17_warden_intro_test.gd
  test -f game/scripts/tests/m17/m17_prologue_hooks_test.gd
  # M18 Ring 3 + Warden Boss
  test -f game/scripts/tests/m18/m18_warden_phase_test.gd
  test -f game/scripts/tests/m18/m18_boss_gate_test.gd
  test -f game/scripts/tests/m18/m18_artifact_victory_test.gd
  # M19 Combat Juice & Feel Polish
  test -f game/scripts/tests/m19/hit_feedback_test.gd
  test -f game/scripts/tests/m19/phase_transition_test.gd
  test -f game/scripts/tests/m19/death_screen_test.gd
  # M20 Title Screen & Onboarding
  test -f game/scripts/tests/m20/title_screen_test.gd
  test -f game/scripts/tests/m20/onboarding_flow_test.gd
  test -f game/scripts/tests/m20/how_to_play_test.gd
  # M21 Run Summary & Stats Tracking
  test -f game/scripts/tests/m21/run_stats_test.gd
  test -f game/scripts/tests/m21/run_summary_test.gd
  test -f game/scripts/tests/m21/personal_best_test.gd
  # M22 Upgrade Shop Polish & Economy Balance
  test -f game/scripts/tests/m22/upgrade_data_test.gd
  test -f game/scripts/tests/m22/economy_balance_test.gd
  test -f game/scripts/tests/m22/shop_ui_test.gd
  # M23 Lore Fragment Pickups
  test -f game/scripts/tests/m23/fragment_drop_test.gd
  test -f game/scripts/tests/m23/fragment_state_test.gd
  test -f game/scripts/tests/m23/fragment_ui_test.gd
  # M31 Challenge Runs
  test -f game/scripts/tests/m31/challenge_data_test.gd
  test -f game/scripts/tests/m31/challenge_unlock_test.gd
  test -f game/scripts/tests/m31/challenge_enforcement_test.gd
fi

echo "[headless-tests] Complete"
