# M9: Modifier Live

**Status: DONE**
**Branch: TBD**

---

## Goal

Activate the run modifier system by wiring selected modifiers into combat stat resolution at run start, so modifier choices have tangible in-run consequences. Simultaneously add narrative texture through per-ring briefing text and surface modifier context in the run history screen so players can understand why past runs felt different.

---

## Exit Criteria

- [x] Active modifiers: all modifiers selected during draft are applied to player and enemy stats at run start
- [x] Modifier application: stat deltas verified correct for each modifier entry in the pool; no modifier silently no-ops
- [x] Ring narrative: briefing text shown before entering each ring; text sourced from rings.json per-ring entry
- [x] Run history: modifier names for each run displayed on history screen entry
- [x] Encounter resolution: idempotent -- resolving the same encounter twice does not double-apply rewards
- [x] Player stats: cleared fully on run start; do not accumulate across consecutive runs
- [x] Test suite: M9 tests cover modifier wiring, ring narrative, and history display; zero M8 regressions

---

## Tasks

| ID       | Title                                              | Priority | Area        | Status  | Depends On     |
|----------|----------------------------------------------------|----------|-------------|---------|----------------|
| TASK-901 | Wire Run Modifier Mechanics (apply at run start)   | p1       | progression | done    | none           |
| TASK-902 | Ring Narrative Context (briefing text per ring)    | p1       | data        | done    | none           |
| TASK-903 | Show Modifier Names in Run History                 | p2       | ui          | done    | none           |
| TASK-904 | M9 Test Suite                                      | p1       | test        | done    | TASK-901..903  |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-901  Wire Run Modifier Mechanics (apply at run start)
  TASK-902  Ring Narrative Context (briefing text per ring)
  TASK-903  Show Modifier Names in Run History

Wave 2 (all Wave 1 complete):
  TASK-904  M9 Test Suite
```

---

## Deferred to M10

- Template-driven enemy spawning (spawn config in JSON, not hardcoded)
- Upgrade pool deduplication and pool expansion beyond 12 entries
- Modifier pool expansion beyond initial set
- Warden phase transition signal and HUD flash on threshold crossing
- Lifetime stats panel (total kills, total loot, total runs) on run history screen
- Prestige XP shop items for post-completion meta-progression
