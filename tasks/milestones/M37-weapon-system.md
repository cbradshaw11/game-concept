# M37 — Weapon System Overhaul

**Status:** DONE

## Goal

Expand weapon roster with 4 new weapons (10 total), add per-family visual/audio attack distinction, and implement 3 new combat mechanics.

## Exit Criteria

- [x] 10 weapons in weapons.json (6 existing + 4 new)
- [x] Per-family player flash colors (9 families + default fallback)
- [x] Per-family SFX keys in AudioManager (light + heavy per family, silent-fail)
- [x] Per-family flash durations (dagger=snappy, hammer=slow, others=default)
- [x] 3 new heavy mechanics: ranged_pierce, arcane_burst, drain_stamina
- [x] EnemyController stamina_drained_ticks for Void Lance drain mechanic
- [x] HUD debug label shows current weapon name
- [x] All 4 new weapons in shop_items.json
- [x] All 4 new weapons have flavor text in narrative.json
- [x] Test suite passes

## Tasks

| # | Task | Status |
|---|------|--------|
| 1 | Add 4 new weapons to weapons.json (greatsword_iron, crossbow_iron, resonance_orb, void_lance) | DONE |
| 2 | Add per-family flash color dict + duration overrides to combat_arena.gd | DONE |
| 3 | Add per-family SFX keys (18 new entries) to AudioManager | DONE |
| 4 | Wire _on_attack_triggered and execute_heavy_attack to use family-aware flash/SFX | DONE |
| 5 | Implement ranged_pierce mechanic (crossbow heavy → all enemies at full damage) | DONE |
| 6 | Implement arcane_burst mechanic (orb heavy → all enemies + poise break) | DONE |
| 7 | Implement drain_stamina mechanic (void lance heavy → enemy skips attacks) | DONE |
| 8 | Add stamina_drained_ticks to EnemyController with tick decrement | DONE |
| 9 | Add weapon name to HUD debug label | DONE |
| 10 | Add 4 new weapons to shop_items.json | DONE |
| 11 | Add 4 weapon flavor texts to narrative.json | DONE |
| 12 | Write M37 test suite | DONE |

## New Weapons

| Weapon | Family | Light Mechanic | Heavy Mechanic | Unlock Cost |
|--------|--------|----------------|----------------|-------------|
| Iron Greatsword | greatsword | sweep_all (0.8 ratio) | single_target | 120 |
| Iron Crossbow | crossbow | ranged_single | ranged_pierce (1.0 ratio) | 130 |
| Resonance Orb | orb | single_target | arcane_burst | 140 |
| Void Lance | staff | single_target | drain_stamina | 150 |

## Deferred to M+1

- Per-family hit particles/VFX (requires particle system)
- Actual audio asset creation for per-family SFX (placeholders with silent-fail)
- Weapon upgrade tiers (iron → steel → resonant)
