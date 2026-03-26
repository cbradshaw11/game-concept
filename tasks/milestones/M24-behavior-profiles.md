# M24 — Enemy Behavior Profiles

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** 8 distinct enemy behavior profiles wired from data, profile-specific AI in EnemyController

---

## Overview

M24 makes the `behavior_profile` field in `enemies.json` meaningful. Previously all enemies shared identical chase-and-attack behavior; now each profile sets distinct combat parameters and special abilities. Players can read enemy types and adapt tactics: guard_counter punishes reckless attacks, kite_volley maintains distance, zone_control denies area, poise_gate_tank requires sustained pressure, and elite_pressure scales with player vulnerability.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Behavior profile system in EnemyController — `apply_profile()` method, 8 profiles with distinct chase/attack ranges, cooldowns, and special mechanics | DONE |
| T2 | Wire profiles from DataStore — combat_arena reads `behavior_profile` and `poise` from enemy data, connects death_explosion, handles zone damage and kite retreat | DONE |
| T3 | `behavior_profiles.gd` constants file — prevents magic strings for all 8 profile names | DONE |
| T4 | Self-review pass — fixed poise accumulation system, guard_counter absorption + counter-attack, guard timer preventing repeated rolls | DONE |
| T5 | Test suite (3 files, 32+ assertions) | DONE |
| T6 | Milestone summary | DONE |

---

## Profile Behaviors

| Profile | Enemy | Chase | Attack Range | Cooldown | Special Mechanic |
|---------|-------|-------|-------------|----------|-----------------|
| frontline_basic | scavenger_grunt | 5.0 | 1.5 | 1.5s | None (baseline) |
| guard_counter | shieldbearer | 4.0 | 1.8 | 2.0s | 40% chance to guard, absorbs hit + counter-attacks |
| flank_aggressive | ash_flanker | 7.0 | 1.6 | 1.2s | Prefers flanking offset |
| kite_volley | ridge_archer | 8.0 | 5.0 | 2.5s | Retreats if player < 3.0, melee fallback when cornered |
| zone_control | rift_caster | 6.0 | 4.0 | 3.5s | 2.5s damage zone after attack (4 dps within radius 2.5) |
| glass_cannon_aggro | berserker | 9.0 | 1.4 | 0.8s | Death explosion (8 dmg within 2 units) |
| poise_gate_tank | shield_wall | 3.5 | 1.6 | 2.2s | Poise threshold 60 (requires multiple hits to stagger) |
| elite_pressure | warden_hunter | 8.0 | 2.0 | 1.0s | Poise immune, +20% damage when player < 50% HP |

---

## Key Implementation Details

- **Poise accumulation**: Added `_poise_damage_accumulated` tracking. Stagger only triggers when accumulated poise damage >= `poise_threshold`. Resets after stagger. Default threshold is 1 (preserves existing behavior where any poise-break hit staggers).
- **Guard counter**: Shieldbearers have a 40% chance to enter guard state when player is in attack range. While guarding, incoming hits are absorbed and the enemy counter-attacks immediately. Guard lasts 1.5s and prevents re-rolling during guard.
- **Kite retreat**: New `RETREAT` enemy state. Kiters flee when player gets within 3.0 units. If cornered (at arena edge), switch to melee fallback (range 1.5, cooldown 1.0) for 2s then resume kiting.
- **Zone control**: After each attack, a damage zone activates for 2.5s. Players within 2.5 units take 4 damage/second. Combat arena applies zone damage each tick.
- **Death explosion**: Glass cannon emits `death_explosion` signal on kill. Combat arena connects this and applies 8 damage if player within 2 zones.
- **Elite pressure**: Immune to poise break. Damage scales +20% when player is below 50% HP, tracked via `set_player_hp_percent()` called each tick.

---

## Files Modified

- `game/scripts/core/enemy_controller.gd` — behavior profile system, new states (RETREAT, GUARD), poise accumulation, profile-specific update methods
- `game/scripts/core/behavior_profiles.gd` — NEW, profile name constants
- `game/scenes/combat/combat_arena.gd` — profile wiring, zone damage tick, kite retreat handling, guard counter absorption, death explosion handler

## Test Files

- `game/scripts/tests/m24/behavior_profile_test.gd` — 15 assertions across all 8 profiles
- `game/scripts/tests/m24/kite_behavior_test.gd` — 8 assertions for retreat, fallback, expiry
- `game/scripts/tests/m24/zone_control_test.gd` — 9 assertions for zone activation, damage, expiry
