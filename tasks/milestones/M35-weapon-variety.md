# M35: Weapon Variety Expansion

**Status: DONE**
**Date Completed:** 2026-03-26

---

## Goal

Add 3 new weapons with distinct playstyles to expand combat variety beyond the existing Iron Blade, Polearm, and Bow.

---

## Exit Criteria

- [x] Twin Fangs (dual daggers) added to `weapons.json` — fast attack_cooldown (0.6), low damage (8), moderate poise (15)
- [x] War Hammer (heavy two-hander) added to `weapons.json` — slow attack_cooldown (1.8), high damage (28), high poise (40)
- [x] Resonance Staff (magic-adjacent) added to `weapons.json` — mid attack_cooldown (1.1), mid damage (15), guard_penetration 0.3
- [x] `guard_penetration` field added to all weapons (default 0.0 for existing)
- [x] Guard penetration combat math in `combat_arena.gd` — bypasses fraction of enemy guard absorption
- [x] Weapon flavor text added to `narrative.json` under `weapons` key
- [x] `shop_items.json` created with all 3 weapons at correct silver costs (80/90/100)
- [x] DataStore loads `shop_items.json` with `get_shop_items()` / `get_shop_item()` lookups
- [x] Tests pass: `test_weapons_m35.gd`

---

## Tasks

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 1 | Add Twin Fangs, War Hammer, Resonance Staff to weapons.json | `game/data/weapons.json` | DONE |
| 2 | Add `guard_penetration` field to all weapons (0.0 default) | `game/data/weapons.json` | DONE |
| 3 | Implement guard_penetration in combat damage math | `game/scenes/combat/combat_arena.gd` | DONE |
| 4 | Add weapon flavor text to narrative.json | `game/data/narrative.json` | DONE |
| 5 | Create shop_items.json with weapon entries | `game/data/shop_items.json` | DONE |
| 6 | Update DataStore to load shop_items.json | `game/autoload/data_store.gd` | DONE |
| 7 | Write M35 test suite | `game/scripts/tests/m35/test_weapons_m35.gd` | DONE |
| 8 | Write milestone summary | `tasks/milestones/M35-weapon-variety.md` | DONE |

---

## Deferred to M+1

- Weapon-specific heavy attack mechanics for new weapons (e.g., dagger flurry, hammer slam AoE, staff resonance blast)
- Weapon selection UI in sanctuary
- Weapon unlock persistence in save state
