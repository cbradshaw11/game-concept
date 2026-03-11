# TASK-301 Execution Plan: Player HP and Death State

## Goal
Add `current_health` / `max_health` to PlayerController, wire `player_died` signal through CombatArena, connect to GameState death flow in main.gd.

## Pre-existing wiring (do NOT recreate)
- `GameState.die_in_run()` exists and clears unbanked rewards
- `main.gd._on_player_died()` exists: disables combat arena, calls `flow_ui.on_died()`
- `GameState` already emits `player_died` signal

## What's missing
1. `PlayerController` has no `current_health`, `max_health`, `take_damage()`, or `health_changed` signal
2. `CombatArena` has no `player_died` signal and no `_apply_damage_to_player()` method
3. `main.gd` never connects `combat_arena.player_died` → `_on_player_died()`

## Implementation Steps

### Step 1: Update PlayerController
File: `game/scripts/core/player_controller.gd`

Add at top of class:
```gdscript
signal health_changed(current: int, maximum: int)
signal player_died()

var current_health: int
var max_health: int
```

In `_ready()`, load max_health from weapons.json via DataStore (or hardcode 100 as fallback):
```gdscript
var combat_data = DataStore.get_global_combat()
max_health = combat_data.get("max_health", 100)
current_health = max_health
```

Add method:
```gdscript
func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        player_died.emit()
```

### Step 2: Update CombatArena
File: `game/scenes/combat/combat_arena.gd`

Add signal:
```gdscript
signal player_died()
```

Add method:
```gdscript
func _apply_damage_to_player(amount: int) -> void:
    if player:
        player.take_damage(amount)
```

Connect `player.player_died` → local handler that re-emits `player_died` signal so main.gd can catch it.

### Step 3: Update main.gd
File: `game/scripts/main.gd`

In `_ready()` or wherever combat_arena is connected, add:
```gdscript
combat_arena.player_died.connect(_on_player_died)
```

### Step 4: Write unit test
File: `game/scripts/tests/test_player_hp.gd` (stub — will be consolidated in TASK-310)

Pattern: extend SceneTree, instantiate minimal PlayerController, call take_damage twice summing > max_health, assert player_died emitted, assert unbanked reset.

## Key Files
- `game/scripts/core/player_controller.gd` (primary)
- `game/scenes/combat/combat_arena.gd` (add signal + method)
- `game/scripts/main.gd` (connect signal)
- `game/autoload/game_state.gd` (read-only — do not modify)
- `game/data/weapons.json` (read-only — read max_health=100)

## Acceptance Criteria
- `PlayerController` has `current_health`, `max_health`, `take_damage()`, `player_died` signal
- `take_damage()` at 0 HP emits `player_died`
- `main.gd` connects `combat_arena.player_died` → `_on_player_died()`
- Unit test verifies: damage > max_health → player_died fires, unbanked resets to 0
