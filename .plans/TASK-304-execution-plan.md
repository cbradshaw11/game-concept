# TASK-304 Execution Plan: Guard Damage Reduction

## Goal
Make guard mechanically meaningful. While PlayerController.guarding is true, incoming damage is reduced by `guard_efficiency` from the equipped weapon. Guard break fires a signal when a single hit exceeds the threshold.

## Depends on: TASK-301 (take_damage), TASK-302 (enemy damage output)

## Current State
- `PlayerController.guarding: bool` already exists and is toggled by guard input
- `weapons.json` has `guard_efficiency` per weapon (0.35–0.78)
- `take_damage()` applies full damage regardless of guard state

## Implementation Steps

### Step 1: Add guard constants and signal to PlayerController
File: `game/scripts/core/player_controller.gd`

```gdscript
signal guard_broken()
const GUARD_BREAK_THRESHOLD: int = 30  # single hit exceeding this breaks guard

var guard_efficiency: float = 0.0  # loaded from weapon data
```

### Step 2: Load guard_efficiency from weapon at init
File: `game/scripts/core/player_controller.gd`

In `_ready()` or when weapon is set:
```gdscript
func set_weapon(weapon_data: Dictionary) -> void:
    guard_efficiency = weapon_data.get("guard_efficiency", 0.5)
```

Or read from GameState.selected_weapon_id → weapons.json in _ready().

### Step 3: Modify take_damage() to apply guard reduction
File: `game/scripts/core/player_controller.gd`

```gdscript
func take_damage(amount: int) -> void:
    var effective_damage = amount
    if guarding:
        if amount > GUARD_BREAK_THRESHOLD:
            # guard broken — remainder at full damage, guard drops
            guard_broken.emit()
            guarding = false
            effective_damage = amount - GUARD_BREAK_THRESHOLD  # or full amount
        else:
            effective_damage = int(amount * (1.0 - guard_efficiency))

    current_health = max(0, current_health - effective_damage)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        player_died.emit()
```

### Step 4: Write unit test stub
File: `game/scripts/tests/test_guard_reduction.gd`

Pattern:
- Set guarding = true, call take_damage(20), assert HP > (max - 20)
- Set guarding = true, call take_damage(40) > threshold, assert guard_broken fired
- Set guarding = false, call take_damage(20), assert HP = max - 20 exactly

## Weapon guard_efficiency values (from weapons.json)
- blade_iron: 0.70 (30% of damage taken while guarding)
- polearm_iron: 0.78 (22% taken)
- bow_iron: 0.35 (65% taken — poor guard weapon)

## Key Files
- `game/scripts/core/player_controller.gd` (primary — modify take_damage)
- `game/data/weapons.json` (read-only — guard_efficiency values)
- `game/scenes/combat/combat_arena.gd` (read-only — calls take_damage)

## Acceptance Criteria
- Guarded damage = `damage * (1 - guard_efficiency)` < unguarded damage
- `guard_broken` signal fires when hit exceeds threshold
- Remainder damage after guard break applies at full value
- Guard has no effect when guarding = false
