# TASK-404 Execution Plan: Ring 3 Encounter Completion and Boss Spawn Fix

## Goal
Fix outer_warden spawn path (bosses key issue). Add mid-ring and outer-ring
encounter templates. Ensure ring-based enemy filtering in CombatArena works
correctly so Ring 3 spawns only outer-ring enemies.

## Depends on: TASK-402

## Key Files
- `game/scenes/combat/combat_arena.gd` (_spawn_enemies + add _spawn_boss helper)
- `game/data/enemies.json` (read enemy ring_availability; outer_warden is in "bosses")
- `game/data/encounter_templates.json` (add mid and outer templates)
- `game/autoload/game_state.gd` (read-only — current_ring for filtering)

## Step 1: Read enemy data to understand structure

Before editing, read game/data/enemies.json to confirm:
- Which enemies have ring_availability="mid" and ring_availability="outer"
- outer_warden structure under "bosses" key
- Fields available: id, health, damage, poise_damage, behavior_profile, ring_availability

## Slice 1: Add boss spawn helper and fix ring filtering in CombatArena

Read game/scenes/combat/combat_arena.gd. Find _spawn_enemies().

**Fix 1: ring_availability filter**
If _spawn_enemies() does not already filter by ring_availability, add:
```gdscript
var ring = GameState.current_ring
var eligible = DataStore.enemies.get("enemies", []).filter(
    func(e): return e.get("ring_availability", "inner") == ring
)
```
For "mid" ring: return enemies with ring_availability="mid"
For "outer" ring: return enemies with ring_availability="outer"

**Fix 2: Add _spawn_boss helper**
```gdscript
func _spawn_boss(boss_id: String) -> EnemyController:
    var bosses = DataStore.enemies.get("bosses", [])
    var boss_data = bosses.filter(func(b): return b.id == boss_id)
    if boss_data.is_empty():
        push_error("Boss not found: " + boss_id)
        return null
    var boss = EnemyController.new()
    boss.max_health = boss_data[0].get("health", 1200)
    boss.damage = boss_data[0].get("damage", 22)
    boss.poise_damage = boss_data[0].get("poise_damage", 35)
    boss.behavior_profile = boss_data[0].get("behavior_profile", "elite_pressure")
    # profile parameters will be set by the same match block
    return boss
```

TASK-405 will call _spawn_boss("outer_warden"). This task just adds the helper.

## Slice 2: Add mid and outer encounter templates

Read game/data/encounter_templates.json to understand existing format.

Add mid-ring templates (at least 2):
- "mid_flank_pair": ash_flanker x2 (flank_aggressive)
- "mid_mixed": cursed_pilgrim + ash_flanker

Add outer-ring templates (at least 2):
- "outer_rift_assault": rift_caster x2
- "outer_warden_approach": rift_caster + warden_hunter

Templates should follow existing format. Add a "ring" field if not present:
```json
{
  "id": "mid_flank_pair",
  "ring": "mid",
  "enemies": ["ash_flanker", "ash_flanker"]
}
```

## Verification Commands
```bash
python3 -c "import json; d=json.load(open('game/data/enemies.json')); print([e['id'] for e in d.get('enemies',[])+d.get('bosses',[])])"
python3 -c "import json; t=json.load(open('game/data/encounter_templates.json')); [print(x.get('ring','?'), x.get('id')) for x in t.get('templates',[])]"
grep -n 'ring_availability\|_spawn_boss' game/scenes/combat/combat_arena.gd
```

## Acceptance Criteria
- AC1: outer_warden is reachable via CombatArena (bosses array path exists)
- AC2: Ring 3 run spawns only outer-ring enemies
- AC3: outer-ring encounter template exists with at least 2 enemy types

## Notes
Do not move outer_warden to the enemies array. Keep the bosses/enemies separation.
Add _spawn_boss() as a new helper. TASK-405 will call it for the Warden encounter.
Check whether CombatArena.gd already has ring filtering. If it does, verify it
reads from GameState.current_ring (not a hardcoded string).
