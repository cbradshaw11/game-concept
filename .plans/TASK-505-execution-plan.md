# TASK-505 Execution Plan: Pause Menu and RunScreen Ring Display

## Goal
Add pause menu accessible via Escape during run states. Two buttons: Resume and
Quit to Main Menu. Add ring name label to RunScreen, updated on run start.

## Depends on: nothing (Wave 1)

## Key Files
- `game/scenes/ui/flow_ui.tscn` (add PauseMenu node and RingDisplay label)
- `game/scripts/ui/flow_ui.gd` (Escape key handler, pause logic, ring label update)

## Read Before Implementing
Read:
- game/scripts/ui/flow_ui.gd (understand state machine, existing signal handlers, run states)
- game/scenes/ui/flow_ui.tscn (understand existing node structure, RunScreen location)
- game/autoload/game_state.gd (understand current_ring field and start_run)

---

## Slice 1: Add PauseMenu and RingDisplay to flow_ui.tscn

Add to flow_ui.tscn:

```
[node name="PauseMenu" type="PanelContainer" parent="."]
visible = false
# Set anchors to fill screen or center

[node name="VBoxContainer" type="VBoxContainer" parent="PauseMenu"]

[node name="PausedLabel" type="Label" parent="PauseMenu/VBoxContainer"]
text = "Paused"

[node name="ResumeButton" type="Button" parent="PauseMenu/VBoxContainer"]
text = "Resume"

[node name="QuitButton" type="Button" parent="PauseMenu/VBoxContainer"]
text = "Quit to Main Menu"
```

Also add to the RunScreen section:
```
[node name="RingDisplay" type="Label" parent="RunScreen"]
text = ""
```

Set PauseMenu process_mode = ALWAYS (so it can receive input while tree is paused).

---

## Slice 2: Escape key and pause logic in flow_ui.gd

Add:

```gdscript
@onready var pause_menu: PanelContainer = $PauseMenu
@onready var resume_button: Button = $PauseMenu/VBoxContainer/ResumeButton
@onready var quit_to_menu_button: Button = $PauseMenu/VBoxContainer/QuitButton
@onready var ring_display: Label = $RunScreen/RingDisplay

var _is_paused: bool = false

func _ready() -> void:
    # ... existing _ready() ...
    resume_button.pressed.connect(_on_resume_pressed)
    quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):  # Escape key
        _handle_pause_input()

func _handle_pause_input() -> void:
    # Only allow pause during run states (not IDLE, PREP, CREDITS, UPGRADE_DRAW)
    # Check what state variable flow_ui uses to track current state
    if not _is_in_run_state():
        return
    if _is_paused:
        _unpause()
    else:
        _pause()

func _is_in_run_state() -> bool:
    # Return true only when a run is active (not in menus or credits)
    # Adapt to match flow_ui's actual state tracking
    return GameState.run_active  # or however run state is tracked

func _pause() -> void:
    _is_paused = true
    pause_menu.visible = true
    get_tree().paused = true

func _unpause() -> void:
    _is_paused = false
    pause_menu.visible = false
    get_tree().paused = false

func _on_resume_pressed() -> void:
    _unpause()

func _on_quit_to_menu_pressed() -> void:
    get_tree().paused = false
    _is_paused = false
    pause_menu.visible = false
    GameState.die_in_run()
    on_idle_ready()  # or whatever the return-to-menu function is called
```

---

## Slice 3: Ring display label

```gdscript
func _refresh_ring_display() -> void:
    var ring_names = {
        "inner": "Ring 1 - The Inner Path",
        "mid": "Ring 2 - The Mid Path",
        "outer": "Ring 3 - The Outer Reach"
    }
    ring_display.text = ring_names.get(GameState.current_ring, "")
```

Call `_refresh_ring_display()` when a run starts (in on_run_started() or wherever the
run begin signal is handled).

---

## Verification Commands
```bash
grep -n 'PauseMenu\|pause_menu\|KEY_ESCAPE\|ui_cancel' game/scripts/ui/flow_ui.gd
grep -n 'get_tree.*paused\|tree.*pause' game/scripts/ui/flow_ui.gd
grep -n 'RingDisplay\|ring_label\|ring_display' game/scripts/ui/flow_ui.gd
grep -n 'PauseMenu\|RingDisplay' game/scenes/ui/flow_ui.tscn
```

## Acceptance Criteria
- AC1: Pause menu implementation present in flow_ui.gd
- AC2: get_tree().paused toggle present
- AC3: Ring display label present and updated on run start
- AC4: PauseMenu node in flow_ui.tscn

## Notes
PauseMenu node MUST have process_mode = Node.PROCESS_MODE_ALWAYS (or set in tscn as
process_mode = 3) so that the Resume button can receive input while the tree is paused.
Without this, clicking Resume will not work.

If flow_ui.gd has no explicit run state tracking, infer it from GameState:
  - GameState.run_active (if this flag exists)
  - or check if GameState.current_ring != "sanctuary" and some active_contract flag

Adapt _is_in_run_state() to match what actually exists after reading the file.
