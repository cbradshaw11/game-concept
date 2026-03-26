# M30 — Resonance Wraith: Phase-Cycling Outer Ring Enemy

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** New enemy type (resonance_wraith) with phase_phantom behavior profile, vulnerability cycling, visual feedback, 2 new encounter templates

---

## Overview

M30 adds the Resonance Wraith — a phantom-type outer ring enemy that cycles between invulnerable and vulnerable phases. While invulnerable, the Wraith absorbs all incoming damage (no HP reduction) but can still attack the player. Players must read phase transition visual cues and time their attacks to the vulnerability window. This forces timing-based play rather than sustained DPS, creating a distinct combat challenge from all existing enemies.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add resonance_wraith to enemies.json — phantom role, outer ring, 95 HP, 18 dmg, phase_phantom profile | DONE |
| T2 | phase_phantom behavior profile — chase_range 7, attack_range 1.8, phase cycling with invulnerable/vulnerable windows | DONE |
| T3 | Visual feedback in CombatArena — immune flash (blue-white), vulnerable flash (gold), invulnerable flash (dark blue) | DONE |
| T4 | 2 new outer ring encounter templates: Phantom Screen (wraith + hunter), Twin Phantoms (2x wraith) | DONE |
| T5 | Self-review pass — verified phase timer ticks, damage absorption, signal wiring, visual feedback | DONE |
| T6 | Test suite — 3 files: wraith_phase_test, wraith_signal_test, wraith_encounter_test | DONE |
| T7 | Milestone summary | DONE |

---

## Key Changes

### Data
- `game/data/enemies.json` — Added resonance_wraith entry with phase_duration (2.5s), vulnerable_duration (1.8s), phase_cycle_start: invulnerable
- `game/data/encounter_templates.json` — Added outer_phantom_screen (weight 4) and outer_twin_phantoms (weight 3)

### Core
- `game/scripts/core/behavior_profiles.gd` — Added PHASE_PHANTOM constant to profiles list
- `game/scripts/core/enemy_controller.gd` — New signals (damage_absorbed, phase_vulnerable, phase_invulnerable), phase_phantom variables (phase_timer, is_vulnerable, phase_duration, vulnerable_duration), apply_profile case, _update_phase_phantom() timer cycling, set_phase_durations() helper, apply_damage() immunity guard

### Combat Arena
- `game/scenes/combat/combat_arena.gd` — Phase flash color constants (PHASE_IMMUNE_FLASH_COLOR, PHASE_VULNERABLE_FLASH_COLOR, PHASE_INVULNERABLE_FLASH_COLOR), signal handlers (_on_damage_absorbed, _on_phase_vulnerable, _on_phase_invulnerable), flash type rendering in _update_hit_flashes(), immunity detection in both _apply_damage_to_front_enemy() and _apply_damage_to_all_enemies()

### Phase Cycle Mechanics
- Starts invulnerable for 2.5s → vulnerable for 1.8s → repeats
- While invulnerable: apply_damage() returns without reducing health, emits damage_absorbed
- While invulnerable: Wraith can still attack the player (normal tick behavior)
- While vulnerable: takes damage normally, can be killed
- Phase transitions emit phase_vulnerable / phase_invulnerable signals for visual feedback

---

## Encounter Templates

| Template | Enemies | Weight | Design Intent |
|----------|---------|--------|---------------|
| Phantom Screen | 1x resonance_wraith, 1x warden_hunter | 4 | Hunter forces engagement while wraith phases |
| Twin Phantoms | 2x resonance_wraith | 3 | Timing puzzle — desynchronized phase cycles |

---

## Deferred to M+1

- Wraith-specific sprite asset (currently uses archetype sprite cycling)
- Audio cues for phase transitions (distinct from existing SFX)
- Wraith encounter in mid ring (currently outer only)
- Visual particle effects for phase shimmer / ghosting
