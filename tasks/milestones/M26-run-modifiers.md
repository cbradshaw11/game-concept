# M26 — Run Modifiers: Between-Encounter Modifier Cards

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** 20 run modifier cards across 3 tiers, ModifierManager autoload, between-encounter card offer UI, stat/flag wiring into combat and economy systems

---

## Overview

M26 adds meaningful between-encounter decisions via run modifier cards. After each encounter, the player is offered a randomly selected modifier card (weighted by tier) which they can Accept or Decline. Modifiers persist for the rest of the run, stacking additively. Effects range from simple stat buffs (HP, damage, stamina) to complex tradeoffs (berserk_pact: +30% damage / -20% HP) and run-altering flags (full_commitment blocks extraction, cursed_silver locks vendor).

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add `run_modifiers` array to modifiers.json — 20 modifiers across 3 tiers | DONE |
| T2 | Create ModifierManager autoload — add/has/clear, stat aggregation, weighted roll | DONE |
| T3 | Modifier Card UI — between-encounter modal with Accept/Decline, 12s auto-dismiss | DONE |
| T4 | Wire modifiers into PlayerController (HP/stamina/dodge/damage), RewardSystem (loot), extraction (full_commitment), vendor (cursed_silver) | DONE |
| T5 | Self-review pass — verified autoload order, signal wiring, flag checks | DONE |
| T6 | Test suite (3 files, 29 assertions) | DONE |
| T7 | Milestone summary | DONE |

---

## Modifier Distribution

- **Tier 1 Common (weight 10, 6 cards):** iron_rations, sharp_edge, light_step, quick_hands, thick_skin, silver_eye
- **Tier 2 Uncommon (weight 5, 7 cards):** berserk_pact, glass_armor, adrenaline, overload, extraction_bounty, stamina_well, poise_breaker
- **Tier 3 Rare (weight 2, 7 cards):** death_pact, resonance_surge, last_stand, phantom_dodge, cursed_silver, warden_mark, full_commitment

## Key Changes

- `modifiers.json` — Added `run_modifiers` array with 20 entries (id, name, description, flavor, tier, weight, effects dict)
- `modifier_manager.gd` — New autoload: active modifier tracking, `get_stat_bonus()` for additive stat aggregation, `has_flag()` for boolean effects, `roll_modifier_offer()` weighted selection excluding held modifiers
- `flow_ui.gd` — `show_modifier_card_offer()` displays tiered card modal with Accept/Decline and 12s auto-dismiss timer
- `main.gd` — `_offer_run_modifier()` called after each encounter clear; `full_commitment` blocks extraction; `cursed_silver` blocks vendor
- `player_controller.gd` — `effective_max_hp`, `effective_max_stamina`, `effective_dodge_cost` recalculated on modifier change; `get_damage_multiplier()` and `get_damage_taken_multiplier()` exposed
- `reward_system.gd` — Applies `loot_pct` modifier bonus to encounter loot calculation
- `data_store.gd` — Added `get_run_modifiers()` and `get_run_modifier()` lookup helpers
- `project.godot` — Registered ModifierManager autoload

---

## Deferred to M+1

- Visual card animations (flip, glow by tier rarity)
- Modifier synergy indicators (show when new modifier combos with existing ones)
- Modifier history display on run summary screen
- Combat-triggered modifiers (resonance_surge hit counter, phantom_dodge free dodge tracking, adrenaline HP-on-kill, last_stand threshold check) — data and flags are defined, runtime combat hooks deferred
