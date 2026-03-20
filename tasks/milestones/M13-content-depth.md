# M13: Content Depth

**Status: DONE**
**Branch: TBD**

---

## Goal

Expand the content surface area across every system that players interact with repeatedly: more vendor options per run, a deeper upgrade pool, death flavor text that contextualizes where you fell, and a new enemy behavior profile for ranged snipers. The goal is that no two runs feel identical in their available choices, and that dying in Ring 3 reads differently than dying in Ring 1.

---

## Exit Criteria

- [x] Vendor: per-run pool expanded from 3 to 7 items; no duplicate items within a single vendor visit
- [x] Upgrade pool: expanded from 16 to 21 cards; all new cards have display names and descriptions
- [x] Death flavor text: per-ring flavor strings defined in rings.json; death panel renders correct ring-contextual text
- [x] warden_herald solo template: standalone encounter template for warden_herald in outer ring; does not pull from standard pool
- [x] void_sniper: sniper_volley behavior profile implemented; kite dead zone documented with push_warning on unknown profile
- [x] Critical shop bugs resolved: stat names correct in buy confirmation; no stale stat applied on purchase
- [x] stamina_on_kill: HUD correctly emits stat update signal after proc; no silent no-op
- [x] Test suite: M13 tests cover vendor pool size, upgrade descriptions, and death flavor text; zero M12 regressions

---

## Tasks

| ID        | Title                                              | Priority | Area        | Status  | Depends On      |
|-----------|----------------------------------------------------|----------|-------------|---------|-----------------|
| TASK-1301 | Scoping / Planning (no deliverable commit)         | p2       | planning    | done    | none            |
| TASK-1302 | kite_volley Dead Zone Doc + push_warning           | p2       | combat      | done    | none            |
| TASK-1303 | Expand Vendor Per-Run Pool (3 -> 7 items)          | p1       | progression | done    | none            |
| TASK-1304 | Expand Upgrade Pool (16 -> 21 cards)               | p1       | progression | done    | none            |
| TASK-1305 | Death Flavor Text per Ring                         | p1       | data        | done    | none            |
| TASK-1306 | Solo warden_herald Template + sniper_volley Profile| p1       | combat      | done    | none            |
| TASK-1307 | M13 Test Suite                                     | p1       | test        | done    | TASK-1302..1306 |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-1301  Scoping / Planning
  TASK-1302  kite_volley Dead Zone Doc + push_warning
  TASK-1303  Expand Vendor Per-Run Pool (3 -> 7 items)
  TASK-1304  Expand Upgrade Pool (16 -> 21 cards)
  TASK-1305  Death Flavor Text per Ring
  TASK-1306  Solo warden_herald Template + sniper_volley Profile

Wave 2 (all Wave 1 complete):
  TASK-1307  M13 Test Suite
```

---

## Deferred to M14

- Environmental art differentiation per ring (distinct visual language for inner/mid/outer)
- Ambient audio per ring (layered soundscape distinct from combat music)
- Accessibility pass: colorblind mode, font size options, input remapping
- New enemy archetype: shielder or support role to disrupt current combat meta
- Difficulty modes or scaling options beyond the modifier system
- Controller / gamepad input support
