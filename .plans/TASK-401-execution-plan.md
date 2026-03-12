# TASK-401 Execution Plan: Ring Selection UI and main.gd Decoupling

## Goal
Remove hardcoded "inner" strings from main.gd combat flow (lines 41, 51, 62).
Add ring selector to FlowUI PrepScreen. Wire selected ring through to all
ring-dependent logic. Ring 3 visible but disabled (placeholder gate).

## Depends on: nothing (Wave 1)

## Key Files
- `game/scripts/main.gd` (lines 41, 51, 62 — three hardcoded "inner" strings)
- `game/scripts/ui/flow_ui.gd` (add ring selector to PrepScreen section)
- `game/scenes/ui/flow_ui.tscn` (add RingSelector node)
- `game/autoload/game_state.gd` (current_ring field already exists)
- `game/data/rings.json` (read-only — ring IDs and display names)

## Slice 1: Remove hardcoded strings from main.gd

Read game/scripts/main.gd and find all three "inner" occurrences:
- Line ~41: start_run call passes "inner" as ring param
- Line ~51: encounter spawning uses "inner"
- Line ~62: reward calculation uses "inner"

Replace each with `GameState.current_ring`. GameState.current_ring defaults to
"inner" so first-run behavior is unchanged.

Verify: `grep -n '"inner"' game/scripts/main.gd` returns no results in combat flow.

## Slice 2: Add ring selector to FlowUI

Read game/scripts/ui/flow_ui.gd and game/scenes/ui/flow_ui.tscn.
Find the PrepScreen section / on_idle_ready() flow.

Add RingSelector (OptionButton or ItemList) to PrepScreen:
- Option 0: "Ring 1 — The Inner Way" (always enabled, value="inner")
- Option 1: "Ring 2 — The Mid Path" (disabled until TASK-402, value="mid")
- Option 2: "Ring 3 — The Outer Reaches" (disabled, value="outer")

On ring selection change: `GameState.current_ring = ring_id`

In flow_ui.tscn: add RingSelector OptionButton under PrepScreen container.
In flow_ui.gd: @onready var ring_selector and _on_ring_selected() handler.

Ring 2 and 3 should be set disabled=true for now (TASK-402 wires real gate logic).
Add a comment: # Gate logic wired in TASK-402

## Verification Commands
```bash
grep -n '"inner"' game/scripts/main.gd
grep -n 'ring_selector\|RingSelector\|current_ring' game/scripts/ui/flow_ui.gd
grep -n 'current_ring' game/scripts/main.gd
```

## Acceptance Criteria
- AC1: No hardcoded "inner" in main.gd combat flow
- AC2: FlowUI PrepScreen has ring selector control
- AC3: Ring 3 option visible but disabled

## Notes
GameState.current_ring already exists. Default is "inner". Only need to ensure
that all three main.gd sites read GameState.current_ring instead of the literal.
Do not change the start_run() signature — just pass GameState.current_ring.
