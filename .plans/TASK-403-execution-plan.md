# TASK-403 Execution Plan: Enemy Behavior Profile Dispatch

## Goal
Wire behavior_profile field from enemies.json into EnemyController tick() parameters.
Add preferred_min_range and guard_query to EnemyController. Add match block in
CombatArena._spawn_enemies() that sets parameters per profile.

## Depends on: nothing (Wave 1)

## Key Files
- `game/scripts/core/enemy_controller.gd` (add fields, modify tick())
- `game/scenes/combat/combat_arena.gd` (add match block in _spawn_enemies())
- `game/data/enemies.json` (read-only — behavior_profile values per enemy)

## Profile Parameter Reference
```
frontline_basic: chase_range=3.5, attack_cooldown=1.5 (unchanged defaults)
flank_aggressive: chase_range=5.0, attack_cooldown=0.9
kite_volley: preferred_min_range=1.5, attack_range=4.5
guard_counter: chase_range=4.5, guard_query reads player guard state
zone_control: chase_range=6.0, attack_cooldown=1.8, poise_damage x1.5
elite_pressure: chase_range=4.5, attack_cooldown=0.7
```

## Slice 1: Add fields to EnemyController

Read game/scripts/core/enemy_controller.gd.

Add to variable declarations:
```gdscript
var preferred_min_range: float = 0.0
var guard_query: Callable = func() -> bool: return false
```

Modify tick() ATTACK state transition. The current check is likely:
```gdscript
if distance_to_player <= attack_range:
```
Change to:
```gdscript
if distance_to_player <= attack_range and distance_to_player >= preferred_min_range:
```

For guard_counter attack suppression — in the ATTACK branch where the enemy
fires attack_resolved, add a guard check:
```gdscript
if not guard_query.call():
    attack_resolved.emit(damage)
```
(Or suppress the ATTACK state transition entirely when guard_query.call() is true.)

## Slice 2: Add match block in CombatArena._spawn_enemies()

Read game/scenes/combat/combat_arena.gd. Find _spawn_enemies().

After instantiating each EnemyController (after setting damage, poise_damage),
read behavior_profile from the enemy data dict and apply:

```gdscript
var profile: String = enemy_data.get("behavior_profile", "frontline_basic")
match profile:
    "flank_aggressive":
        enemy.chase_range = 5.0
        enemy.attack_cooldown = 0.9
    "kite_volley":
        enemy.preferred_min_range = 1.5
        enemy.attack_range = 4.5
    "guard_counter":
        enemy.chase_range = 4.5
        var pc = player_controller  # capture reference
        enemy.guard_query = func() -> bool: return pc.guarding
    "zone_control":
        enemy.chase_range = 6.0
        enemy.attack_cooldown = 1.8
    "elite_pressure":
        enemy.chase_range = 4.5
        enemy.attack_cooldown = 0.7
    _:  # frontline_basic — defaults already set
        pass
```

## Verification Commands
```bash
grep -n 'behavior_profile\|preferred_min_range\|guard_query' game/scripts/core/enemy_controller.gd
grep -n 'behavior_profile\|flank_aggressive\|kite_volley\|guard_counter' game/scenes/combat/combat_arena.gd
```

## Acceptance Criteria
- AC1: preferred_min_range and guard_query declared in EnemyController
- AC2: CombatArena match block dispatches profile parameters on spawn
- AC3: test_behavior_profiles.gd test file exists (written by TASK-409)

## Notes
Do not add zone system code. All profiles operate on tick() parameter values only.
The guard_query closure captures player_controller reference. Make sure the closure
references are valid (avoid dangling refs if PlayerController is freed).
Default guard_query returns false so non-guard_counter enemies always fire normally.
kite_volley prefers minimum range — the enemy will chase until at preferred_min_range
then stop closing and attack from that distance. This is achievable with the
existing CHASE/ATTACK FSM by checking preferred_min_range in the distance checks.
