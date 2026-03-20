# TASK-408 Execution Plan: Loot Threshold Ring Access Gate

## Goal
Add loot_gate_threshold per ring in rings.json. Gate ring selector in FlowUI
so rings requiring loot show as locked when GameState.banked_loot is below
threshold. Both gates (rings_cleared from TASK-402 AND loot threshold) must pass.

## Depends on: TASK-402

## Loot Thresholds
- inner (Ring 1): threshold = 0 (always accessible, no loot required)
- mid (Ring 2): threshold = 50
- outer (Ring 3): threshold = 150
- sanctuary: not in selector

## Key Files
- `game/data/rings.json` (add loot_gate_threshold to each ring)
- `game/scripts/ui/flow_ui.gd` (add loot gate check to ring selector)
- `game/autoload/game_state.gd` (read-only — banked_loot field)

## Slice 1: Update rings.json

Read game/data/rings.json. Add loot_gate_threshold to each ring entry:
```json
{
  "rings": [
    { "id": "sanctuary", "index": 0, ... },
    { "id": "inner", "index": 1, "loot_gate_threshold": 0, ... },
    { "id": "mid", "index": 2, "loot_gate_threshold": 50, ... },
    { "id": "outer", "index": 3, "loot_gate_threshold": 150, ... }
  ]
}
```

Do not change any other ring fields. Only add loot_gate_threshold.

## Slice 2: Add loot gate check to FlowUI

Read game/scripts/ui/flow_ui.gd. Find _refresh_ring_selector() from TASK-402.

Extend the gate logic to also check loot threshold:
```gdscript
func _refresh_ring_selector() -> void:
    var rings_data = DataStore.rings.get("rings", [])
    var rings_map = {}
    for r in rings_data:
        rings_map[r.get("id")] = r

    # inner: always accessible
    ring_selector.set_item_disabled(0, false)

    # mid: requires rings_cleared AND loot
    var mid_loot = rings_map.get("mid", {}).get("loot_gate_threshold", 50)
    var mid_locked = "inner" not in GameState.rings_cleared \
        or GameState.banked_loot < mid_loot
    ring_selector.set_item_disabled(1, mid_locked)

    # outer: requires rings_cleared AND loot
    var outer_loot = rings_map.get("outer", {}).get("loot_gate_threshold", 150)
    var outer_locked = "mid" not in GameState.rings_cleared \
        or GameState.banked_loot < outer_loot
    ring_selector.set_item_disabled(2, outer_locked)
```

Optionally update item text to show requirement when locked:
```gdscript
if mid_locked:
    ring_selector.set_item_text(1, "Ring 2 (requires %d loot)" % mid_loot)
else:
    ring_selector.set_item_text(1, "Ring 2 — The Mid Path")
```

## Verification Commands
```bash
python3 -c "import json; r=json.load(open('game/data/rings.json')); [print(x['id'], x.get('loot_gate_threshold','MISSING')) for x in r.get('rings',[])]"
grep -n 'loot_gate\|loot_threshold\|banked_loot' game/scripts/ui/flow_ui.gd
```

## Acceptance Criteria
- AC1: rings.json has loot_gate_threshold per ring
- AC2: Locked ring shows threshold message in FlowUI
- AC3: Gate check uses GameState.banked_loot comparison

## Notes
Both gates (rings_cleared AND loot) must both pass for a ring to be selectable.
inner ring threshold is 0, so it is always accessible regardless of banked_loot.
DataStore needs to expose rings data. Check if DataStore.rings exists, or if
rings.json is accessed differently. If DataStore doesn't have a rings accessor,
load directly: FileAccess.open("res://data/rings.json", ...).
