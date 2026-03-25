# M23 — Lore Fragment Pickups + Recovered Notes Archive

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** Lore fragment drop integration, pickup modal, sanctuary archive, run summary counter

---

## Overview

M23 surfaces the five lore fragments defined in narrative.json as in-game collectibles. Fragments drop as rare pickups (15% chance) after ring encounters, with duplicate protection and a stop condition once all five are collected. A "RECOVERED NOTE" modal displays the fragment text after combat. The sanctuary gains a "Recovered Notes" archive button for re-reading collected fragments, and the run summary screen shows a "Notes Recovered: X / 5" counter.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add `collected_fragments` to GameState with v9 save/load migration guard | DONE |
| T2 | Fragment drop logic (15% chance, no duplicates, stops at 5) + pickup modal in FlowUI | DONE |
| T3 | "Recovered Notes" archive button in sanctuary (visible only when fragments collected) | DONE |
| T4 | "Notes Recovered: X / 5" counter on run summary screen with "First Note!" badge | DONE |
| T5 | Test suite (3 files, 23+ assertions) | DONE |
| T6 | Milestone summary | DONE |

---

## Fragment Drop Logic (T1, T2)

- `GameState.roll_fragment_drop(encounter_seed)` — seeded RNG, 15% chance, picks from uncollected fragments only, returns "" when all 5 collected
- `GameState.collect_fragment(fragment_id)` — adds to `collected_fragments` and `current_run_fragments`, emits `fragment_collected` signal
- `GameState.has_fragment(fragment_id)` — lookup helper
- Drop is wired in `main.gd._on_encounter_cleared()` after reward resolution
- Save version bumped to v9 with migration guard for `collected_fragments: Array`

## Pickup Modal (T2)

- `FlowUI.show_fragment_pickup(fragment)` — full-screen overlay (z_index 12)
- Header: "RECOVERED NOTE" in warm gold
- Fragment title in accent purple, author attribution below
- Scrollable body text in parchment tone
- "Pocket It" dismiss button, emits `fragment_pickup_dismissed` signal

## Recovered Notes Archive (T3)

- "Recovered Notes" button added to sanctuary PrepScreen via `_setup_recovered_notes_button()`
- Button visibility refreshed on every `_show_prep()` call — hidden until first fragment collected
- Archive overlay shows header with "RECOVERED NOTES (X / 5)" count
- Each fragment displayed as collapsible entry: click title to expand/collapse full text
- Fragments listed in collection order

## Run Summary Counter (T4)

- `FragmentLabel` node added to RunSummary `_build_ui()`
- Shows "Notes Recovered: X / 5" when any fragments collected
- "First Note!" badge displayed if `current_run_fragments` contains `fragment_001`
- Warm gold accent color matching the pickup modal

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `fragment_drop_test.gd` | 5 | 15% rate validation, no duplicates, stop-at-full, fragment field completeness |
| `fragment_state_test.gd` | 8 | save/load round-trip, v9 migration guard, has_fragment, current_run_fragments |
| `fragment_ui_test.gd` | 10 | display data quality, ID conventions, UI method presence, signal wiring, run summary integration |
| **Total** | **23** | |

---

## Files Changed

- `game/autoload/game_state.gd` — `collected_fragments`, `current_run_fragments`, v9 migration, drop/collect helpers, `fragment_collected` signal
- `game/scripts/ui/flow_ui.gd` — `show_fragment_pickup()`, `_show_recovered_notes()`, `_setup_recovered_notes_button()`, button visibility refresh
- `game/scripts/ui/run_summary.gd` — `FragmentLabel` node, "Notes Recovered" counter, "First Note!" badge
- `game/scripts/main.gd` — fragment drop wiring in `_on_encounter_cleared()`
- `game/scripts/tests/m23/fragment_drop_test.gd` — new
- `game/scripts/tests/m23/fragment_state_test.gd` — new
- `game/scripts/tests/m23/fragment_ui_test.gd` — new
- `scripts/ci/headless_tests.sh` — M23 test entries

---

## What This Unlocks

- **M24+**: Fragment-gated content (e.g., hidden dialogue with Genn after collecting all 5)
- **M24+**: Ring-specific fragment theming (fragments already have `ring` field for contextual drops)
- **M24+**: Achievement system integration (collect-all-fragments achievement)
