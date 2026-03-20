# TASK-303 Execution Plan: Weapon Stat Integration

## Goal
Remove the hardcoded `40` damage constant from CombatArena. Thread the selected weapon through GameState so CombatArena reads `light_damage` from weapons.json.

## Current State (what to fix)
- `combat_arena.gd` line: `_apply_damage_to_front_enemy(40)` — hardcoded, ignores weapon choice
- `main.gd` stores `var selected_weapon_id: String = "blade_iron"` locally, never synced to GameState
- GameState has no `selected_weapon_id` field

## Implementation Steps

### Step 1: Add weapon tracking to GameState
File: `game/autoload/game_state.gd`

Add:
```gdscript
var selected_weapon_id: String = "blade_iron"
```

### Step 2: Sync weapon selection to GameState in main.gd
File: `game/scripts/main.gd`

When weapon is selected (loadout_selected signal handler), add:
```gdscript
GameState.selected_weapon_id = weapon_id
```

### Step 3: Replace hardcoded 40 in CombatArena
File: `game/scenes/combat/combat_arena.gd`

Add a method to load weapon data at arena start:
```gdscript
var weapon_data: Dictionary = {}

func _load_weapon_data() -> void:
    var all_weapons = DataStore.get_weapons()
    for w in all_weapons:
        if w.get("id") == GameState.selected_weapon_id:
            weapon_data = w
            break
    if weapon_data.is_empty():
        # fallback
        weapon_data = {"light_damage": 14}
```

Replace hardcoded call:
```gdscript
# Before:
_apply_damage_to_front_enemy(40)
# After:
_apply_damage_to_front_enemy(weapon_data.get("light_damage", 14))
```

Call `_load_weapon_data()` in `_ready()` or at the start of each encounter.

### Step 4: Write unit test stub
File: `game/scripts/tests/test_weapon_stats.gd`

Pattern: set GameState.selected_weapon_id to each weapon, instantiate arena, trigger attack, assert HP delta matches weapons.json value.

## Weapon damage values (from weapons.json)
- blade_iron: light_damage = 14
- polearm_iron: light_damage = 12
- bow_iron: light_damage = 11

## Key Files
- `game/scenes/combat/combat_arena.gd` (primary — remove hardcoded 40)
- `game/autoload/game_state.gd` (add selected_weapon_id)
- `game/scripts/main.gd` (sync weapon to GameState on selection)
- `game/scripts/ui/flow_ui.gd` (read-only — loadout_selected signal source)
- `game/data/weapons.json` (read-only — source of truth for damage values)

## Acceptance Criteria
- No hardcoded `40` remains in the combat damage path
- GameState.selected_weapon_id persists weapon choice
- CombatArena reads light_damage from weapon record
- All 3 weapons deal distinct damage amounts matching weapons.json
