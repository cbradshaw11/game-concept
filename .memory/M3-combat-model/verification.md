# M3 Combat Model — Adversarial Verification Record

**Date**: 2026-03-10
**Verdict**: BLOCK

---

## Summary

The M3 combat model is architecturally sound in most areas, but contains one CRITICAL data integrity
bug (encounters_cleared never incremented), two WARNING-level gameplay defects, and one WARNING-level
display correctness defect. The CRITICAL finding means the death screen always shows incorrect data.
The implementation cannot ship as-is without the CRITICAL fix.

---

## CRITICAL Findings

### CRIT-1: encounters_cleared is never incremented — death screen always shows 0

**Files affected**: `game/autoload/game_state.gd`, `game/scripts/main.gd`, `game/scripts/ui/flow_ui.gd`

`GameState.encounters_cleared` is declared at line 18 of `game_state.gd` and initialized to `0`.
`flow_ui.on_died()` reads it at line 84 to populate the "Encounters Cleared" field on the death
screen. No code path in the entire codebase ever increments this counter.

`GameState.add_unbanked()` (called when an encounter clears) does not touch `encounters_cleared`.
`_on_resolve_encounter_pressed()` and `_on_encounter_cleared()` in `main.gd` also do not touch it.
Searching every `.gd` file for any assignment to `encounters_cleared` yields zero results.

**Reproduction**: Start a run, clear one or more encounters, die. The death panel will display
"Encounters Cleared: 0" regardless of how many encounters were actually cleared.

**Impact**: Every death screen is factually wrong. Players cannot see their run progress. This is a
broken feature, not a cosmetic issue.

**Fix**: `GameState.add_unbanked()` or a new `GameState.record_encounter_cleared()` method must
increment `encounters_cleared`. It should also be reset in `start_run()` and `die_in_run()`.

---

## WARNING Findings

### WARN-1: ridge_archer has contradictory ring_availability vs rings fields

**File**: `game/data/enemies.json`

`ridge_archer` has `"rings": ["mid", "outer"]` but `"ring_availability": "inner"`. These fields
directly contradict each other.

The spawn filter in `combat_arena.gd:121` uses the `rings` array, so `ridge_archer` is correctly
excluded from inner-ring encounters at runtime. However, `ring_availability: "inner"` is wrong
metadata. The `encounter_templates.json` file includes `ridge_archer` in the `inner_ranged_mix`
template, which is consistent with the broken `ring_availability` field but inconsistent with
`rings`. Any future tool or agent that reads `ring_availability` to determine spawn eligibility
will incorrectly place `ridge_archer` in inner-ring encounters.

**Fix**: Change `ridge_archer`'s `ring_availability` from `"inner"` to `"mid"` (or remove the field
entirely). Also update the `inner_ranged_mix` encounter template to replace `ridge_archer` with an
enemy that actually has `rings: [inner, ...]`.

### WARN-2: ash_flanker missing poise_damage field — silently does zero poise damage

**File**: `game/data/enemies.json`

`ash_flanker` has no `poise_damage` field. `_spawn_enemies()` in `combat_arena.gd:133` does
`enemy_data.get("poise_damage", 0)`, which silently defaults to 0. Every `ash_flanker` attack
calls `_apply_damage_to_player(amount, 0)`, and the `if poise_damage > 0` guard at line 158
means `take_poise_damage` is never called. `ash_flanker` effectively has no poise threat.

`scavenger_grunt` has `poise_damage: 15`, `shieldbearer` has `poise_damage: 20`. Given
`ash_flanker` is a mid/outer-ring flanker with higher base damage (12 vs 6), the omission is
almost certainly unintentional.

**Fix**: Add `"poise_damage": <intended_value>` to `ash_flanker` in `enemies.json`.

### WARN-3: poise_bar not initialized in CombatArena._ready()

**File**: `game/scenes/combat/combat_arena.gd`

`hp_bar` and `stamina_bar` are explicitly initialized in `_ready()` (lines 37-40):

```
hp_bar.max_value = player.max_health
hp_bar.value = player.current_health
stamina_bar.max_value = player.max_stamina
stamina_bar.value = player.stamina
```

`poise_bar` is never initialized in `_ready()`. Its `max_value` and `value` are only set when
`poise_changed` fires. The `.tscn` file sets `max_value = 100.0` and `value = 100.0` as static
defaults, which happen to match `global_combat.max_poise = 100`. This works only by coincidence.
If `max_poise` is tuned to any other value, the poise bar will display incorrect initial state
until the first poise event.

**Fix**: Add `poise_bar.max_value = player.max_poise` and `poise_bar.value = player.current_poise`
in `_ready()` immediately after the stamina bar initialization block.

---

## INFO Findings

### INFO-1: test_enemy_damage hardcodes ridge_archer damage as 10 — JSON value is 5

**File**: `game/scripts/tests/combat/test_enemy_damage.gd:36`

`e_archer` is constructed with `damage=10` but `enemies.json` lists `ridge_archer.damage = 5`.
The test only verifies that `ash_flanker.damage != ridge_archer.damage` (12 != 10, which is true),
but does not verify that the JSON-loaded value is correct. The test passes whether or not the JSON
data is accurate.

### INFO-2: test_player_hp does not truly verify DataStore integration

**File**: `game/scripts/tests/combat/test_player_hp.gd`

`PlayerController._ready()` reads `DataStore.weapons.get("global_combat", {})`. The test checks
that `max_health == 100` and `max_poise == 100`, but these are also the hardcoded defaults in the
`.get()` calls (`max_health = combat_data.get("max_health", 100)`). If DataStore fails to load and
returns `{}`, all defaults match the expected values and the test still passes. The test does not
actually verify that the DataStore pipeline loaded `weapons.json` successfully.

### INFO-3: Lambda closure capture of poise_dmg in _spawn_enemies — needs runtime verification

**File**: `game/scenes/combat/combat_arena.gd:133-136`

```
var poise_dmg: int = enemy_data.get("poise_damage", 0)
enemy.attack_resolved.connect(func(amount: int) -> void:
    _apply_damage_to_player(amount, poise_dmg)
)
```

`poise_dmg` is a loop-iteration-local `var`. In GDScript 4, integer variables declared inside a
`for` body are per-iteration bindings. The lambda should capture the correct `poise_dmg` for each
enemy. However, GDScript closure capture semantics with loop-local variables have historically had
edge cases. This requires a live runtime test with multiple enemies of different `poise_damage`
values to confirm each lambda fires with the correct value.

### INFO-4: Defensive has_signal("poise_changed") guard is unnecessary

**File**: `game/scenes/combat/combat_arena.gd:35`

```
if player.has_signal("poise_changed"):
    player.poise_changed.connect(_on_poise_changed)
```

`poise_changed` is always defined in `PlayerController` (line 11). The guard is dead code and
signals that a prior agent was uncertain whether the signal existed. It should be removed and
replaced with a direct `player.poise_changed.connect(_on_poise_changed)` call.

---

## Checks That Passed

- Signal contract: `health_changed(int, int)` — defined, emitted, connected with matching params
- Signal contract: `stamina_changed(float, int)` — defined, emitted, connected with matching params
- Signal contract: `poise_changed(int, int)` — defined, emitted, connected with matching params
- Signal contract: `player_died()` — PlayerController emits, CombatArena re-emits via lambda,
  main.gd connects `combat_arena.player_died` to `_on_combat_player_died` (correct chain)
- Signal contract: `attack_resolved(int)` — EnemyController emits, CombatArena connects via
  lambda with correct 2-arg signature (`_apply_damage_to_player(amount, poise_dmg)`)
- DataStore.weapons structure: top-level Dictionary with `"weapons"` Array and `"global_combat"`
  Dictionary — all access patterns in codebase match this structure
- DataStore.enemies structure: top-level Dictionary with `"enemies"` Array — access pattern
  `DataStore.enemies.get("enemies", [])` at arena line 119 matches actual structure
- `take_damage()` call order: is_invulnerable check FIRST (line 107), guard logic SECOND (lines
  111-117), health reduction LAST (line 118) — correct
- `_apply_damage_to_player` signature: `(amount: int, poise_damage: int = 0)` with default
  parameter — not needed (lambda always passes both args), but harmless
- Node paths in combat_arena.tscn: `$HUD/Bars/HPBar`, `$HUD/Bars/StaminaBar`,
  `$HUD/Bars/PoiseBar` all exist at the correct paths
- Node paths in flow_ui.tscn: `$DeathPanel/VBox/RingLabel`, `$DeathPanel/VBox/EncountersLabel`,
  `$DeathPanel/VBox/XPLabel`, `$DeathPanel/VBox/LootLabel`, `$DeathPanel/VBox/ReturnButton` all
  exist at the correct paths
- `_spawn_enemies` ring filter: correctly uses `rings` array field, `ring_id` defaults to
  `"inner"` at declaration and is set by `set_context()` before `_spawn_enemies` is called
- `_spawn_enemies` fallback: if `enemy_pool` is empty, falls back to entire `all_enemies` array
- `PlayerController._ready()`: `max_health` set before `current_health`, `max_poise` set before
  `current_poise` — initialization order correct
- `dodge_iframe_ms` key exists in `weapons.json` `global_combat` section — PlayerController line
  44 reads the correct key
- `guard_efficiency` key exists in all three weapons in `weapons.json`
- `_trigger_stagger()`: poise resets to `max_poise` after stagger duration — correct recovery
- `test_guard_reduction.gd` TC3 math: guard break remainder calculation matches implementation
- `test_dodge_iframes.gd` TC3: `dodge_cooldown_timer` is set synchronously before the `await` in
  `_start_iframe_window`, so the test assertion is valid
- Inner-ring balance check: scavenger_grunt (6 dmg) and shieldbearer (6 dmg) both well below
  one-shot threshold of 40
- headless_tests.sh structural check (fallback mode): all 6 new test files present
- `test_poise.gd` stagger recovery: uses `await create_timer(0.7).timeout` with 0.2s buffer over
  the 0.5s `stagger_duration` — valid async test with sufficient margin
- `test_player_hp.gd` `die_in_run()` assertions: unbanked_xp halved (500 -> 250), unbanked_loot
  zeroed — implementation matches

---

## Items Requiring Godot Runtime to Fully Verify

1. DataStore autoload initialization order relative to PlayerController._ready() in a real scene
2. Lambda closure capture of poise_dmg per enemy instance (INFO-3)
3. poise_bar initial display state if max_poise is changed (WARN-3 in practice)
4. Headless test execution of test_poise.gd (uses async timer await — may hang on shutdown)
5. Stamina regeneration emitting stamina_changed every frame — potential HUD update performance
   at 60fps (stamina_bar updated 60 times/sec regardless of visible change)

---

## Recommended Fixes for CRITICAL and WARNING Items

**CRIT-1**: In `game/autoload/game_state.gd`, add `encounters_cleared += 1` inside
`add_unbanked()`. Add `encounters_cleared = 0` inside `start_run()` and `die_in_run()`.

**WARN-1**: In `game/data/enemies.json`, change `ridge_archer.ring_availability` from `"inner"`
to `"mid"`. In `game/data/encounter_templates.json`, replace `ridge_archer` in `inner_ranged_mix`
with an inner-eligible enemy.

**WARN-2**: In `game/data/enemies.json`, add `"poise_damage": <value>` to `ash_flanker`.
Based on role (flanker, 12 base damage), a value in the 10-15 range is appropriate.

**WARN-3**: In `game/scenes/combat/combat_arena.gd`, add after stamina_bar initialization:
`poise_bar.max_value = player.max_poise` and `poise_bar.value = player.current_poise`.

---

## Gate Recommendation

BLOCK

CRIT-1 is a broken feature: the death screen Encounters Cleared counter is permanently stuck at 0
for every player death. WARN-1 creates data integrity corruption that will mislead future agents or
designers working with enemy data. WARN-2 silently removes a gameplay mechanic from an enemy.
WARN-3 is a latent display bug waiting for the first balance pass.

The signal wiring, node paths, take_damage order, DataStore key structure, and test structure are
all correct. The core combat loop will not crash. But the AC for the death screen (encounters
cleared display) is provably broken without any Godot runtime needed to confirm it.

---

## Post-fix Status

**Date**: 2026-03-10

All 4 CRITICAL and WARNING issues resolved:

- **CRIT-1 (TASK-311) — RESOLVED**: `encounters_cleared` now incremented in `GameState.add_unbanked()` and reset in both `start_run()` and `die_in_run()`. Death screen will display correct encounter count.
- **WARN-1 (TASK-312) — RESOLVED**: `ridge_archer.ring_availability` corrected from `"inner"` to `"mid"` in `enemies.json`. `inner_ranged_mix` template in `encounter_templates.json` updated to replace `ridge_archer` with `shieldbearer` (an inner-eligible enemy).
- **WARN-2 (TASK-313) — RESOLVED**: `ash_flanker` now has `poise_damage: 14` in `enemies.json`. Flanker attacks will correctly apply poise pressure at runtime.
- **WARN-3 (TASK-314) — RESOLVED**: `poise_bar.max_value` and `poise_bar.value` initialized in `CombatArena._ready()` immediately after `stamina_bar`, matching the pattern used for `hp_bar` and `stamina_bar`.

Remaining items requiring Godot runtime verification (not addressable statically):

- **INFO-3**: Lambda closure capture of `poise_dmg` per enemy instance in `_spawn_enemies()` — requires live runtime test with multiple enemies of different `poise_damage` values to confirm each lambda fires with the correct bound value.
- **INFO-2**: DataStore load verification — test suite passes even if DataStore returns `{}` because defaults match expected values; true integration requires a runtime scene load.
