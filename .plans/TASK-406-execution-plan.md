# TASK-406 Execution Plan: Win Condition Handler and Credits Screen

## Goal
Wire win state: warden_defeated -> narrative card -> credits screen -> stable
PrepScreen. Add game_completed flag. No crash after credits.

## Depends on: TASK-405

## Key Files
- `game/scripts/main.gd` (win state handler, route to credits)
- `game/scripts/ui/flow_ui.gd` (add credits screen / panel)
- `game/scenes/ui/flow_ui.tscn` (add CreditsPanel node)
- `game/autoload/game_state.gd` (add game_completed flag)
- `game/scripts/systems/save_system.gd` (persist game_completed)

## Slice 1: Add game_completed to GameState

Read game/autoload/game_state.gd.

Add:
```gdscript
var game_completed: bool = false
```

In to_save_state(): include "game_completed": game_completed
In apply_save_state(): game_completed = save_data.get("game_completed", false)

## Slice 2: Add win handler in main.gd

Read game/scripts/main.gd.

Add handler triggered after Warden defeat (from TASK-405):
```gdscript
func on_warden_defeated() -> void:
    GameState.warden_defeated = true
    GameState.game_completed = true
    SaveSystem.save()
    flow_ui.show_credits()
```

This may already be partially wired from TASK-405. Confirm the connection and
ensure game_completed is set here.

## Slice 3: Add CreditsPanel to FlowUI

Read game/scripts/ui/flow_ui.gd and game/scenes/ui/flow_ui.tscn.

Add show_credits() method:
```gdscript
func show_credits() -> void:
    _hide_all_panels()
    credits_panel.visible = true
```

CreditsPanel content:
- Title: "The Long Walk"
- Narrative card (Label, multiline):
  "You have retrieved the Sunken Artifact.
   The rings grow quiet.
   The long walk ends here — for now."
- Scrolling credits list (placeholder developer names acceptable)
- "Begin New Journey" button

_on_begin_new_journey() pressed handler:
```gdscript
func _on_begin_new_journey() -> void:
    credits_panel.visible = false
    on_idle_ready()  # return to prep screen
```

In flow_ui.tscn: add CreditsPanel (PanelContainer) with VBoxContainer,
narrative Label, credits Label, and Button.

Set credits_panel.visible = false initially so it does not show on startup.

## Verification Commands
```bash
grep -n 'warden_defeated\|game_completed\|on_warden_defeated' game/scripts/main.gd
grep -n 'credits\|CreditsPanel\|game_completed' game/scripts/ui/flow_ui.gd
grep -n 'game_completed' game/autoload/game_state.gd
```

## Acceptance Criteria
- AC1: main.gd shows win state handling wired to warden_defeated
- AC2: CreditsPanel exists in FlowUI
- AC3: After credits, game reaches stable screen (on_idle_ready)

## Notes
The credits screen does not need to be polished. Placeholder text is fine.
The goal is: no crash, stable state after winning. "Begin New Journey" returns
to PrepScreen. If game_completed is true, the prep screen can show a subtle
indicator (optional, not required for M4 AC).
