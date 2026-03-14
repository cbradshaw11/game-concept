# TASK-503 Execution Plan: Warden Boss Phases 2 and 3 (+ save_version: 1)

## Goal
Add phase transition logic to EnemyController (gated by is_boss flag).
Phase 2 triggers at 70% HP, phase 3 at 35%. Bundle save_version: 1 and
M5 migration guard. Track warden_phase_reached in GameState.

## Depends on: nothing (Wave 1)

## Key Files
- `game/scripts/core/enemy_controller.gd` (add is_boss, phase logic)
- `game/scenes/combat/combat_arena.gd` (set is_boss=true on outer_warden spawn)
- `game/autoload/game_state.gd` (add warden_phase_reached, save_version)

## Read Before Implementing
Read these files in full:
- game/scripts/core/enemy_controller.gd (understand tick() signature, current state machine, existing fields)
- game/scenes/combat/combat_arena.gd (understand _spawn_boss() — where outer_warden is instantiated)
- game/autoload/game_state.gd (understand to_save_state(), apply_save_state(), all existing fields)

---

## Slice 1: EnemyController phase logic

Read enemy_controller.gd. Add at the top of the class:

```gdscript
var is_boss: bool = false
var initial_health: int = 0
var damage_multiplier: float = 1.0

func _ready_or_init() -> void:
    initial_health = max_health  # capture at spawn time
```

Or set initial_health when max_health is assigned (whichever pattern the class uses).

Add phase update method:

```gdscript
func _update_boss_phase() -> void:
    if not is_boss or initial_health <= 0:
        return
    var hp_ratio = float(current_health) / float(initial_health)
    if hp_ratio > 0.70:
        # Phase 1: default elite_pressure params already set
        damage_multiplier = 1.0
        attack_cooldown = 0.8
    elif hp_ratio > 0.35:
        # Phase 2
        damage_multiplier = 1.25
        attack_cooldown = 0.6
        if GameState.warden_phase_reached < 2:
            GameState.warden_phase_reached = 2
    else:
        # Phase 3
        damage_multiplier = 1.25
        attack_cooldown = 0.4
        preferred_min_range = 0.0
        if GameState.warden_phase_reached < 3:
            GameState.warden_phase_reached = 3
```

Call `_update_boss_phase()` at the start of `tick()` (before state machine).

Apply damage_multiplier when emitting attack damage:
```gdscript
# Where attack damage is emitted (in ATTACK state of tick):
var final_damage = int(float(damage) * damage_multiplier)
# emit final_damage instead of damage
```

---

## Slice 2: Set is_boss=true for Warden spawn

In combat_arena.gd, find `_spawn_boss()` or where outer_warden's EnemyController is configured.
After creating the enemy controller instance, add:

```gdscript
enemy_controller.is_boss = true
enemy_controller.initial_health = enemy_data.get("health", 1200)
```

---

## Slice 3: GameState save schema changes

In game_state.gd, add:

```gdscript
var warden_phase_reached: int = -1  # -1 = not encountered; 2 or 3 = highest phase reached
```

In to_save_state():
```gdscript
return {
    # ... existing fields ...
    "warden_phase_reached": warden_phase_reached,
    "save_version": 1
}
```

In apply_save_state():
```gdscript
func apply_save_state(data: Dictionary) -> void:
    # M5 migration guard — must run BEFORE normal key assignments
    if data.get("save_version", 0) < 1:
        warden_phase_reached = -1
    # ... existing apply logic (rings_cleared, banked_loot, etc.) ...
    warden_phase_reached = data.get("warden_phase_reached", -1)
    # save_version is not applied back (it's a migration marker, not runtime state)
```

---

## Verification Commands
```bash
grep -n 'phase\|warden_phase\|is_boss' game/scripts/core/enemy_controller.gd
grep -n 'warden_phase_reached\|save_version' game/autoload/game_state.gd
grep -n 'is_boss\|initial_health' game/scenes/combat/combat_arena.gd
```

## Acceptance Criteria
- AC1: Phase threshold logic in enemy_controller.gd
- AC2: warden_phase_reached and save_version in game_state.gd
- AC3: Phase 2 at <= 840 HP (70% of 1200)
- AC4: Phase 3 at <= 420 HP (35% of 1200)
- AC5: save_version: 1 in to_save_state()

## Notes
The damage_multiplier approach multiplies the emitted damage value, not the base stat.
Find exactly where tick() emits/returns damage to apply the multiplier correctly.
If EnemyController uses a signal like `damage_ready.emit(damage)`, multiply before emit.
If it returns a struct or dict, multiply the damage field there.
initial_health must be captured AFTER max_health is set from enemies.json,
not in the constructor. Verify where max_health is assigned in _spawn_boss().
