# M4: The Road Opens

**Status: DONE**
**Branch: codex/ci-godot-runtime-headless**

---

## Goal

First completable loop: Sanctuary -> Ring 1 -> Ring 2 -> Ring 3 -> Defeat Warden -> Credits.

---

## Exit Criteria

- [x] Ring 1 -> Ring 2 -> Ring 3 -> Warden -> Credits completable without a hard block
- [x] Ring 2 enemies behave observably differently from Ring 1 (at least 2 distinct behavior profiles)
- [x] Ring unlock gates persist through death (rings_cleared survives die_in_run)
- [x] M3 saves load cleanly in M4 (rings_cleared defaults to [], no crash)
- [x] Warden spawns and is defeatable; warden_defeated persists to save
- [x] M4 test suite (5 new tests) passes in CI with zero M3 regressions

---

## Tasks

| ID       | Title                                        | Priority | Area        | Status  | Depends On        |
|----------|----------------------------------------------|----------|-------------|---------|-------------------|
| TASK-401 | Ring selection UI + main.gd decoupling       | p1       | ui          | done    | none              |
| TASK-402 | Ring unlock gates + save schema migration    | p1       | progression | done    | TASK-401          |
| TASK-403 | Enemy behavior profile dispatch              | p1       | combat      | done    | none              |
| TASK-404 | Ring 3 encounter + boss spawn path fix       | p1       | combat      | done    | TASK-402          |
| TASK-405 | Warden boss encounter                        | p1       | combat      | done    | TASK-403, TASK-404|
| TASK-406 | Win condition handler + credits screen       | p1       | ui          | done    | TASK-405          |
| TASK-407 | Heavy attacks + weapon stat reload fix       | p2       | combat      | done    | none              |
| TASK-408 | Loot threshold ring gate                     | p2       | progression | done    | TASK-402          |
| TASK-409 | M4 test suite                                | p1       | test        | done    | all above         |

---

## Wave Dispatch Plan

```
Wave 1 (parallel — no dependencies):
  TASK-401  Ring selection UI + main.gd decoupling
  TASK-403  Enemy behavior profile dispatch
  TASK-407  Heavy attacks + weapon stat reload (p2)

Wave 2 (after TASK-401):
  TASK-402  Ring unlock gates + save migration
  TASK-408  Loot threshold gate (p2, parallel with TASK-402)

Wave 3 (after TASK-402):
  TASK-404  Ring 3 encounter + boss spawn path fix

Wave 4 (after TASK-403 + TASK-404):
  TASK-405  Warden boss encounter

Wave 5 (after TASK-405):
  TASK-406  Win condition + credits screen

Wave 6 (after all above):
  TASK-409  M4 test suite
```

---

## Deferred to M5

- Full shop/vendor UI and upgrade catalog
- Warden boss phases 2 and 3
- Zone system replacement (real 2D positions)
- Balance and tuning for 8-12h target
- Audio, animation, visual polish
- Save schema versioning system
