# M8: Modifier Foundation

**Status: DONE**
**Branch: TBD**

---

## Goal

Lay the structural groundwork for run modifiers -- player-chosen per-run conditions that add challenge or grant bonuses -- without yet wiring their effects into combat. Also improve enemy combat intelligence by giving bow enemies proper ranged priority targeting, and eliminate the last raw FileAccess calls from flow_ui by consolidating all persistence through DataStore.

---

## Exit Criteria

- [x] Bow enemy: selects farthest-from-melee target when multiple enemies present; kite behavior activates at range threshold
- [x] Modifier draft: player is presented a draft of run modifiers before entering Ring 1; selection persists in save (save_version 5)
- [x] Modifier draft UI: renders modifier cards with name and description; selection confirmed before run starts
- [x] DataStore migration: flow_ui.gd contains no direct FileAccess calls; all reads/writes routed through DataStore
- [x] Abandon run: player can voluntarily extract; partial loot banked; run recorded in history as abandoned
- [x] Test suite: M8 tests cover modifier draft persistence, bow targeting, and abandon-run; zero M7 regressions

---

## Tasks

| ID       | Title                                              | Priority | Area        | Status  | Depends On     |
|----------|----------------------------------------------------|----------|-------------|---------|----------------|
| TASK-801 | Bow Ranged Priority Targeting                      | p1       | combat      | done    | none           |
| TASK-802 | Run Modifier Draft System (save_version 5)         | p1       | progression | done    | none           |
| TASK-803 | DataStore Migration (remove FileAccess/flow_ui)    | p1       | data        | done    | none           |
| TASK-804 | M8 Test Suite                                      | p1       | test        | done    | TASK-801..803  |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-801  Bow Ranged Priority Targeting
  TASK-802  Run Modifier Draft System (save_version 5)
  TASK-803  DataStore Migration (remove FileAccess/flow_ui)

Wave 2 (all Wave 1 complete):
  TASK-804  M8 Test Suite
```

---

## Deferred to M9

- Wiring active_modifiers into actual combat stat effects at run start
- Ring narrative briefing text shown before entering each ring
- Modifier names surfaced in run history entries
- Balance tuning on modifier draft pool size and individual modifier magnitudes
