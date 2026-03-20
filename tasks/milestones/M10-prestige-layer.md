# M10: Prestige Layer

**Status: DONE**
**Branch: TBD**

---

## Goal

Add meaningful post-completion depth for players who have already killed the Warden. Introduce a prestige XP shop with meta-progression items, a lifetime stats panel, and a warden phase transition signal with HUD feedback. Also clean up content authoring by moving enemy spawn configuration into JSON templates and expanding both the upgrade and modifier pools to increase run variety.

---

## Exit Criteria

- [x] Template-driven spawning: enemy spawn lists defined in encounter JSON; ring_director reads templates at runtime; no hardcoded spawn arrays
- [x] Upgrade pool: deduplication pass complete; >= 16 distinct upgrades in pool
- [x] Modifier pool: >= 9 distinct run modifiers in pool
- [x] Warden phase: phase transition emits a signal; HUD flashes ring indicator on threshold crossing
- [x] Lifetime stats: total runs, total kills, total loot banked displayed on run history screen
- [x] Prestige shop: veteran_spirit, deep_pockets, and warden_insight purchasable with prestige XP; guard prevents purchase before first Warden kill
- [x] Test suite: M10 tests cover template spawning, prestige guard, and lifetime stats; zero M9 regressions

---

## Tasks

| ID        | Title                                              | Priority | Area        | Status  | Depends On      |
|-----------|----------------------------------------------------|----------|-------------|---------|-----------------|
| TASK-1001 | Template-Driven Enemy Spawning                     | p1       | data        | done    | none            |
| TASK-1002 | Upgrade Pool Dedup + 6 New Entries (total 16)      | p1       | progression | done    | none            |
| TASK-1003 | Expand Modifier Pool to 9 Entries                  | p2       | progression | done    | none            |
| TASK-1004 | Warden Phase Transition Signal + HUD Flash         | p1       | combat      | done    | none            |
| TASK-1005 | Lifetime Stats Panel on Run History Screen         | p2       | ui          | done    | none            |
| TASK-1006 | Prestige XP Shop Items                             | p1       | progression | done    | none            |
| TASK-1007 | M10 Test Suite                                     | p1       | test        | done    | TASK-1001..1006 |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-1001  Template-Driven Enemy Spawning
  TASK-1002  Upgrade Pool Dedup + 6 New Entries (total 16)
  TASK-1003  Expand Modifier Pool to 9 Entries
  TASK-1004  Warden Phase Transition Signal + HUD Flash
  TASK-1005  Lifetime Stats Panel on Run History Screen
  TASK-1006  Prestige XP Shop Items

Wave 2 (all Wave 1 complete):
  TASK-1007  M10 Test Suite
```

---

## Deferred to M11

- Ring story beat events (narrative moments tied to specific ring milestones)
- Save version bump for story beat persistence (save_version 6)
- Tutorial quality pass (cleaner first-run guidance, fewer dead ends)
- Mini-boss encounter: warden_herald enemy as pre-Warden gatekeeper
- Seed alias fix in ring_director (named seeds for reproducible testing)
- Vendor button wire-up regression fixes from M10 adversarial pass
