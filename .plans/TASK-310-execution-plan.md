# TASK-310 Execution Plan: Full Combat Loop Test Suite

## Goal
Consolidate all 6 combat model test files into `game/scripts/tests/combat/`. Update headless_tests.sh to include new paths. Verify all pass with no M2 regressions.

## Depends on: TASK-301 through TASK-306 (all combat system implementations)

## Test file pattern (from existing M2 tests)
```gdscript
extends SceneTree

func _initialize() -> void:
    # setup
    # assert conditions
    if condition_met:
        quit(0)  # PASS
    else:
        print("FAIL: reason")
        quit(1)  # FAIL
```

## Files to create (6 new test files)

### game/scripts/tests/combat/test_player_hp.gd
Tests:
1. `take_damage()` reduces current_health by amount
2. Two damage events summing to > max_health → `player_died` fires
3. After `player_died`, GameState.unbanked_xp resets (connect to die_in_run)

### game/scripts/tests/combat/test_enemy_damage.gd
Tests:
1. EnemyController with known damage emits `attack_resolved(damage_amount)`
2. CombatArena wires attack_resolved → `_apply_damage_to_player()`
3. Player HP delta after enemy attack = enemy.damage

### game/scripts/tests/combat/test_weapon_stats.gd
Tests:
1. GameState.selected_weapon_id = "blade_iron" → combat_arena uses 14 damage
2. GameState.selected_weapon_id = "polearm_iron" → combat_arena uses 12 damage
3. GameState.selected_weapon_id = "bow_iron" → combat_arena uses 11 damage
4. No hardcoded 40 in damage path

### game/scripts/tests/combat/test_guard_reduction.gd
Tests:
1. guarding = true, take_damage(20) → HP loss < 20 (guard efficiency applied)
2. guarding = false, take_damage(20) → HP loss = 20 exactly
3. guarding = true, take_damage > GUARD_BREAK_THRESHOLD → guard_broken signal fires

### game/scripts/tests/combat/test_dodge_iframes.gd
Tests:
1. Trigger dodge, immediately call take_damage → HP unchanged, attack_evaded fires
2. Wait > iframe_duration after dodge, call take_damage → HP reduced
3. Two rapid dodges → second dodge blocked by cooldown

### game/scripts/tests/combat/test_poise.gd
Tests:
1. take_poise_damage() reduces current_poise
2. current_poise → 0 fires player_staggered
3. After stagger_duration, current_poise restored to max_poise

## headless_tests.sh update
File: `scripts/ci/headless_tests.sh`

Add 6 new test file paths to the test runner list:
```bash
TESTS=(
    # ... existing M2 tests ...
    "game/scripts/tests/combat/test_player_hp.gd"
    "game/scripts/tests/combat/test_enemy_damage.gd"
    "game/scripts/tests/combat/test_weapon_stats.gd"
    "game/scripts/tests/combat/test_guard_reduction.gd"
    "game/scripts/tests/combat/test_dodge_iframes.gd"
    "game/scripts/tests/combat/test_poise.gd"
)
```

(Check existing headless_tests.sh format — it may use a for loop or explicit godot calls per file)

## Verification Commands
```bash
ls game/scripts/tests/combat/
bash scripts/ci/headless_tests.sh 2>&1 | tail -5
bash scripts/ci/headless_tests.sh 2>&1 | grep -c FAIL || echo "0 failures"
```

## Key Files
- `game/scripts/tests/combat/` (create directory + 6 test files)
- `scripts/ci/headless_tests.sh` (add new test paths)
- `game/scripts/tests/` (read-only — existing M2 tests for pattern reference)

## Acceptance Criteria
- 6 new test files exist in game/scripts/tests/combat/
- All combat tests pass in CI headless run
- No regression on existing M2 test files (0 FAIL)
- headless_tests.sh picks up all new files with no new CI step required
