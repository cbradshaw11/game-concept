# M18 — Ring 3 Map + Warden Boss Combat

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** shadowBot (overnight session)
**Scope:** Outer ring arena, Warden 3-phase boss, boss gate narrative, artifact win condition

---

## Overview

M18 completes the Outer Ring combat loop and implements the Warden boss — the final guardian standing between the player and the Artifact. The Warden is a purpose-built guardian that has been doing its job for three hundred years and is very good at it. Phase transitions represent escalating effort, not panic.

This milestone connects M17's narrative hooks (warden intro monologue, extraction flavor text) to actual gameplay: the boss gate modal fires before combat, the three-phase system scales damage and cooldowns, and Warden death triggers the Artifact extraction sequence — the MVP win condition.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add `background` and `unlock_condition` to outer ring in rings.json | DONE |
| T2 | Add `damage` and `attack_cooldown` fields to outer_warden in enemies.json | DONE |
| T3 | Implement boss phase system in EnemyController (3 phases, HP thresholds, scaling) | DONE |
| T4 | Add `get_boss(ring_id)` lookup to DataStore | DONE |
| T5 | Add `artifact_retrieved` flag + `retrieve_artifact()` to GameState (save v7 migration) | DONE |
| T6 | Add `get_artifact_text()` to NarrativeManager | DONE |
| T7 | Update CombatArena — boss spawning, phase change signals, boss_defeated signal | DONE |
| T8 | Add Ring 3 button to FlowUI prep screen (unlocked after mid extraction) | DONE |
| T9 | Implement Warden gate modal in FlowUI (sequential text cards from warden_intro) | DONE |
| T10 | Implement artifact victory screen in FlowUI (extraction + artifact flavor text) | DONE |
| T11 | Wire boss encounter flow in main.gd (gate → combat → artifact extraction) | DONE |
| T12 | M18 test suite (3 files, 32 assertions, all green) | DONE |

---

## Boss Phase System

The Warden uses a three-phase system driven by HP thresholds:

| Phase | HP Range | Damage | Attack Cooldown | Behavior |
|-------|----------|--------|-----------------|----------|
| 1 | 100%–70% | 18 (base) | 2.5s | Measured, methodical |
| 2 | 70%–35% | 23 (+25%) | 2.0s (×0.8) | Escalating pressure |
| 3 | <35% | 27 (+50%) | 1.5s (×0.6) | Full commitment |

Phase transitions trigger screen shake (8.0, 0.5s) as a visual signal.

---

## Game Flow: Outer Ring → Warden → Artifact

1. Player completes outer ring contract (5 encounters)
2. Extract button triggers `_trigger_warden_gate()` instead of normal extraction
3. Warden gate modal displays intro monologue from narrative.json
4. Player dismisses gate → boss combat starts (single Warden enemy, 2.5× sprite scale)
5. Warden death → `boss_defeated` signal → artifact extraction sequence
6. `GameState.retrieve_artifact()` banks all XP/loot, sets `artifact_retrieved = true`
7. Artifact victory screen shows outer extraction flavor + artifact flavor text
8. Return to sanctuary — MVP run complete

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `m18_warden_phase_test.gd` | 12 | Phase thresholds, damage scaling, cooldown scaling, death, non-boss isolation |
| `m18_boss_gate_test.gd` | 10 | Warden intro lines, boss data fields, ring config (unlock, background) |
| `m18_artifact_victory_test.gd` | 10 | Artifact flavor text, Warden death flow, phase math, boss spec validation |
| **Total** | **32** | |

---

## Files Changed

- `game/data/rings.json` — outer ring: added `background`, `unlock_condition`
- `game/data/enemies.json` — outer_warden: added `damage`, `attack_cooldown`
- `game/scripts/core/enemy_controller.gd` — boss phase system (setup_boss, phase transitions, scaling)
- `game/autoload/data_store.gd` — added `get_boss(ring_id)`
- `game/autoload/game_state.gd` — `artifact_retrieved` flag, `retrieve_artifact()`, save v7 migration
- `game/autoload/narrative_manager.gd` — added `get_artifact_text()`
- `game/scenes/combat/combat_arena.gd` — boss spawning, phase signals, boss_defeated signal
- `game/scripts/ui/flow_ui.gd` — Ring 3 button, warden gate modal, artifact victory screen
- `game/scripts/main.gd` — warden gate flow, boss encounter wiring, artifact extraction
- `scripts/ci/headless_tests.sh` — M18 test entries

---

## What This Unlocks

With M18 complete, the MVP game loop has a beginning, middle, and end:
- Inner Ring → Mid Ring → Outer Ring → Warden → Artifact
- The player can win
- Narrative and gameplay are fully connected

Next: M19 — Polish pass, balance tuning, final playtesting
