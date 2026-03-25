# M19 — Combat Juice & Feel Polish

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code (overnight session)
**Scope:** Hit stop, screen shake, hit flash, poise break visual, Warden phase VFX, death screen weight, extraction feel

---

## Overview

M19 adds the feedback layer that makes combat feel punchy and satisfying. Everything was mechanically functional after M18, but hits landed with no weight, death was abrupt, and phase transitions were invisible. This milestone adds hit stop (frame freeze), screen shake with tuned magnitudes, colored hit flashes, Warden phase transition VFX, death screen breathing room, and extraction feel polish.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Hit Stop — freeze Engine.time_scale to 0.05 for ~65ms on every landed hit | DONE |
| T2 | Screen Shake — tuned magnitude constants (small=5, medium=8, large=18) | DONE |
| T3 | Enemy Hit Flash — Color(1.5, 0.5, 0.5) hold 1 frame, lerp to white over 0.15s | DONE |
| T4 | Warden Phase Transition Visual — large shake + white flash overlay + log line | DONE |
| T5 | Death Screen Weight — 0.8s delay + narrative death flavor text | DONE |
| T6 | Extraction Feel — 0.5s hold before reward screen + extraction flavor text | DONE |
| T7 | Poise Break Visual — blue-white flash Color(0.8, 0.8, 2.0) for 0.2s | DONE |
| T8 | Test suite (3 files, 26 assertions, all green) | DONE |
| T9 | Milestone summary | DONE |

---

## Hit Stop System

When any hit lands (player → enemy or enemy → player), `Engine.time_scale` drops to 0.05 for 65ms then restores. The timer runs in unscaled time so the duration is consistent regardless of time scale. Hit stop is the single most impactful feel improvement — it gives every hit weight.

---

## Screen Shake Magnitudes

| Context | Magnitude | Duration |
|---------|-----------|----------|
| Player taking damage | 5.0 (small) | 0.3s |
| Enemy death | 8.0 (medium) | 0.3s |
| Warden phase transition | 18.0 (large) | 0.5s |
| Regular hit on enemy | 5.0 (small) | 0.12s |

Shake now only overrides if the new shake is stronger than the current one, preventing small shakes from cutting off large ones.

---

## Hit Flash Types

| Flash Type | Color | Duration | Trigger |
|------------|-------|----------|---------|
| Normal hit | Color(1.5, 0.5, 0.5) | 1 frame hold + 0.15s lerp | Damage dealt to enemy |
| Poise break | Color(0.8, 0.8, 2.0) | 0.2s solid | Enemy enters STAGGER state |
| Warden phase | Color(1.5, 0.5, 0.5) | 0.3s hold | Warden crosses HP threshold |

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `hit_feedback_test.gd` | 10 | Hit stop duration, time scale, shake magnitudes, flash colors, durations |
| `phase_transition_test.gd` | 8 | Warden phase thresholds (70%/35%), damage/cooldown scaling, death |
| `death_screen_test.gd` | 8 | Death delay >= 0.8s, DEATH_FLAVOR for all rings, narrative death flavor |
| **Total** | **26** | |

---

## Files Changed

- `game/scenes/combat/combat_arena.gd` — hit stop, flash system rewrite, phase flash overlay, shake constants
- `game/scripts/main.gd` — death screen delay (0.8s), extraction hold delay (0.5s)
- `game/scripts/ui/flow_ui.gd` — narrative death flavor text, extraction flavor text on victory panel
- `game/scripts/tests/m19/hit_feedback_test.gd` — new
- `game/scripts/tests/m19/phase_transition_test.gd` — new
- `game/scripts/tests/m19/death_screen_test.gd` — new
- `scripts/ci/headless_tests.sh` — M19 test entries

---

## What This Unlocks

With M19 complete, combat has the feedback layer needed for playtesting. Every hit has weight, phase transitions are visible events, and death/extraction have breathing room. The game is ready for balance tuning (M20).
