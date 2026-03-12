# TASK-407 Execution Plan: Heavy Attack Input and Weapon Stat Reload Fix

## Goal
Wire heavy_damage and heavy_stamina_cost from weapons.json. Add heavy attack input.
Add reload_weapon_stats() to PlayerController. Fix _on_loadout_selected() in
main.gd to call reload_weapon_stats() after weapon swap.

## Depends on: nothing (Wave 1)

## Weapon Data Reference (from weapons.json)
- blade_iron: light_damage=14, heavy_damage=24, heavy_stamina_cost=18, guard_efficiency=0.70
- polearm_iron: light_damage=12, heavy_damage=28, heavy_stamina_cost=22, guard_efficiency=0.78
- bow_iron: light_damage=11, heavy_damage=26, heavy_stamina_cost=20, guard_efficiency=0.35
- global_combat: max_health=100, max_poise=100, dodge_iframe_ms=220

## Key Files
- `game/scripts/core/player_controller.gd` (add heavy_damage, heavy_stamina_cost, reload_weapon_stats, heavy_attack)
- `game/scenes/combat/combat_arena.gd` (handle heavy attack input, apply heavy damage)
- `game/scripts/main.gd` (call reload_weapon_stats on loadout change)
- `game/data/weapons.json` (read-only)

## Slice 1: Add heavy attack to PlayerController

Read game/scripts/core/player_controller.gd.

Add field declarations:
```gdscript
var heavy_damage: int = 24
var heavy_stamina_cost: float = 18.0
signal heavy_attack_triggered(damage: int)
```

Add reload_weapon_stats() method:
```gdscript
func reload_weapon_stats() -> void:
    var weapons = DataStore.weapons.get("weapons", [])
    var weapon_id = GameState.selected_weapon_id
    for w in weapons:
        if w.get("id") == weapon_id:
            max_health = DataStore.weapons.get("global_combat", {}).get("max_health", 100)
            guard_efficiency = w.get("guard_efficiency", 0.70)
            heavy_damage = w.get("heavy_damage", 24)
            heavy_stamina_cost = float(w.get("heavy_stamina_cost", 18))
            # Also reload light attack damage if player tracks it
            break
```

Add heavy_attack() method:
```gdscript
func heavy_attack() -> bool:
    if current_stamina < heavy_stamina_cost:
        return false
    current_stamina -= heavy_stamina_cost
    stamina_changed.emit(current_stamina, max_stamina)
    heavy_attack_triggered.emit(heavy_damage)
    return true
```

## Slice 2: Wire heavy attack input in CombatArena

Read game/scenes/combat/combat_arena.gd.

In _input() (or _unhandled_input):
```gdscript
if event.is_action_pressed("heavy_attack"):
    if player_controller.heavy_attack():
        _apply_damage_to_front_enemy(player_controller.heavy_damage)
```

Or connect to the heavy_attack_triggered signal:
```gdscript
player_controller.heavy_attack_triggered.connect(
    func(dmg): _apply_damage_to_front_enemy(dmg)
)
```

Add input action to project.godot or use InputMap.add_action() in _ready():
The action "heavy_attack" should be bound to Shift+Z or a distinct key.

Note: If project.godot is not accessible, add the binding via InputMap in
CombatArena._ready():
```gdscript
if not InputMap.has_action("heavy_attack"):
    InputMap.add_action("heavy_attack")
    var event = InputEventKey.new()
    event.keycode = KEY_X  # or another unused key
    InputMap.action_add_event("heavy_attack", event)
```

## Slice 3: Fix weapon stat reload on loadout change

Read game/scripts/main.gd. Find _on_loadout_selected() or the loadout signal handler.

After updating GameState.selected_weapon_id, add:
```gdscript
if is_instance_valid(player_controller):
    player_controller.reload_weapon_stats()
```

Also call reload_weapon_stats() in combat arena initialization (after player_controller is created).

## Verification Commands
```bash
grep -n 'heavy_damage\|heavy_attack\|heavy_stamina' game/scripts/core/player_controller.gd
grep -n 'reload_weapon_stats\|selected_weapon_id' game/scripts/main.gd
grep -n 'heavy_attack' game/scenes/combat/combat_arena.gd
```

## Acceptance Criteria
- AC1: heavy_damage and heavy_stamina_cost wired in PlayerController
- AC2: reload_weapon_stats() called on loadout change in main.gd
- AC3: test_heavy_attack.gd test file created (TASK-409 writes it, but structure should be testable)

## Notes
reload_weapon_stats() is the fix for the weapon-swap bug. When the player
changes weapons in FlowUI loadout selector, the combat session previously
kept the old weapon's guard_efficiency, attack costs, etc. After this fix,
all stats reload from the new weapon's data.
Do not hardcode the heavy_attack key — use InputMap to avoid conflicts.
