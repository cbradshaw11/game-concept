# TASK-308 Execution Plan: Death Screen and Run Summary

## Goal
When player_died fires, overlay a death screen panel on FlowUI showing run summary: ring reached, encounters cleared, unbanked XP/loot lost. "Return to Sanctuary" button resets and returns to prep screen.

## Depends on: TASK-301 (player_died signal), TASK-302 (combat produces meaningful run data)

## Current State
- `main.gd._on_player_died()` already exists and calls `flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)`
- `flow_ui.on_died()` may already exist but lacks death screen panel
- GameState tracks current_ring, unbanked_xp, unbanked_loot
- No death_panel Control node exists in flow_ui.tscn

## Implementation Steps

### Step 1: Add death_panel Control node to flow_ui.tscn
File: `game/scenes/ui/flow_ui.tscn`

Add a Control overlay anchored to fill the screen:
```
[node name="DeathPanel" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15  # full rect

  [node name="VBox" type="VBoxContainer" parent="DeathPanel"]
    [node name="TitleLabel" type="Label" parent="DeathPanel/VBox"]
    text = "YOU DIED"

    [node name="RingLabel" type="Label" parent="DeathPanel/VBox"]
    [node name="EncountersLabel" type="Label" parent="DeathPanel/VBox"]
    [node name="XPLabel" type="Label" parent="DeathPanel/VBox"]
    [node name="LootLabel" type="Label" parent="DeathPanel/VBox"]

    [node name="ReturnButton" type="Button" parent="DeathPanel/VBox"]
    text = "Return to Sanctuary"
```

### Step 2: Implement on_died() in flow_ui.gd
File: `game/scripts/ui/flow_ui.gd`

Add node references:
```gdscript
@onready var death_panel = $DeathPanel
@onready var ring_label = $DeathPanel/VBox/RingLabel
@onready var encounters_label = $DeathPanel/VBox/EncountersLabel
@onready var xp_label = $DeathPanel/VBox/XPLabel
@onready var loot_label = $DeathPanel/VBox/LootLabel
@onready var return_button = $DeathPanel/VBox/ReturnButton
```

Implement or update on_died():
```gdscript
func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
    ring_label.text = "Ring Reached: %d" % GameState.current_ring
    encounters_label.text = "Encounters Cleared: %d" % GameState.encounters_cleared
    xp_label.text = "XP Lost: %d" % unbanked_xp
    loot_label.text = "Loot Lost: %d" % unbanked_loot
    death_panel.visible = true
```

### Step 3: Wire Return to Sanctuary button
In `_ready()`:
```gdscript
return_button.pressed.connect(_on_return_to_sanctuary)

func _on_return_to_sanctuary() -> void:
    death_panel.visible = false
    on_idle_ready()  # existing method — resets to prep screen
```

### Step 4: Check if GameState.encounters_cleared exists
File: `game/autoload/game_state.gd`

If missing, add:
```gdscript
var encounters_cleared: int = 0
```

It should already exist given telemetry tracking from M2, but verify.

### Step 5: Extend main.gd call signature if needed
If encounters_cleared is not accessible from GameState directly, extend the on_died call:
```gdscript
flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)
# GameState.current_ring and encounters_cleared read directly inside on_died()
```

## Key Files
- `game/scripts/ui/flow_ui.gd` (primary — implement on_died, wire panel)
- `game/scenes/ui/flow_ui.tscn` (primary — add DeathPanel node)
- `game/autoload/game_state.gd` (read-only or add encounters_cleared if missing)
- `game/scripts/main.gd` (read-only — already calls on_died)

## Acceptance Criteria
- FlowUI has on_died() that shows death_panel with run summary
- Panel shows ring reached, encounters cleared, XP lost, loot lost
- "Return to Sanctuary" button calls on_idle_ready() to reset to prep
- Panel is hidden by default, shown only on death
