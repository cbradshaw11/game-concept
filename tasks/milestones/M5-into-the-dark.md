# M5: Into the Dark

**Status: DONE**
**Branch: TBD**

---

## Goal

Polish and balance the MVP to support an 8-12 hour average clear time (total invested playtime across all failed runs until first Warden kill). Add per-run upgrade economy, content volume, Warden phases, audio readability floor, pause menu, and progression improvements.

---

## Exit Criteria

- [x] Upgrade pass: 3-card draw appears between Ring 1-2 and Ring 2-3; >= 6 upgrades in pool; per-run (not persistent)
- [x] Content: >= 5 distinct templates per ring; 0 duplicate compositions; python3 check_content_volume.py exits 0
- [x] Enemy roster: inner >= 4, mid >= 5, outer >= 5 native enemy types in enemies.json
- [x] Warden: phases 2+3 trigger at 70%/35% HP thresholds; warden_phase_reached persists to save
- [x] Audio: 4 combat readability sounds present in game/audio/; enemy attack telegraph (WIND_UP) implemented
- [x] UI: Pause menu accessible via Escape, preserves run state; current ring shown persistently on RunScreen
- [x] Progression: die_in_run() banks 25% of unbanked_loot
- [x] Progression: contract targets data-driven from rings.json (inner=3, mid=4, outer=4)
- [x] Save: save_version: 1 in all new saves; M4 saves migrate cleanly with correct defaults
- [x] Test suite: 6 new M5 tests pass; zero M4 regressions; check_content_volume.py passes

---

## Tasks

| ID       | Title                                              | Priority | Area        | Status  | Depends On     |
|----------|----------------------------------------------------|----------|-------------|---------|----------------|
| TASK-501 | Upgrade Pass (per-run economy)                     | p1       | progression | done    | none           |
| TASK-502 | Content Volume Pass (templates + enemies)          | p1       | data        | done    | none           |
| TASK-503 | Warden Phases 2+3 (+ save_version: 1)              | p1       | combat      | done    | none           |
| TASK-504 | Audio: Combat Readability Floor                    | p1       | audio       | done    | none           |
| TASK-505 | Pause Menu + RunScreen Ring Display                | p2       | ui          | done    | none           |
| TASK-506 | Bank on Death: Partial Loot Retention              | p2       | progression | done    | none           |
| TASK-507 | Per-Ring Contract Targets (Data-Driven)            | p2       | data        | done    | none           |
| TASK-508 | M5 Test Suite                                      | p1       | test        | done    | TASK-501..507  |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-501  Upgrade Pass (per-run economy)
  TASK-502  Content Volume Pass (templates + enemies)
  TASK-503  Warden Phases 2+3 (+ save_version: 1)
  TASK-504  Audio: Combat Readability Floor
  TASK-505  Pause Menu + RunScreen Ring Display
  TASK-506  Bank on Death (25% loot retention)
  TASK-507  Per-Ring Contract Targets (data-driven)

Wave 2 (all Wave 1 complete):
  TASK-508  M5 Test Suite
```

---

## Deferred to M6

- Full shop/vendor UI with currency, vendor NPC, and upgrade catalog
- Persistent/meta-progression upgrades across runs
- Sector-based zone system (multi-flank spatial positioning)
- Music, ambient audio, UI sounds, footsteps, environmental sounds
- Settings menu, volume controls, key rebinding
- Environmental art differentiation between rings
- Content density beyond minimum viable (9+ templates per ring)
- Balance tuning for completion rate optimization
