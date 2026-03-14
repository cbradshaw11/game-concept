# M4 Plan: The Road Opens

**Milestone goal:** First completable loop — Sanctuary -> Ring 1 -> Ring 2 -> Ring 3 -> Warden -> Credits.

---

## Context: What M1-M3 Built

**M1 (Foundation):** CI workflows, branch protection, PR templates, headless test runner, GitHub Projects board. No game code.

**M2 (Ring 1 Vertical Slice):** Sanctuary-to-Ring1 loop: loadout selector, encounter templates, save/load, combat arena scaffolding, enemy state machine, contract objectives, telemetry, CI headless runtime. Combat baseline — no real damage.

**M3 (Combat Model):** Made the game loseable. Player HP tracked in PlayerController (max 100 from weapons.json). Enemy damage from enemies.json. Weapon stats from weapons.json (removed hardcoded 40). Guard damage reduction (guard_efficiency per weapon). Dodge i-frames (220ms from global_combat). Player poise/stagger. Combat HUD (HP/stamina/poise ProgressBars). Death screen with run summary. Ring 1 balance pass (scavenger_grunt, shieldbearer tuned). 6-test combat suite in game/scripts/tests/combat/. Post-verifier fixes: encounters_cleared increment, ash_flanker poise_damage, ridge_archer ring_availability, poise_bar initialization.

---

## What M4 Must Deliver

**Critical path to first completable loop:**
1. Ring selection UI (player must be able to choose rings other than "inner")
2. Ring unlock gates (rings_cleared persists; cannot skip to Ring 3)
3. Enemy behavior profiles (Ring 2 enemies must feel different)
4. Ring 3 encounter templates + outer_warden spawn path fix
5. Warden boss encounter (single phase, high HP)
6. Win condition + credits screen

**Parallel work (p2, improves loop quality):**
7. Heavy attacks + weapon stat reload fix
8. Loot threshold gates (economy placeholder until shop in M5)

**Test coverage (p1, gate for merge):**
9. M4 test suite (5 tests, all registered in CI)

---

## Key Design Decisions

### Behavior profiles: parameter-driven only

The zone system (pixel_x / 160 = zone index; distance = absf(index - player_zone) + 0.5) is a 1D fake. It cannot support spatial flanking or kiting. Behavior profiles are implemented as tick() parameter variations:

- `frontline_basic`: chase_range=3.5, attack_cooldown=1.5 (current behavior, unchanged)
- `flank_aggressive`: chase_range=5.0, attack_cooldown=0.9 (faster, more aggressive)
- `kite_volley`: preferred_min_range=1.5, attack_range=4.5 (attacks from distance, never closes)
- `guard_counter`: chase_range=4.5, skips ATTACK when player is guarding
- `zone_control`: chase_range=6.0, moderate cooldown, high poise_damage
- `elite_pressure`: high damage, low cooldown (Warden/Warden-adjacent)

Implementation: add `preferred_min_range: float` and `guard_query: Callable` to EnemyController. Match block in CombatArena._spawn_enemies() sets parameters per profile.

### Shop deferred, loot gate instead

rings.json gets loot_gate_threshold per ring. FlowUI gates ring selector. No vendor UI in M4. Shop is M5 scope.

### Warden is single-phase for MVP

enemies.json defines 3 phases but EnemyController has no phase logic. M4 Warden is a single high-stat encounter. Phases 2 and 3 are M5.

### Two concrete bugs fixed as part of M4

1. `outer_warden` is in "bosses" key in enemies.json. `_spawn_enemies()` reads only "enemies" key. Fix: add `_spawn_boss(boss_id)` helper that reads from DataStore.enemies.get("bosses").
2. `main.gd` line 62 hardcodes "inner" for reward calculation. Fix: use `GameState.current_ring` everywhere.

---

## Tasks

### TASK-401 Ring Selection UI and main.gd Decoupling
**Area:** ui | **Priority:** p1 | **Wave:** 1

**Problem:** main.gd hardcodes "inner" at lines 41, 51, 62. No UI to choose a ring.

**AC1:** `grep -n '"inner"' game/scripts/main.gd` returns zero matches in combat flow
**AC2:** FlowUI PrepScreen has ring selector; selecting Ring 2 passes "mid" to GameState
**AC3:** Ring 3 visible but disabled in selector

**Files:** game/scripts/main.gd, game/scripts/ui/flow_ui.gd, game/scenes/ui/flow_ui.tscn

---

### TASK-402 Ring Unlock Gates and Save Schema Migration
**Area:** progression | **Priority:** p1 | **Wave:** 2 (after TASK-401)

**Problem:** No rings_cleared field. Cannot persist ring progress. M3 saves lack this field.

**AC1:** `grep -n 'rings_cleared' game/autoload/game_state.gd` shows field, extract(), save methods
**AC2:** Loading M3 save without rings_cleared key defaults to [] without crash
**AC3:** Ring 2 disabled when rings_cleared does not contain "inner"

**Files:** game/autoload/game_state.gd, game/scripts/systems/save_system.gd, game/scripts/ui/flow_ui.gd

---

### TASK-403 Enemy Behavior Profile Dispatch
**Area:** combat | **Priority:** p1 | **Wave:** 1

**Problem:** behavior_profile field in enemies.json is never read. All enemies behave identically.

**AC1:** `grep -n 'behavior_profile\|preferred_min_range' game/scripts/core/enemy_controller.gd` shows declarations
**AC2:** `grep -n 'flank_aggressive\|kite_volley\|guard_counter' game/scenes/combat/combat_arena.gd` shows match block
**AC3:** test_behavior_profiles.gd exists in game/scripts/tests/m4/

**Files:** game/scripts/core/enemy_controller.gd, game/scenes/combat/combat_arena.gd

---

### TASK-404 Ring 3 Encounter Completion and Boss Spawn Fix
**Area:** combat | **Priority:** p1 | **Wave:** 3 (after TASK-402)

**Problem:** outer_warden unreachable (wrong JSON key). No mid/outer encounter templates.

**AC1:** outer_warden is reachable via CombatArena spawn path
**AC2:** Ring 3 run spawns only outer-ring enemies
**AC3:** outer-ring encounter template with at least 2 distinct enemy types exists

**Files:** game/data/enemies.json, game/scenes/combat/combat_arena.gd, game/data/encounter_templates.json

---

### TASK-405 Warden Boss Encounter
**Area:** combat | **Priority:** p1 | **Wave:** 4 (after TASK-403 + TASK-404)

**Problem:** No way to fight the Warden. No warden_defeated flag. Game cannot be completed.

**AC1:** "Descend to Warden" option in FlowUI after Ring 3 encounters complete
**AC2:** `grep -n 'warden_defeated' game/autoload/game_state.gd` shows flag and persistence
**AC3:** Warden HP loaded from enemies.json (1200)

**Files:** game/autoload/game_state.gd, game/scenes/combat/combat_arena.gd, game/scripts/ui/flow_ui.gd

---

### TASK-406 Win Condition Handler and Credits Screen
**Area:** ui | **Priority:** p1 | **Wave:** 5 (after TASK-405)

**Problem:** warden_defeated has no effect. No win state. No credits. Game crashes.

**AC1:** `grep -n 'warden_defeated\|game_completed\|on_warden_defeated' game/scripts/main.gd` shows handler
**AC2:** CreditsPanel in FlowUI
**AC3:** After credits, stable screen reached (no crash)

**Files:** game/scripts/main.gd, game/scripts/ui/flow_ui.gd, game/scenes/ui/flow_ui.tscn

---

### TASK-407 Heavy Attack Input and Weapon Stat Reload Fix
**Area:** combat | **Priority:** p2 | **Wave:** 1

**Problem:** heavy_damage/heavy_stamina_cost in weapons.json never wired. Weapon swap does not reload stats.

**AC1:** `grep -n 'heavy_damage\|heavy_attack\|heavy_stamina' game/scripts/core/player_controller.gd`
**AC2:** `grep -n 'reload_weapon_stats' game/scripts/main.gd`
**AC3:** test_heavy_attack.gd exists in game/scripts/tests/m4/

**Files:** game/scripts/core/player_controller.gd, game/scenes/combat/combat_arena.gd, game/scripts/main.gd

---

### TASK-408 Loot Threshold Ring Access Gate
**Area:** progression | **Priority:** p2 | **Wave:** 2 (after TASK-401, parallel with TASK-402)

**Problem:** Players can skip to Ring 3 with 0 banked loot. No economy friction.

**AC1:** rings.json has loot_gate_threshold (inner=0, mid=50, outer=150)
**AC2:** Locked ring shows threshold message in FlowUI
**AC3:** `grep -n 'banked_loot' game/scripts/ui/flow_ui.gd` shows gate check

**Files:** game/data/rings.json, game/scripts/ui/flow_ui.gd

---

### TASK-409 M4 Test Suite
**Area:** test | **Priority:** p1 | **Wave:** 6 (after all above)

**Problem:** No test coverage for M4 systems.

**AC1:** `ls game/scripts/tests/m4/` returns 5 files
**AC2:** `bash scripts/ci/headless_tests.sh 2>&1 | tail -5` shows 0 failures
**AC3:** `grep -n 'm4/' scripts/ci/headless_tests.sh` shows all 5 tests registered

**Files:** game/scripts/tests/m4/ (new), scripts/ci/headless_tests.sh
