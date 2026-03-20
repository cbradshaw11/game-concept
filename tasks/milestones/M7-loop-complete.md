# M7: Loop Complete

**Status: DONE**
**Branch: TBD**

---

## Goal

Close the full game loop so a player can win, see what they accomplished, spend accumulated XP on new weapons, and start over with meaningful persistence. Add run history, a victory/extraction screen, XP-gated weapon unlocks, richer encounter template variety, and a deeper upgrade pool with conditional cards that reward specific playstyle choices.

---

## Exit Criteria

- [x] Run history: last 10 runs persist across sessions (save_version 4); ring reached, outcome, and loot banked recorded per run
- [x] Run history screen: renders history list and shows permanent upgrade display
- [x] Victory screen: shown on Warden kill; extraction summary (loot, contracts, rings cleared) displayed
- [x] Weapon unlock: XP spend UI functional; at least 2 unlockable weapons gated behind XP threshold
- [x] Encounter templates: >= 9 templates per ring; seed fix ensures no duplicate composition on same run
- [x] Upgrade pool: >= 12 upgrades in pool; at least 3 conditional upgrades that gate on player stats or prior picks
- [x] Polish: display names on all upgrades; warden phase HUD indicator; upgrade-exhausted toast shown when pool empty
- [x] Test suite: 6 new M7 headless tests pass; zero M6 regressions

---

## Tasks

| ID       | Title                                              | Priority | Area        | Status  | Depends On     |
|----------|----------------------------------------------------|----------|-------------|---------|----------------|
| TASK-701 | Run History Persistence (save_version 4)           | p1       | data        | done    | none           |
| TASK-702 | Run History Screen + Permanent Upgrade Display     | p1       | ui          | done    | none           |
| TASK-703 | Victory Screen and Extraction Summary              | p1       | ui          | done    | none           |
| TASK-704 | XP Spend Weapon Unlock System                      | p1       | progression | done    | none           |
| TASK-705 | Encounter Templates 9/ring + Seed Fix              | p1       | data        | done    | none           |
| TASK-706 | Upgrade Pool Expansion with Conditional Upgrades   | p2       | progression | done    | none           |
| TASK-707 | Polish Pass (names, warden HUD, exhausted toast)   | p2       | ui          | done    | none           |
| TASK-708 | M7 Test Suite                                      | p1       | test        | done    | TASK-701..707  |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-701  Run History Persistence (save_version 4)
  TASK-702  Run History Screen + Permanent Upgrade Display
  TASK-703  Victory Screen and Extraction Summary
  TASK-704  XP Spend Weapon Unlock System
  TASK-705  Encounter Templates 9/ring + Seed Fix
  TASK-706  Upgrade Pool Expansion with Conditional Upgrades
  TASK-707  Polish Pass (names, warden HUD, exhausted toast)

Wave 2 (all Wave 1 complete):
  TASK-708  M7 Test Suite
```

---

## Deferred to M8

- Ranged enemy bow targeting and priority logic
- Run modifier draft system (player-chosen per-run handicaps/bonuses)
- DataStore consolidation -- eliminate raw FileAccess calls from flow_ui
- Abandon-run mechanic (voluntary extraction before Warden)
- Balance pass on upgrade costs and weapon unlock XP thresholds
