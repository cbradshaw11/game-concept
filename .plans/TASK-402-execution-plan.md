# TASK-402 Execution Plan: Ring Unlock Gates and Save Schema Migration

## Goal
Add rings_cleared: Array[String] to GameState. Populate on extract(). Persist
in save schema with safe M3 migration. Gate ring selector in FlowUI based on
rings_cleared content.

## Depends on: TASK-401

## Key Files
- `game/autoload/game_state.gd` (add rings_cleared field, populate in extract())
- `game/scripts/systems/save_system.gd` (include in save/load schema)
- `game/scripts/ui/flow_ui.gd` (gate ring selector options)
- `game/data/rings.json` (read-only — ring IDs for gate mapping)

## Slice 1: Add rings_cleared to GameState

Read game/autoload/game_state.gd.

Add field:
```gdscript
var rings_cleared: Array[String] = []
```

In extract() (called when player successfully leaves a ring):
```gdscript
if current_ring != "sanctuary" and current_ring not in rings_cleared:
    rings_cleared.append(current_ring)
```

In die_in_run(): DO NOT clear rings_cleared. Only reset unbanked_xp, unbanked_loot,
encounters_cleared.

In to_save_state() (or equivalent):
```gdscript
"rings_cleared": rings_cleared,
```

In apply_save_state() (or from_save_state):
```gdscript
rings_cleared = save_data.get("rings_cleared", [])
```
The .get() with default [] is the M3 migration safety.

## Slice 2: Add save system support

Read game/scripts/systems/save_system.gd.
Confirm rings_cleared is included in whatever dict GameState exports.
If save_system has its own field list, add "rings_cleared" there.

## Slice 3: Wire gate logic into FlowUI ring selector

Read game/scripts/ui/flow_ui.gd.
Find the ring selector added by TASK-401. Replace the placeholder disabled=true
with actual gate logic:

```gdscript
func _refresh_ring_selector() -> void:
    # inner: always accessible
    ring_selector.set_item_disabled(0, false)
    # mid: requires "inner" in rings_cleared
    ring_selector.set_item_disabled(1, "inner" not in GameState.rings_cleared)
    # outer: requires "mid" in rings_cleared
    ring_selector.set_item_disabled(2, "mid" not in GameState.rings_cleared)
```

Call _refresh_ring_selector() in on_idle_ready() and after extract/die flows.

## Verification Commands
```bash
grep -n 'rings_cleared' game/autoload/game_state.gd
grep -n 'rings_cleared' game/scripts/systems/save_system.gd
grep -n 'rings_cleared' game/scripts/ui/flow_ui.gd
python3 -c "import json; s=json.load(open('game/save_state.json')) if __import__('os').path.exists('game/save_state.json') else {}; print(s.get('rings_cleared', 'SAFE_DEFAULT_OK'))"
```

## Acceptance Criteria
- AC1: rings_cleared declared in GameState, populated in extract(), in save schema
- AC2: Loading M3 save without rings_cleared key defaults to [] without crash
- AC3: Ring 2 disabled when rings_cleared does not contain "inner"

## Notes
Death must NOT clear rings_cleared. This is persistent run-to-run progress.
The migration is safe because apply_save_state() uses .get("rings_cleared", []).
If save_system.gd uses an explicit field list, add rings_cleared there too.
