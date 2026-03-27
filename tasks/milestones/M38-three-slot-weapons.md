# M38 — Three-Slot Weapon System

**Status:** DONE

## Goal

Replace single weapon slot with three independent weapon slots (melee / ranged / magic), each with its own input binding, cooldown, and vendor selection UI.

## Exit Criteria

- [x] Three equipped slots in GameState: equipped_melee, equipped_ranged, equipped_magic
- [x] Default loadout: blade_iron (melee), bow_iron (ranged), resonance_staff (magic)
- [x] "category" field on all 10 weapons in weapons.json (5 melee, 2 ranged, 3 magic)
- [x] Three input actions: attack_melee (LMB/Z), attack_ranged (Q), attack_magic (R)
- [x] Independent cooldown timers per slot in combat_arena.gd
- [x] Three OptionButtons in FlowUI (MeleeSelect, RangedSelect, MagicSelect) filtered by category
- [x] HUD debug line: "M: Iron Blade | R: Iron Bow | Mg: Resonance Staff | ..."
- [x] SaveSystem v11 — equipped slots persisted and migrated from old saves
- [x] guard_penetration reads from the attacking slot, not always melee
- [x] Test suite passes (10 tests)

## Tasks

| # | Task | Status |
|---|------|--------|
| 1 | Add "category" field to all 10 weapons in weapons.json | DONE |
| 2 | Add equipped_melee/ranged/magic to GameState (vars, default_save_state, to_save_state, apply_save_state) | DONE |
| 3 | Bump SaveSystem.SAVE_VERSION to 11 | DONE |
| 4 | Replace single weapon in main.gd with three slots, wire loadout_updated signal | DONE |
| 5 | Add attack_melee, attack_ranged, attack_magic input actions to project.godot | DONE |
| 6 | Replace single weapon in combat_arena with three slots + independent cooldowns | DONE |
| 7 | Add _try_slot_attack and _get_weapon_data_for_slot to combat_arena | DONE |
| 8 | Remove light/heavy attack distinction — each slot uses heavy mechanic | DONE |
| 9 | Fix guard_penetration to read from attacking slot | DONE |
| 10 | Build three-category OptionButtons in FlowUI | DONE |
| 11 | Update HUD debug label to show all three equipped weapons | DONE |
| 12 | Remove player_controller attack input (now handled by combat_arena) | DONE |
| 13 | Fix dodge keybinding conflict (Z → Space, was shared with attack_melee) | DONE |
| 14 | Remove legacy "attack" action fallback from combat_arena | DONE |
| 15 | Write M38 test suite (10 tests) | DONE |

## Weapon Category Map

| Category | Weapons |
|----------|---------|
| melee | blade_iron, twin_fangs, polearm_iron, war_hammer, greatsword_iron |
| ranged | bow_iron, crossbow_iron |
| magic | resonance_staff, resonance_orb, void_lance |

## Input Bindings

| Action | Keys |
|--------|------|
| attack_melee | LMB, Z |
| attack_ranged | Q |
| attack_magic | R |
| dodge | Space (unchanged — uses ui_select in player_controller) |
| guard | X (unchanged — uses ui_cancel in player_controller) |

## Deferred to M+1

- Slot-specific cooldown UI indicators in HUD
- Weapon unlock gating per slot in vendor (currently all unlocked weapons available)
- Per-slot stamina cost tuning pass
- Mid-combat slot swap / weapon wheel
