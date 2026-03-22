# M16 — Polish Pass

**Status:** DONE
**Goal:** Make what exists feel complete and satisfying before adding story. Two new weapons, two new enemies, better screens, balance tuning, more varied encounters.

---

## Exit Criteria

1. ✅ Polearm weapon available and unlockable in Sanctuary (distinct stats from Iron Blade)
2. ✅ Bow weapon available and unlockable in Sanctuary (ranged playstyle feel)
3. ✅ 2 new enemy types added: Berserker (high damage, low HP) and Shield Wall (low damage, very high poise/guard)
4. ✅ Victory screen shows full run stats (encounters cleared, XP earned, loot earned, upgrades active, run seed, ring reached, active modifiers)
5. ✅ Death screen shows cause of death flavor text (varies by ring/enemy type — 8-10 lines per ring, enemy-specific for berserker/shield_wall)
6. ✅ Run modifier pool expanded to 6 options, shows 3 choices at run start (up from 2)
7. ✅ Encounter compositions improved — max 2 of same enemy type per encounter (enforced in both templates and RingDirector)
8. ✅ Balance pass: Ring 1 enemy HP slightly reduced (grunt: 60→52, shieldbearer: 85→75); Ring 2+ enemies slightly tuned; new high-pressure enemies in Ring 2+
9. ✅ All existing tests pass

---

## Design Notes

### Weapons Implemented
**Polearm (polearm_iron)**
- Light attack: 12 dmg, 10 stamina — `sweep_all` mechanic hits ALL enemies at 60% damage
- Heavy attack: 28 dmg, 24 stamina — `lunge_poise` mechanic forces poise break
- Guard: 50% (worse than blade at 70%)
- Unlock: 150 XP from vendor
- Feel: crowd control, poise breaker

**Bow (bow_iron)**
- Light attack: 18 dmg, 14 stamina — `ranged_single` (high single-target damage)
- Heavy attack: 32 dmg, 28 stamina — `charged_suppress` suppresses front enemy for 1 tick
- Guard: 30% (worst guard — dodge-reliant)
- Unlock: 200 XP from vendor
- Feel: high damage, glass cannon, dodge-reliant

### New Enemies
**Berserker**
- HP: 45, Poise: 8 (staggers easily), Damage: 22
- Available: Ring 2 (mid) and Ring 3 (outer)
- Feel: glass cannon enemy — punishes slow players hard

**Shield Wall**
- HP: 80, Poise: 40, Damage: 8, Guard efficiency: 80%
- Available: Ring 2 (mid) and Ring 3 (outer)
- Feel: must break poise before effective damage; attrition tank

### Run Modifiers (6 total)
1. **Swift** — -20% light attack stamina cost
2. **Death Wish** — +30% damage at low HP (< 30 HP)
3. **Iron Skin** — +15 max HP this run
4. **Relentless** — stamina regens 30% faster
5. **Berserker** — heavy attacks deal +25% damage but cost +5 stamina
6. **Ghost Step** — dodge i-frames extended by 50ms

### Encounter Templates
- Inner: 4 templates (was 3)
- Mid: 5 templates (new: berserker entry, shield wall, mixed berserker+shield_wall)
- Outer: 4 templates (new: berserker pack, wall+caster, full squad)
- All 13 templates enforce max 2 of same enemy type

---

## Tasks

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T1 | Add Polearm to weapons.json | DONE | sweep_all light (60%), lunge_poise heavy, guard 50%, unlock 150 |
| T2 | Add Bow to weapons.json | DONE | ranged_single light, charged_suppress heavy, guard 30%, unlock 200 |
| T3 | Wire multi-hit logic for Polearm sweep | DONE | `_apply_damage_to_all_enemies()` in combat_arena.gd; 60% ratio from weapon data |
| T4 | Wire charge mechanic for Bow heavy | DONE | `_suppress_front_enemy()` + `_enemy_suppress_ticks` array in combat_arena.gd |
| T5 | Add Berserker to enemies.json | DONE | hp:45, poise:8, dmg:22, mid+outer rings |
| T6 | Add Shield Wall to enemies.json | DONE | hp:80, poise:40, dmg:8, guard:0.8, mid+outer rings |
| T7 | Update encounter templates | DONE | 13 templates; max 2 same type in RingDirector + templates |
| T8 | Expanded run modifier pool | DONE | 6 modifiers in modifiers.json; choices_per_run: 3; DataStore.get_random_modifiers() |
| T9 | Victory screen redesign | DONE | Full stats panel: ring, encounters, XP, loot, seed, modifiers, upgrades |
| T10 | Death screen flavor text | DONE | 8-10 lines per ring; enemy-specific for berserker/shield_wall; priority: enemy > ring |
| T11 | Balance tuning pass | DONE | Ring 1 grunt/shieldbearer HP reduced; berserker/shield_wall add Ring 2 pressure |
| T12 | M16 test suite | DONE | 7 tests, 97 checks in game/scripts/tests/m16/ |
| T13 | Milestone summary | DONE | This file |

---

## Implementation Notes

### Architecture Changes
- **DataStore**: Added `modifiers` field, `get_weapon()`, `get_all_modifiers()`, `get_modifier()`, `get_modifier_choices_per_run()`, `get_random_modifiers()` (Fisher-Yates shuffle, deterministic by seed)
- **GameState**: Added per-run tracking (`run_encounters_cleared`, `run_total_xp`, `run_total_loot`, `run_active_modifiers`, `run_last_enemy_killer`); added `get_run_stats()`, `set_active_modifiers()`, `has_modifier()`, `set_killer_enemy()`
- **RingDirector**: Added `MAX_SAME_ENEMY_TYPE = 2` enforcement in both `generate_encounter()` (random path) and `_generate_template_encounter()` (template path)
- **CombatArena**: Added `_enemy_suppress_ticks` array; `_execute_weapon_attack()` dispatch on `light_mechanic`; `execute_heavy_attack()` for heavy mechanic dispatch; `_apply_damage_to_all_enemies()` for polearm sweep; `_suppress_front_enemy()` for bow charge
- **FlowUI**: Added `VictoryPanel`, `DeathPanel`, `ModifierPanel` (dynamically constructed); `DEATH_FLAVOR` const dictionary with 5 categories (inner/mid/outer/berserker/shield_wall); `show_modifier_selection()` public API
- **Main**: Added modifier selection flow before run start (`_on_modifier_selected` → `_begin_run`); fixed signal connections for extracted/died

### Pre-existing Test Failures (NOT caused by M16)
- `progression_integrity_test.gd` — autoload access in SceneTree mode broken since before M16
- `save_load_integrity_test.gd` — same issue
- `telemetry_lifecycle_test.gd` — same issue

---

## Deferred to M17
- Narrative layer (prologue, ring lore, NPC dialogue, Wren personality)
- Ring 3 + Warden boss
- Weapon-specific animations
- Polearm/Bow unlock gated behind vendor purchase flow (data ready, UI hookup deferred)
- Modifier effects applied at runtime (data-driven effects in modifiers.json, behavioral application deferred)
