# M21 — Run Summary Screen + Stats Tracking

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** Run summary screen, persistent stats tracking, personal bests

---

## Overview

M21 gives every run a proper ending. Previously death and extraction routed to minimal panels with limited information. Now all three run outcomes (death, extraction, artifact retrieval) route through a unified run summary screen that shows detailed combat stats, silver/XP earned, run duration, and all-time lifetime stats. A personal best system highlights new records (deepest ring, fastest extraction, first artifact).

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Run stats tracking in GameState (save v8, lifetime + per-run stats) | DONE |
| T2 | Run summary scene + controller (`run_summary.tscn` / `run_summary.gd`) | DONE |
| T3 | Wire summary into FlowUI (replaces old victory/death panels for routing) | DONE |
| T4 | Personal best tracking (deepest ring, fastest run, first artifact badges) | DONE |
| T5 | Test suite (3 files, 47 assertions, all green) | DONE |
| T6 | Milestone summary | DONE |

---

## Run Stats Tracking (T1)

### Lifetime stats (persisted in save file, v8 migration)
- `total_runs` — incremented on every run end
- `total_extractions` — incremented on clean extraction or artifact
- `total_deaths` — incremented on death
- `deepest_ring_reached` — "inner" | "mid" | "outer" (all-time best, never downgrades)
- `artifact_retrievals` — times the Warden was defeated
- `fastest_extraction_seconds` — best extraction time (0 = no record)

### Per-run stats (`current_run_stats` dictionary, reset on `start_run`)
- `rings_cleared`, `enemies_killed`, `damage_taken`, `damage_dealt`
- `silver_earned`, `silver_spent`, `run_duration_seconds`, `extraction_ring`

### Wiring
- `record_enemy_killed()` called from `combat_arena.gd` on enemy death
- `record_damage_dealt()` called from `combat_arena.gd` on player attack
- `record_damage_taken()` called from `combat_arena.gd` on enemy attack
- `record_silver_spent()` called from `purchase_upgrade()` in GameState
- `silver_earned` tracked in `add_unbanked()`
- Duration computed from `_run_start_time` on run finalization

---

## Run Summary Screen (T2 + T3)

Unified screen for all three outcomes. Header changes based on outcome:
- Death: "RUN COMPLETE"
- Extraction: "EXTRACTED"
- Artifact: "ARTIFACT RETRIEVED"

Layout (VBoxContainer in ScrollContainer):
1. Header
2. Run stats block (ring reached, enemies killed, damage dealt/taken, silver, duration, XP)
3. All-time stats (total runs, extractions, deaths, deepest ring, artifacts)
4. Personal best badges (shown/hidden conditionally)
5. Flavor text from NarrativeManager
6. Two buttons: "Run Again" (sanctuary) and "Title" (title screen)

FlowUI routing: `on_extracted`, `on_died`, and `show_artifact_victory` all call `_show_run_summary(outcome)`.

---

## Personal Bests (T4)

`GameState.get_personal_bests(outcome)` returns an Array of badge strings:
- "Personal Best: Deepest Ring" — when a new deepest ring is reached
- "Personal Best: Fastest Run" — when extraction time beats the record
- "First Artifact Retrieved" — on first Warden defeat

Badges displayed as a label block on the run summary, visible only when earned.

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `run_stats_test.gd` | 16 | Stats reset, increment, save/load round-trip, v8 migration guard |
| `run_summary_test.gd` | 18 | Scene/script existence, headers, signals, FlowUI routing, stats display |
| `personal_best_test.gd` | 13 | Ring depth ordering, deepest ring updates, fastest extraction, artifact tracking |
| **Total** | **47** | |

---

## Files Changed

- `game/autoload/game_state.gd` — lifetime stats, per-run stats, combat helpers, personal bests, save v8
- `game/scenes/combat/combat_arena.gd` — damage_dealt, damage_taken, enemy_killed tracking
- `game/scripts/ui/run_summary.gd` — new
- `game/scenes/ui/run_summary.tscn` — new
- `game/scripts/ui/flow_ui.gd` — run summary integration, return_to_title signal
- `game/scripts/main.gd` — return_to_title handler
- `game/scripts/tests/m21/run_stats_test.gd` — new
- `game/scripts/tests/m21/run_summary_test.gd` — new
- `game/scripts/tests/m21/personal_best_test.gd` — new
- `scripts/ci/headless_tests.sh` — M21 test entries

---

## What This Unlocks

- **M22+**: Leaderboard/scoring systems can build on lifetime stats
- **M22+**: Run history screen can show detailed per-run breakdowns
- **M22+**: Achievement system can hook into personal bests
