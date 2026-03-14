# TASK-507 Execution Plan: Per-Ring Contract Targets (Data-Driven)

## Goal
Add contract_target to rings.json (inner=3, mid=4, outer=4).
Update main.gd start_contract call to read from ring data.

## Depends on: nothing (Wave 1)

## Key Files
- `game/data/rings.json` (add contract_target field)
- `game/scripts/main.gd` (read contract_target instead of hardcoding 3)

## Read Before Implementing
Read:
- game/data/rings.json (understand current ring fields and structure)
- game/scripts/main.gd (find the start_contract call, understand how ring data is accessed)

---

## Slice 1: Update rings.json

Read game/data/rings.json. Add contract_target to each combat ring:

```json
{
  "rings": [
    { "id": "sanctuary", "index": 0, ... },
    { "id": "inner", "index": 1, "contract_target": 3, "loot_gate_threshold": 0, ... },
    { "id": "mid", "index": 2, "contract_target": 4, "loot_gate_threshold": 50, ... },
    { "id": "outer", "index": 3, "contract_target": 4, "loot_gate_threshold": 150, ... }
  ]
}
```

Do not add contract_target to sanctuary (it is not a combat ring).
Do not change any other existing fields.

---

## Slice 2: Update main.gd

Find the start_contract call in main.gd. It currently looks something like:
```gdscript
contract_system.start_contract("ring1_clearance", GameState.current_ring, 3)
```

Change it to read from rings data:

```gdscript
# Load ring data to get contract_target
var rings_data = DataStore.rings.get("rings", [])  # or however rings.json is loaded
var ring_data = {}
for r in rings_data:
    if r.get("id") == GameState.current_ring:
        ring_data = r
        break
var contract_target = ring_data.get("contract_target", 3)
contract_system.start_contract("ring_clearance", GameState.current_ring, contract_target)
```

If DataStore does not have a rings accessor, use:
```gdscript
var f = FileAccess.open("res://data/rings.json", FileAccess.READ)
var rings_json = JSON.parse_string(f.get_as_text())
```

Check how other ring data is read in main.gd or flow_ui.gd and follow the same pattern.

---

## Verification Commands
```bash
python3 -c "import json; r=json.load(open('game/data/rings.json')); [print(x['id'], x.get('contract_target','MISSING')) for x in r['rings']]"
grep -n 'contract_target\|start_contract' game/scripts/main.gd
```

## Acceptance Criteria
- AC1: rings.json has contract_target for inner(3), mid(4), outer(4)
- AC2: main.gd reads contract_target from data (no hardcoded 3 in start_contract call)
- AC3: Sanctuary has no contract_target

## Notes
The fallback .get("contract_target", 3) in main.gd ensures backward compatibility
if sanctuary or an unknown ring is somehow passed. Inner stays at 3 (not changed)
because the inner ring is the learning/entry ring and shorter loops are appropriate.
