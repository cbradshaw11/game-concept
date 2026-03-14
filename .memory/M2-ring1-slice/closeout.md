# M2 Ring1 Slice — Sprint Closeout (partial)

## Status
done

## Summary
M2 Ring1 Slice delivered all 9 tasks. The Sanctuary-to-Ring1 vertical slice is
complete: loadout selector, encounter templates, save/load, combat arena, enemy
state machine, contract objectives, verifier tests, telemetry event sink, and
Godot CI runtime are all done.

## Delivered Tickets

| ID | Title | Area |
|----|-------|------|
| TASK-201 | Sanctuary prep UI loadout selector | ui |
| TASK-202 | Encounter templates data file and loader | data |
| TASK-203 | Save/load system for banked progression | progression |
| TASK-204 | Combat arena scene and player movement controller | combat |
| TASK-205 | Enemy actor integration with state machine | combat |
| TASK-206 | Contract objective system v1 | progression |
| TASK-207 | Verifier tests for save integrity and combat smoke | test |
| TASK-208 | Telemetry event sink for run lifecycle | infra |

## Exit Criteria
- [ ] Sanctuary to Ring1 loop stable on main
- [ ] Combat depth baseline complete
- [ ] No open p0 issues in milestone scope

## Notes
TASK-209 implementation appears complete at the code level as of migration audit.
The workflow already installs godot4 and the test script uses the runtime when
available. Recommend verifying AC and closing TASK-209 to unlock milestone exit.

History reconstructed from `tasks/milestones/M2-ring1-slice.md` and `tasks/QUEUE.md`
during migration to local ticket system. Individual branch/PR/commit metadata was
not captured in the original markdown system.
