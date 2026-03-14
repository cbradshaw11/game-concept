# TASK-506 Execution Plan: Bank on Death - Partial Loot Retention

## Goal
Modify GameState.die_in_run() to retain 25% of unbanked_loot into banked_loot.
Compute retained before clearing unbanked_loot to zero.

## Depends on: nothing (Wave 1)

## Key Files
- `game/autoload/game_state.gd` (modify die_in_run())

## Read Before Implementing
Read:
- game/autoload/game_state.gd (find die_in_run(), understand what it currently does,
  understand all fields: unbanked_loot, banked_loot, current_run state)

---

## Implementation

Find die_in_run() in game_state.gd. It currently likely:
1. Emits a death signal or calls a callback
2. Clears run state (current_ring, unbanked_loot, etc.)
3. May call save

Insert at the TOP of die_in_run(), before any clearing:

```gdscript
func die_in_run() -> void:
    # Retain 25% of unbanked loot even on death
    var retained: int = int(unbanked_loot * 0.25)
    banked_loot += retained
    # ... rest of existing die_in_run() logic unchanged ...
```

Do NOT change anything else in die_in_run(). The retained value must be computed
before unbanked_loot is set to 0 (if that happens in the existing code).

---

## Verification Commands
```bash
grep -n '0.25\|retained\|die_in_run' game/autoload/game_state.gd
grep -n 'rings_cleared' game/autoload/game_state.gd
```

## Acceptance Criteria
- AC1: Retention logic inside die_in_run()
- AC2: banked_loot += retained before unbanked_loot cleared
- AC3: rings_cleared NOT reset by die_in_run() (existing M4 behavior)

## Notes
This is a 3-line change. Read die_in_run() first to understand the existing
sequence of operations, then insert the 2 retention lines at the top.
The order matters: retained = int(unbanked_loot * 0.25) must happen when
unbanked_loot still has its run value, before any cleanup sets it to 0.
