# TASK-501 Execution Plan: Upgrade Pass (Per-Run Economy)

## Goal
Add 3-card upgrade draw between Ring 1->2 and Ring 2->3. Upgrades are per-run (not persistent).
Pool of 6 upgrades in upgrades.json. Active upgrades tracked in GameState, applied to PlayerController.

## Depends on: nothing (Wave 1)

## Key Files
- `game/data/upgrades.json` (new — upgrade pool definitions)
- `game/autoload/game_state.gd` (add active_upgrades Array, apply_upgrade(), reset in start_run)
- `game/scripts/core/player_controller.gd` (apply stat modifiers from upgrades)
- `game/scripts/ui/flow_ui.gd` (3-card draw UI logic, trigger after ring completion)
- `game/scenes/ui/flow_ui.tscn` (UpgradeDrawPanel node with 3 UpgradeCard buttons)

## Read Before Implementing
Read these files in full before writing code:
- game/autoload/game_state.gd (understand start_run, extract, die_in_run, to_save_state)
- game/scripts/core/player_controller.gd (understand stat fields: max_health, max_stamina, guard_efficiency, etc.)
- game/scripts/ui/flow_ui.gd (understand state machine: on_idle_ready, on_run_started, on_run_complete, etc.)
- game/data/rings.json (understand which ring IDs trigger upgrade draws)

---

## Slice 1: upgrades.json

Create game/data/upgrades.json:
```json
{
  "upgrades": [
    {
      "id": "iron_constitution",
      "name": "Iron Constitution",
      "description": "Increases maximum health by 20.",
      "stat": "max_health",
      "modifier_type": "add",
      "value": 20
    },
    {
      "id": "veteran_endurance",
      "name": "Veteran Endurance",
      "description": "Increases maximum stamina by 15.",
      "stat": "max_stamina",
      "modifier_type": "add",
      "value": 15
    },
    {
      "id": "reckless_momentum",
      "name": "Reckless Momentum",
      "description": "Light and heavy attacks deal 4 more damage.",
      "stat": "attack_damage",
      "modifier_type": "add",
      "value": 4
    },
    {
      "id": "ironhide_stance",
      "name": "Ironhide Stance",
      "description": "Increases guard efficiency by 5%.",
      "stat": "guard_efficiency",
      "modifier_type": "add",
      "value": 0.05
    },
    {
      "id": "poise_anchor",
      "name": "Poise Anchor",
      "description": "Increases maximum poise by 20.",
      "stat": "max_poise",
      "modifier_type": "add",
      "value": 20
    },
    {
      "id": "swift_recovery",
      "name": "Swift Recovery",
      "description": "Increases stamina regeneration rate by 25%.",
      "stat": "stamina_regen_rate",
      "modifier_type": "multiply",
      "value": 1.25
    }
  ]
}
```

---

## Slice 2: GameState active_upgrades tracking

Read game/autoload/game_state.gd. Add:

```gdscript
var active_upgrades: Array = []  # Array of upgrade dicts, reset each run

func start_run(ring_id: String) -> void:
    active_upgrades = []  # reset at run start
    # ... existing start_run logic

func apply_upgrade(upgrade: Dictionary) -> void:
    active_upgrades.append(upgrade)
    # actual stat application happens in PlayerController
```

Do NOT add active_upgrades to to_save_state() — it is per-run only.

---

## Slice 3: PlayerController upgrade application

Read game/scripts/core/player_controller.gd. Add:

```gdscript
func apply_upgrade(upgrade: Dictionary) -> void:
    var stat = upgrade.get("stat", "")
    var mod_type = upgrade.get("modifier_type", "add")
    var value = upgrade.get("value", 0)
    match stat:
        "max_health":
            max_health += int(value)
            current_health = min(current_health + int(value), max_health)
        "max_stamina":
            max_stamina += value
        "attack_damage":
            # apply to both light and heavy if they exist
            if "attack_damage" in self:
                attack_damage += int(value)
            if "heavy_damage" in self:
                heavy_damage += int(value)
        "guard_efficiency":
            guard_efficiency = min(guard_efficiency + value, 0.95)
        "max_poise":
            max_poise += int(value)
        "stamina_regen_rate":
            if mod_type == "multiply":
                stamina_regen_rate *= value
            else:
                stamina_regen_rate += value
```

Adapt field names to match actual PlayerController fields (read the file first).

---

## Slice 4: FlowUI 3-card draw

In flow_ui.gd, trigger upgrade draw after ring 1 or ring 2 completion (before extract).

```gdscript
func _show_upgrade_draw() -> void:
    var upgrades_data = DataStore.upgrades.get("upgrades", [])  # or load directly
    # Pick 3 random upgrades from pool (no repeats within a draw)
    upgrades_data.shuffle()
    var draw = upgrades_data.slice(0, 3)
    # Populate 3 upgrade card buttons with draw[0], draw[1], draw[2]
    upgrade_card_0.text = "%s\n%s" % [draw[0]["name"], draw[0]["description"]]
    upgrade_card_1.text = "%s\n%s" % [draw[1]["name"], draw[1]["description"]]
    upgrade_card_2.text = "%s\n%s" % [draw[2]["name"], draw[2]["description"]]
    upgrade_draw_panel.visible = true
    # Store draw for selection callbacks
    _current_draw = draw
```

Wire upgrade card button pressed signals to:
```gdscript
func _on_upgrade_card_selected(index: int) -> void:
    var selected = _current_draw[index]
    GameState.apply_upgrade(selected)
    player_controller.apply_upgrade(selected)  # or signal main.gd
    upgrade_draw_panel.visible = false
    # proceed to extract or ring transition
```

Trigger upgrade draw after extract signal from mid/inner (not outer — outer goes to Warden).

---

## Slice 5: Active upgrade display

Add compact label on RunScreen listing active upgrade names:
```gdscript
func _refresh_upgrade_display() -> void:
    if GameState.active_upgrades.is_empty():
        upgrade_list_label.text = ""
    else:
        var names = GameState.active_upgrades.map(func(u): return u["name"])
        upgrade_list_label.text = "Upgrades: " + ", ".join(names)
```

Update on each upgrade selected. Also add to death screen / credits panel:
call `_refresh_upgrade_display()` when showing death screen.

---

## Scene Nodes to Add (flow_ui.tscn)

```
UpgradeDrawPanel (PanelContainer, visible=false)
  VBoxContainer
    Label ("Choose an Upgrade")
    HBoxContainer
      UpgradeCard0 (Button)
      UpgradeCard1 (Button)
      UpgradeCard2 (Button)
RunScreen (existing)
  UpgradeListLabel (Label, text="")
```

---

## Verification Commands
```bash
python3 -c "import json; u=json.load(open('game/data/upgrades.json')); print(len(u['upgrades']))"
grep -n 'active_upgrades\|apply_upgrade' game/autoload/game_state.gd
grep -n 'UpgradeCard\|upgrade_draw\|upgrade_panel' game/scripts/ui/flow_ui.gd
grep -n 'active_upgrades' game/autoload/game_state.gd | grep -v 'to_save_state'
```

## Acceptance Criteria
- AC1: 3-card draw appears; player must select one
- AC2: Selected upgrade modifies PlayerController stats
- AC3: Active upgrades shown on RunScreen and death screen
- AC4: upgrades.json has >= 6 upgrades
- AC5: active_upgrades NOT in to_save_state()

## Notes
If DataStore does not have a `upgrades` accessor, load directly:
```gdscript
var f = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
var upgrades_data = JSON.parse_string(f.get_as_text()).get("upgrades", [])
```
Check how DataStore loads other JSON files (rings.json, weapons.json) and follow the same pattern.
