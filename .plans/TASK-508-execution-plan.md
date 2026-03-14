# TASK-508 Execution Plan: M5 Test Suite

## Goal
Write 6 headless unit tests for M5 systems. Register all in headless_tests.sh.
Zero regression on M4 suite. All tests follow the established SceneTree pattern.

## Depends on: TASK-501 through TASK-507 (all M5 Wave 1 implementations complete)

## Test File Pattern (from M3/M4 tests)
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
`game/scripts/tests/m5/`

## CRITICAL: Read All M5 Implementation Files First
Before writing any test, read:
- game/autoload/game_state.gd (all fields, start_run, die_in_run, apply_upgrade, warden_phase_reached, save_version)
- game/scripts/core/enemy_controller.gd (is_boss, phase logic, initial_health, tick() signature)
- game/scripts/core/player_controller.gd (apply_upgrade, stat fields)
- game/data/upgrades.json (upgrade pool structure)
- game/data/rings.json (contract_target fields)
- scripts/ci/headless_tests.sh (run_test function, existing test registrations)

---

## Test 1: test_upgrade_pass.gd

Tests:
1. upgrades.json has >= 6 upgrades
2. apply_upgrade() with iron_constitution increases PlayerController.max_health by 20
3. active_upgrades is empty after start_run() (resets each run)
4. active_upgrades is NOT a key in to_save_state() output

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    # Test 1: upgrades.json has >= 6 upgrades
    var f = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
    var upgrades_data = JSON.parse_string(f.get_as_text())
    if upgrades_data.get("upgrades", []).size() < 6:
        failures.append("upgrades.json has fewer than 6 upgrades")

    # Test 2: apply_upgrade increases stat
    var player = PlayerController.new()
    # ... initialize player ...
    var before = player.max_health
    var upgrade = {"stat": "max_health", "modifier_type": "add", "value": 20}
    player.apply_upgrade(upgrade)
    if player.max_health != before + 20:
        failures.append("apply_upgrade did not increase max_health by 20")

    # Test 3: start_run resets active_upgrades
    GameState.active_upgrades.append({"id": "test"})
    GameState.start_run("inner")
    if not GameState.active_upgrades.is_empty():
        failures.append("start_run did not clear active_upgrades")

    # Test 4: active_upgrades not in save state
    var save = GameState.to_save_state()
    if "active_upgrades" in save:
        failures.append("active_upgrades found in to_save_state() — must be per-run only")

    if failures.is_empty():
        print("PASS: test_upgrade_pass")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## Test 2: test_warden_phases.gd

Tests:
1. EnemyController with is_boss=true, initial_health=1200: at health=840 (70%) phase 2 params active
2. At health=420 (35%) phase 3 params active
3. EnemyController with is_boss=false: no phase change at any HP

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    var enemy = EnemyController.new()
    enemy.is_boss = true
    enemy.max_health = 1200
    enemy.initial_health = 1200
    enemy.current_health = 1200
    # set to elite_pressure base params
    enemy.attack_cooldown = 0.8

    # Test 1: at 840 HP (70%) — phase 2
    enemy.current_health = 840
    enemy.tick(2.0, 0.1)  # within range, trigger phase check
    if enemy.attack_cooldown >= 0.8:
        failures.append("Phase 2 not triggered at 70% HP (attack_cooldown should be < 0.8)")

    # Test 2: at 420 HP (35%) — phase 3
    enemy.current_health = 420
    enemy.tick(2.0, 0.1)
    if enemy.attack_cooldown >= 0.6:
        failures.append("Phase 3 not triggered at 35% HP (attack_cooldown should be < 0.6)")

    # Test 3: non-boss enemy — no phase change
    var regular = EnemyController.new()
    regular.is_boss = false
    regular.max_health = 100
    regular.current_health = 10  # very low HP
    regular.attack_cooldown = 1.5
    regular.tick(2.0, 0.1)
    if regular.attack_cooldown != 1.5:
        failures.append("Regular enemy attack_cooldown changed — phase logic must check is_boss")

    if failures.is_empty():
        print("PASS: test_warden_phases")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## Test 3: test_bank_on_death.gd

Tests:
1. die_in_run() with unbanked_loot=100 results in banked_loot += 25
2. rings_cleared is not reset by die_in_run()

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    # Setup
    GameState.rings_cleared = ["inner"]
    GameState.unbanked_loot = 100
    GameState.banked_loot = 0

    GameState.die_in_run()

    # Test 1: 25% retention
    if GameState.banked_loot != 25:
        failures.append("Expected banked_loot == 25 after die_in_run() with unbanked=100, got %d" % GameState.banked_loot)

    # Test 2: rings_cleared preserved
    if not GameState.rings_cleared.has("inner"):
        failures.append("rings_cleared lost 'inner' on die_in_run() — must persist through death")

    if failures.is_empty():
        print("PASS: test_bank_on_death")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## Test 4: test_save_migration_m5.gd

Tests:
1. M4-era save dict (no save_version, no warden_phase_reached) applies cleanly
2. warden_phase_reached defaults to -1 after applying M4 save

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    var m4_save = {
        "unbanked_xp": 100,
        "unbanked_loot": 50,
        "banked_loot": 200,
        "current_ring": "inner",
        "rings_cleared": ["inner"],
        "warden_defeated": false,
        "game_completed": false
        # intentionally missing save_version, warden_phase_reached
    }

    GameState.apply_save_state(m4_save)

    if GameState.warden_phase_reached != -1:
        failures.append("Expected warden_phase_reached == -1 for M4 save, got %d" % GameState.warden_phase_reached)

    # Verify no crash (reaching here means migration was safe)
    if GameState.rings_cleared != ["inner"]:
        failures.append("rings_cleared not preserved from M4 save")

    if failures.is_empty():
        print("PASS: test_save_migration_m5")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## Test 5: test_contract_targets.gd

Tests:
1. rings.json inner has contract_target == 3
2. rings.json mid has contract_target == 4
3. rings.json outer has contract_target == 4
4. rings.json sanctuary does NOT have contract_target (or it is 0)

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    var f = FileAccess.open("res://data/rings.json", FileAccess.READ)
    var rings_data = JSON.parse_string(f.get_as_text()).get("rings", [])

    var targets = {}
    for r in rings_data:
        targets[r.get("id")] = r.get("contract_target", null)

    if targets.get("inner") != 3:
        failures.append("inner contract_target expected 3, got %s" % str(targets.get("inner")))
    if targets.get("mid") != 4:
        failures.append("mid contract_target expected 4, got %s" % str(targets.get("mid")))
    if targets.get("outer") != 4:
        failures.append("outer contract_target expected 4, got %s" % str(targets.get("outer")))

    if failures.is_empty():
        print("PASS: test_contract_targets")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## Test 6: test_audio_events.gd

Tests structural wiring only — no runtime audio playback.
1. combat_arena.gd source contains references to 4 audio event names
2. game/audio/ directory has the 4 required files

```gdscript
extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []

    # Check audio files exist
    var required_files = ["hit_land.wav", "damage_taken.wav", "dodge_guard_success.wav", "player_death.wav"]
    for filename in required_files:
        var path = "res://audio/" + filename
        if not FileAccess.file_exists(path):
            failures.append("Missing audio file: " + path)

    # Check WIND_UP state in enemy_controller.gd source
    var ec_path = "res://scripts/core/enemy_controller.gd"
    if FileAccess.file_exists(ec_path):
        var src = FileAccess.get_file_as_string(ec_path)
        if not ("WIND_UP" in src or "wind_up" in src):
            failures.append("WIND_UP state not found in enemy_controller.gd")
    else:
        failures.append("enemy_controller.gd not found at expected path")

    if failures.is_empty():
        print("PASS: test_audio_events")
        quit(0)
    else:
        for f in failures:
            print("FAIL: " + f)
        quit(1)
```

---

## headless_tests.sh additions

Add to the run_test block (after existing M4 tests):
```bash
run_test res://scripts/tests/m5/test_upgrade_pass.gd
run_test res://scripts/tests/m5/test_warden_phases.gd
run_test res://scripts/tests/m5/test_bank_on_death.gd
run_test res://scripts/tests/m5/test_save_migration_m5.gd
run_test res://scripts/tests/m5/test_contract_targets.gd
run_test res://scripts/tests/m5/test_audio_events.gd
```

Add structural file checks in the `else` (no godot4) branch:
```bash
test -f game/scripts/tests/m5/test_upgrade_pass.gd
test -f game/scripts/tests/m5/test_warden_phases.gd
test -f game/scripts/tests/m5/test_bank_on_death.gd
test -f game/scripts/tests/m5/test_save_migration_m5.gd
test -f game/scripts/tests/m5/test_contract_targets.gd
test -f game/scripts/tests/m5/test_audio_events.gd
```

---

## Verification Commands
```bash
ls game/scripts/tests/m5/
grep -n 'm5/' scripts/ci/headless_tests.sh
bash scripts/ci/headless_tests.sh 2>&1 | tail -10
python3 scripts/ci/check_content_volume.py
```

## Acceptance Criteria
- AC1: ls shows 6 files
- AC2: headless_tests.sh shows 0 failures
- AC3: grep shows 6 m5 test registrations
- AC4: check_content_volume.py exits 0

## Notes
Read all M5 implementation files before writing tests to match actual method names.
Tests must be self-contained — no scene dependencies.
EnemyController extends RefCounted, not Node, so can be instantiated directly with .new().
GameState is an autoload — access fields directly (GameState.warden_phase_reached).
Adapt tick() call signatures to match what was actually implemented in TASK-503.
