# M20 — Title Screen & Onboarding

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** Title screen, first-run detection, how to play reference, sanctuary return greeting

---

## Overview

M20 gives the game a proper front door. Previously the game dumped straight into the sanctuary/prologue. Now players see a title screen first, with routing based on whether they're a first-time or returning player. A "How to Play" reference is accessible from the sanctuary, and returning players get a brief Genn greeting toast.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Title screen scene (`title_screen.tscn`) + controller script with cycling flavor lines | DONE |
| T2 | First-run detection (`GameState.is_first_run()`) + main.gd routing (prologue vs sanctuary) | DONE |
| T3 | How to Play screen (`how_to_play.tscn`) + sanctuary button in FlowUI | DONE |
| T4 | Sanctuary return greeting toast (3s auto-dismiss, uses narrative.json sanctuary return lines) | DONE |
| T5 | Test suite (3 files, 25 assertions, all green) | DONE |
| T6 | Milestone summary | DONE |

---

## Title Screen

- Black background, centered layout
- "THE LONG WALK" at 48pt, subtitle "A game set in the world of CAULDRON"
- "Begin" button: routes to prologue (first run) or sanctuary (returning)
- "Continue" button: visible only if save exists (run history or banked resources)
- Cycling flavor lines every 8 seconds from a pool of 4

---

## First-Run Detection

`GameState.is_first_run()` returns true when `run_history` is empty. Combined with the existing `_has_seen_prologue()` file flag, main.gd routes:

| State | Begin action |
|-------|-------------|
| First run + prologue not seen | Prologue → Sanctuary |
| Returning player | Sanctuary directly |

---

## How to Play

Modal overlay launched from a "How to Play" button in the sanctuary prep screen. Contains all control bindings (Move, Dodge, Attack, Guard, Extract) plus gameplay rules (rings/contracts, death penalty). Close button dismisses the overlay.

---

## Sanctuary Return Toast

When `_show_prep()` is called after the initial startup (i.e., returning from a run), a toast label appears at the top of the sanctuary screen with a random line from `narrative.json` `ring_entry.sanctuary.return`. Auto-dismisses after 3 seconds.

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `title_screen_test.gd` | 9 | is_first_run, signals, constants, scene/script existence, main.gd routing |
| `onboarding_flow_test.gd` | 7 | Begin/Continue handlers, prologue routing, is_first_run behavioral |
| `how_to_play_test.gd` | 9 | Scene/script existence, controls content, dismiss, FlowUI button, return toast |
| **Total** | **25** | |

---

## Files Changed

- `game/scripts/ui/title_screen.gd` — new
- `game/scenes/ui/title_screen.tscn` — rewritten (subtitle, buttons, flavor line)
- `game/autoload/game_state.gd` — added `is_first_run()`
- `game/scripts/main.gd` — title screen as entry point, begin/continue routing
- `game/scripts/ui/flow_ui.gd` — How to Play button, sanctuary return toast
- `game/scripts/ui/how_to_play.gd` — new
- `game/scenes/ui/how_to_play.tscn` — new
- `game/scripts/tests/m20/title_screen_test.gd` — new
- `game/scripts/tests/m20/onboarding_flow_test.gd` — new
- `game/scripts/tests/m20/how_to_play_test.gd` — new
- `scripts/ci/headless_tests.sh` — M20 test entries
