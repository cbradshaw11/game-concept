# TASK-409 Execution Plan: M4 Test Suite

## Goal
Write 5 headless unit tests for M4 systems. Register all in headless_tests.sh.
Zero regression on M3 suite. All tests follow the established SceneTree pattern.

## Depends on: TASK-401 through TASK-408 (all M4 implementations complete)

## Test File Pattern (from M3 tests)
```gdscript
extends SceneTree

func _initialize() -> void:
    # setup
    # assertions
    if all_passed:
        print("PASS: test_name")
        quit(0)
    else:
        print("FAIL: reason")
        quit(1)
```

## Output Directory
`game/scripts/tests/m4/`

---

## Test 1: test_ring_gate.gd

Tests:
1. With rings_cleared=[] and banked_loot=0, mid and outer disabled
2. With rings_cleared=["inner"] and banked_loot=50, mid enabled
3. With rings_cleared=["inner"] and banked_loot=49, mid still disabled (loot gate)
4. With rings_cleared=["inner","mid"] and banked_loot=150, outer enabled

Since this is headless (no UI), test the gate logic directly on GameState values:
- Simulate what _refresh_ring_selector would compute
- Or call a helper that returns bool: is_ring_accessible(ring_id)

If there is no is_ring_accessible() helper, test the field conditions directly.

---

## Test 2: test_ring_unlock_progression.gd

Tests:
1. After calling GameState.extract() with current_ring="inner", rings_cleared contains "inner"
2. After calling GameState.die_in_run(), rings_cleared still contains "inner" (not cleared on death)
3. Save state round-trip: to_save_state() includes rings_cleared; apply_save_state() restores it
4. Extracting same ring twice does not duplicate entry in rings_cleared

---

## Test 3: test_save_migration.gd

Tests:
1. apply_save_state() with a dict missing "rings_cleared" key sets rings_cleared to []
2. apply_save_state() with a dict missing "warden_defeated" key sets warden_defeated to false
3. apply_save_state() with a dict missing "game_completed" key sets game_completed to false
4. No crash (this is the core test — if it reaches quit(0) without error, migration is safe)

Implementation:
```gdscript
var old_save = {
    "unbanked_xp": 100,
    "unbanked_loot": 50,
    "current_ring": "inner"
    # intentionally missing rings_cleared, warden_defeated, game_completed
}
GameState.apply_save_state(old_save)
assert(GameState.rings_cleared == [])
assert(GameState.warden_defeated == false)
assert(GameState.game_completed == false)
```

---

## Test 4: test_behavior_profiles.gd

Tests:
1. EnemyController with flank_aggressive params (chase_range=5.0, attack_cooldown=0.9):
   - At distance 4.0: state should be ATTACK (within range)
   - Verify attack_cooldown difference from frontline_basic
2. EnemyController with kite_volley params (preferred_min_range=1.5, attack_range=4.5):
   - At distance 0.5 (inside min range): state should NOT be ATTACK
   - At distance 2.5 (within attack_range, above min): state should be ATTACK
3. Default (frontline_basic) enemy at distance 0.5: ATTACK fires

Implementation: instantiate EnemyController, set params, call tick(distance, 0.1) in a loop
to advance through cooldown. Check returned state.

---

## Test 5: test_heavy_attack.gd

Tests:
1. PlayerController.heavy_attack() consumes heavy_stamina_cost
2. heavy_attack() emits heavy_attack_triggered with correct damage
3. With insufficient stamina, heavy_attack() returns false and does not emit
4. After reload_weapon_stats() with blade_iron, heavy_damage == 24
5. After reload_weapon_stats() with polearm_iron, heavy_damage == 28

Implementation: instantiate PlayerController, set GameState.selected_weapon_id,
call reload_weapon_stats(), then verify heavy_damage and heavy_stamina_cost values.
For signal test, connect to heavy_attack_triggered and track emitted values.

---

## headless_tests.sh additions

Add to the run_test block (after existing M3 combat tests):
```bash
run_test res://scripts/tests/m4/test_ring_gate.gd
run_test res://scripts/tests/m4/test_ring_unlock_progression.gd
run_test res://scripts/tests/m4/test_save_migration.gd
run_test res://scripts/tests/m4/test_behavior_profiles.gd
run_test res://scripts/tests/m4/test_heavy_attack.gd
```

Also add structural file checks in the `else` (no godot4) branch:
```bash
test -f game/scripts/tests/m4/test_ring_gate.gd
test -f game/scripts/tests/m4/test_ring_unlock_progression.gd
test -f game/scripts/tests/m4/test_save_migration.gd
test -f game/scripts/tests/m4/test_behavior_profiles.gd
test -f game/scripts/tests/m4/test_heavy_attack.gd
```

## Verification Commands
```bash
ls game/scripts/tests/m4/
grep -n 'm4/' scripts/ci/headless_tests.sh
bash scripts/ci/headless_tests.sh 2>&1 | tail -5
```

## Acceptance Criteria
- AC1: ls game/scripts/tests/m4/ returns 5 files
- AC2: bash scripts/ci/headless_tests.sh shows 0 failures
- AC3: grep -n 'm4/' shows all 5 tests registered

## Notes
Read all M4 implementation files before writing tests to match actual method
names, signal names, and field names (implementations may differ slightly from
execution plans). Tests must be self-contained — no scene dependencies.
EnemyController extends RefCounted, not Node, so can be instantiated directly.
PlayerController may require DataStore to be initialized — check if tests need
to call DataStore._ready() or set up a mock.
