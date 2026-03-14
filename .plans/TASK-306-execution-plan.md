# TASK-306 Execution Plan: Player Poise Tracking and Stagger

## Goal
Mirror the enemy poise system on the player side. Enemies deal poise damage that reduces player poise. At 0, player is staggered for 0.5s and cannot act. Poise regenerates to max after stagger.

## Depends on: TASK-301 (PlayerController foundation), TASK-302 (enemy attacks)

## Current State
- EnemyController already has poise tracking (poise_break bool in apply_damage)
- PlayerController has no poise fields
- enemies.json has `poise_damage` per enemy type
- `_apply_damage_to_player()` in CombatArena only deals health damage

## Implementation Steps

### Step 1: Add poise fields and signals to PlayerController
File: `game/scripts/core/player_controller.gd`

```gdscript
signal poise_changed(current: int, maximum: int)
signal player_staggered()

var current_poise: int
var max_poise: int
var is_staggered: bool = false
var stagger_duration: float = 0.5
```

### Step 2: Initialize poise from weapons.json global_combat
In `_ready()`:
```gdscript
var combat_data = DataStore.get_global_combat()
max_poise = combat_data.get("max_poise", 100)
current_poise = max_poise
```

### Step 3: Add take_poise_damage() method
```gdscript
func take_poise_damage(amount: int) -> void:
    if is_staggered:
        return
    current_poise = max(0, current_poise - amount)
    poise_changed.emit(current_poise, max_poise)
    if current_poise <= 0:
        _trigger_stagger()

func _trigger_stagger() -> void:
    is_staggered = true
    player_staggered.emit()
    await get_tree().create_timer(stagger_duration).timeout
    is_staggered = false
    current_poise = max_poise
    poise_changed.emit(current_poise, max_poise)
```

### Step 4: Block actions during stagger
In `try_attack()` and `try_dodge()`:
```gdscript
if is_staggered:
    return
```

### Step 5: Wire poise damage in CombatArena
File: `game/scenes/combat/combat_arena.gd`

Update `_apply_damage_to_player()` to also call poise damage:
```gdscript
func _apply_damage_to_player(damage: int, poise_damage: int = 0) -> void:
    if player:
        player.take_damage(damage)
        if poise_damage > 0:
            player.take_poise_damage(poise_damage)
```

Or have EnemyController emit `attack_resolved(damage, poise_damage)` and update signature.

### Step 6: Write unit test stub
File: `game/scripts/tests/test_poise.gd`

Pattern:
- Call take_poise_damage until current_poise <= 0
- Assert player_staggered signal fired
- Wait stagger_duration + small buffer
- Assert current_poise restored to max_poise

## Key Files
- `game/scripts/core/player_controller.gd` (primary — add poise system)
- `game/scenes/combat/combat_arena.gd` (call take_poise_damage alongside health damage)
- `game/data/weapons.json` (read-only — max_poise = 100)
- `game/data/enemies.json` (read-only — poise_damage per enemy)
- `game/scripts/core/enemy_controller.gd` (read-only — mirror pattern)

## Acceptance Criteria
- PlayerController has current_poise, max_poise, take_poise_damage(), player_staggered signal
- poise_changed signal emitted when poise changes
- Poise at 0 → player_staggered fires, stagger blocks actions for 0.5s
- Poise resets to max after stagger resolves
