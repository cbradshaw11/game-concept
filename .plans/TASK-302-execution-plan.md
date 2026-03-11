# TASK-302 Execution Plan: Enemy Damage Output

## Goal
Wire EnemyController ATTACK state to call `_apply_damage_to_player(enemy.damage)` using damage values from enemies.json. Enemies currently deal zero damage.

## Depends on: TASK-301
`_apply_damage_to_player()` must exist in CombatArena before this wires up.

## Current State
- `EnemyController.tick()` transitions to ATTACK state but never calls any damage method
- `CombatArena._spawn_enemies()` calls `EnemyController.new(100, 3.5, 1.2)` — hardcoded, no damage field
- `enemies.json` has `damage` field per enemy type (unused)

## Implementation Steps

### Step 1: Add damage field to EnemyController
File: `game/scripts/core/enemy_controller.gd`

Add `var damage: int = 0` to class fields.

Update constructor to accept and store damage:
```gdscript
func _init(p_health: int, p_speed: float, p_attack_speed: float, p_damage: int = 10) -> void:
    max_health = p_health
    current_health = p_health
    speed = p_speed
    attack_speed = p_attack_speed
    damage = p_damage
```

### Step 2: Wire ATTACK state to deal damage
File: `game/scripts/core/enemy_controller.gd`

In `tick()`, when ATTACK state resolves (attack animation/timer completes), emit a signal or return a damage value to CombatArena:

```gdscript
signal attack_resolved(damage_amount: int)
```

When attack completes:
```gdscript
attack_resolved.emit(damage)
```

### Step 3: Update CombatArena to spawn from enemies.json and wire damage
File: `game/scenes/combat/combat_arena.gd`

Load enemy data from DataStore/enemies.json at spawn time:
```gdscript
func _spawn_enemies(count: int) -> void:
    var enemy_pool = DataStore.get_enemies()  # or load enemies.json directly
    # pick appropriate enemy type for current encounter
    for i in range(count):
        var enemy_data = enemy_pool[i % enemy_pool.size()]
        var enemy = EnemyController.new(
            enemy_data.get("health", 60),
            enemy_data.get("speed", 3.5),
            enemy_data.get("attack_speed", 1.2),
            enemy_data.get("damage", 10)
        )
        enemy.attack_resolved.connect(_apply_damage_to_player)
        enemies.append(enemy)
```

### Step 4: Write unit test stub
File: `game/scripts/tests/test_enemy_damage.gd`

Pattern: instantiate EnemyController with known damage value, trigger attack resolution, connect signal, assert player HP delta equals enemy damage.

## Enemy values from enemies.json (reference)
- scavenger_grunt: damage ~8-15
- ridge_sentinel: damage ~15-25
- dust_crawler: damage ~10-18
(Actual values will be set/tuned in TASK-309)

## Key Files
- `game/scripts/core/enemy_controller.gd` (primary — add damage field, emit signal)
- `game/scenes/combat/combat_arena.gd` (spawn from data, wire signal)
- `game/data/enemies.json` (read-only — source of damage values)

## Acceptance Criteria
- EnemyController reads damage from its data record at spawn
- ATTACK state resolution calls `_apply_damage_to_player(damage)`
- 3+ enemy types verified to deal distinct damage amounts
- Unit test: mock enemy with known damage, attack resolves, HP delta correct
