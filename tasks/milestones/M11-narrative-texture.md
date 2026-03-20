# M11: Narrative Texture

**Status: DONE**
**Branch: TBD**

---

## Goal

Add the story layer that makes the rings feel like a place rather than an abstraction. Wire ring story beat events that fire at meaningful progression milestones, persist seen beats to save, and display them as modal narrative moments. Introduce the warden_herald as a mini-boss gatekeeper encounter before the final ring, and improve first-run clarity with a tutorial quality pass.

---

## Exit Criteria

- [x] Story beats: ring milestone events defined in rings.json; modal shown once per beat; rings_story_seen persists to save (save_version 6)
- [x] Story beats: typed Array[String] for rings_story_seen; no duplicate fires on re-entry
- [x] Tutorial: first-run guidance covers movement, dodge, guard, and upgrade pick; tutorial dismiss works without soft-lock
- [x] Seed alias: ring_director resolves named seed aliases; fallback path does not throw on unknown alias
- [x] warden_herald: spawns as solo encounter in outer ring before Warden fight; excluded from standard template pool; damage and phase wired correctly
- [x] Vendor: vendor button wire-up functional after M10 regression; loot retention display shows correct held amount
- [x] Test suite: M11 tests cover story beats, warden_herald exclusion, and seed alias; zero M10 regressions

---

## Tasks

| ID        | Title                                              | Priority | Area        | Status  | Depends On      |
|-----------|----------------------------------------------------|----------|-------------|---------|-----------------|
| TASK-1101 | Vendor Button Wire-up Fix                          | p1       | ui          | done    | none            |
| TASK-1102 | Balance Tuning Pass                                | p2       | balance     | done    | none            |
| TASK-1103 | Ring Story Beat Events + save_version 6            | p1       | data        | done    | none            |
| TASK-1104 | Tutorial Quality Pass                              | p1       | ui          | done    | none            |
| TASK-1105 | Seed Alias Fix in ring_director                    | p2       | data        | done    | none            |
| TASK-1106 | Mini-Boss: warden_herald Encounter                 | p1       | combat      | done    | none            |
| TASK-1107 | M11 Test Suite                                     | p1       | test        | done    | TASK-1101..1106 |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-1101  Vendor Button Wire-up Fix
  TASK-1102  Balance Tuning Pass
  TASK-1103  Ring Story Beat Events + save_version 6
  TASK-1104  Tutorial Quality Pass
  TASK-1105  Seed Alias Fix in ring_director
  TASK-1106  Mini-Boss: warden_herald Encounter

Wave 2 (all Wave 1 complete):
  TASK-1107  M11 Test Suite
```

---

## Deferred to M12

- M11 carryover bugs: total_runs display off-by-one, story modal pause guard, modal min-size constraint, tutorial dismiss edge cases
- Warden Phase 3 attack cooldown tuning for survivability
- Ring-differentiated combat music architecture with per-ring track and fallback
- Orphaned ATTACK state guard in enemy state machine
- Guard counter crash on rapid input
