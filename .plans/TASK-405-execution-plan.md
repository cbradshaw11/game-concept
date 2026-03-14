# TASK-405 Execution Plan: Warden Boss Encounter

## Goal
Add warden_defeated flag to GameState. Add "Descend to Warden" trigger in FlowUI
for Ring 3 final encounter. Wire CombatArena._spawn_boss("outer_warden") to
spawn the Warden. Warden defeat sets warden_defeated = true and persists to save.

## Depends on: TASK-403 (behavior profiles), TASK-404 (boss spawn helper)

## Key Files
- `game/autoload/game_state.gd` (add warden_defeated flag)
- `game/scripts/systems/save_system.gd` (persist warden_defeated)
- `game/scenes/combat/combat_arena.gd` (use _spawn_boss helper from TASK-404)
- `game/scripts/ui/flow_ui.gd` (add "Descend to Warden" option)
- `game/scripts/main.gd` (wire warden_defeated on enemy death)
- `game/data/enemies.json` (read-only — outer_warden stats)

## Slice 1: Add warden_defeated to GameState

Read game/autoload/game_state.gd.

Add field:
```gdscript
var warden_defeated: bool = false
```

warden_defeated must survive die_in_run() (permanent progress — once defeated, stays defeated).
Include in to_save_state() and apply_save_state() with .get("warden_defeated", false) default.

## Slice 2: Add "Descend to Warden" trigger in FlowUI

Read game/scripts/ui/flow_ui.gd.

After the encounter extraction flow for Ring 3, or as part of the between-encounter
menu, show a "Descend to Warden" button when:
- GameState.current_ring == "outer"
- GameState.encounters_cleared >= 3 (or some threshold — use 3)
- NOT GameState.warden_defeated (no point descending again)

```gdscript
func _refresh_warden_option() -> void:
    var show = GameState.current_ring == "outer" \
        and GameState.encounters_cleared >= 3 \
        and not GameState.warden_defeated
    descend_warden_button.visible = show
```

When pressed, emit a signal or call main.gd to start a Warden encounter.

## Slice 3: Wire Warden spawn in CombatArena

In game/scenes/combat/combat_arena.gd, add a method:
```gdscript
func start_boss_encounter(boss_id: String) -> void:
    var boss = _spawn_boss(boss_id)
    if boss == null:
        return
    # Apply behavior profile via the same match block
    _apply_behavior_profile(boss)
    # Add to active enemies list
    _active_enemies = [boss]
    boss.attack_resolved.connect(func(dmg): _apply_damage_to_player(dmg))
    _update_enemy_display()
```

In main.gd, handle the "descend to warden" signal from FlowUI:
```gdscript
func _on_descend_to_warden() -> void:
    _ensure_combat_arena()
    combat_arena.start_boss_encounter("outer_warden")
    # Show combat arena, hide flow UI
```

When the Warden's health reaches 0 (enemy_defeated signal or similar):
```gdscript
func _on_warden_defeated() -> void:
    GameState.warden_defeated = true
    SaveSystem.save()
    flow_ui.show_credits()  # TASK-406 wires this
```

## Verification Commands
```bash
grep -n 'warden_defeated' game/autoload/game_state.gd
grep -n 'warden_defeated\|_spawn_boss\|start_boss_encounter' game/scenes/combat/combat_arena.gd
grep -n 'warden\|Descend' game/scripts/ui/flow_ui.gd
python3 -c "import json; e=json.load(open('game/data/enemies.json')); warden=[x for x in e.get('bosses',[]) if x['id']=='outer_warden'][0]; print('HP:', warden['health'])"
```

## Acceptance Criteria
- AC1: "Descend to Warden" option in FlowUI after Ring 3 encounters threshold
- AC2: warden_defeated flag in GameState, persists in save
- AC3: Warden HP loaded from enemies.json (1200) not hardcoded

## Notes
Warden uses elite_pressure profile from TASK-403 dispatch.
enemies.json outer_warden stats: health=1200, damage=22, poise_damage=35.
The on_warden_defeated handler should call flow_ui.show_credits() but credits
screen content is TASK-406. This task just needs to set warden_defeated and
call the credits entrypoint. Add a placeholder show_credits() to FlowUI if not
yet added by TASK-406.
warden_defeated must survive die_in_run() -- do NOT reset it on death.
