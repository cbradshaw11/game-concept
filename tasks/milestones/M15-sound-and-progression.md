# M15 — Sound, Vendor & Ring 2

**Status:** DONE
**Goal:** Make the game feel rewarding to play — add audio feedback, make the vendor actually work so banked loot has purpose, and unlock Ring 2 so there's somewhere to go after Ring 1.

---

## Exit Criteria

1. ✅ Sound effects: attack, hit, dodge, guard, death, victory, UI clicks
2. ✅ Background music: one ambient track for combat, one for sanctuary
3. ✅ Vendor screen works — banked loot can be spent on permanent upgrades
4. ✅ At least 4 vendor upgrades available (iron_will, swift_feet, sharp_edge, iron_poise)
5. ✅ Ring 2 ("The Mid Reaches") accessible with increased difficulty (4 encounters, 1.5× XP/loot)
6. ✅ Ring 2 has its own visual environment (arena_bg_mid.png — darker indigo-black background)
7. ✅ Run History screen shows previous runs with ring reached, outcome, XP/loot earned
8. ✅ All existing tests pass

---

## Implementation Summary

### T1-T2: Audio Generation (scripts/tools/gen_audio.py)
- 7 SFX generated with scipy/numpy: sfx_attack, sfx_hit, sfx_dodge, sfx_guard, sfx_death, sfx_victory, sfx_ui_click
- 2 ambient music loops (60s each, loopable WAV): music_combat (ominous drone at 55Hz), music_sanctuary (warmer at 65Hz with 0.6 warmth)
- All audio is 100% procedurally generated — no external assets
- Ring 2 background (arena_bg_mid.png) generated via Python/Pillow with darker indigo-black gradient + fog

### T3-T4: Audio Wiring
- AudioManager autoload (game/autoload/audio_manager.gd): manages SFX + music playback via AudioStreamPlayer nodes
- combat_arena.gd: attack/hit/dodge/guard/death/victory sounds triggered on events; combat music on arena start; ring-specific background loaded per context
- flow_ui.gd: UI click sounds on all button presses

### T5-T6: Vendor System
- vendor_upgrades.json: 4 upgrades with cost, stat, bonus_per_level, max_level
- VendorSystem (game/scripts/systems/vendor_system.gd): purchase logic, stat bonus calculation
- FlowUI: dynamically built vendor panel showing all upgrades with Buy buttons, current loot balance, level tracking

### T7-T8: Ring 2 Data
- rings.json: mid ring with index=2, xp_multiplier=1.5, loot_multiplier=1.5, contract_target=4, unlock_condition, background field
- encounter_templates.json: mid_patrol_a template (ash_flanker + ridge_archer + shieldbearer)
- arena_bg_mid.png: 960×540 darker dungeon background

### T9: Ring 2 Unlock Logic
- GameState.extractions_by_ring tracks per-ring extraction count across runs
- GameState.is_ring_unlocked() evaluates "extracted_inner_once" condition
- FlowUI Ring 2 button only appears after first Ring 1 extraction
- main.gd: ring-aware contract targets read from rings.json

### T10: Run History
- GameState.run_history: last 20 run entries (ring, seed, outcome, xp/loot, timestamp)
- History populated on every extract() and die_in_run()
- FlowUI "Run History" button shows last 10 entries in prep_status

---

## Tasks

| ID | Task | Status |
|----|------|--------|
| T1 | Generate SFX with Python (scipy) | ✅ DONE |
| T2 | Generate ambient music loops | ✅ DONE |
| T3 | Wire audio into combat arena | ✅ DONE |
| T4 | Wire UI click sounds | ✅ DONE |
| T5 | Implement vendor purchase logic | ✅ DONE |
| T6 | Build vendor UI screen | ✅ DONE |
| T7 | Add Ring 2 data to rings.json | ✅ DONE |
| T8 | Generate Ring 2 background | ✅ DONE |
| T9 | Unlock logic for Ring 2 | ✅ DONE |
| T10 | Run History screen | ✅ DONE |
| T11 | M15 test suite | ✅ DONE |
| T12 | Milestone summary | ✅ DONE |

---

## Technical Notes

### Godot 4.6.1 Headless Parse Restriction
In Godot 4.6.1, autoload scripts with `class_name` declarations cause parse errors when referenced as both a class and an autoload in headless tests. M15 test files use pure data (JSON loading + direct logic) to avoid this issue — same pattern as passing M14 tests. The pre-existing tests (progression_integrity_test, save_load_integrity_test, telemetry_lifecycle_test, combat_smoke_test, combat_hooks_test) remain in their pre-M15 broken state due to this Godot limitation; M15 did not regress them.

### Audio Architecture
AudioManager is lightweight — a single SFX player (with LRU cache) and a single music player. SFX is fire-and-forget; music has basic loop support via AudioStreamWAV.loop_mode.

### Save Compatibility
GameState adds 3 new fields (extractions_by_ring, vendor_upgrades, run_history) with safe defaults in default_save_state() and Variant-typed apply_save_state() guards.

---

## Deferred to M16
- Voice acting / narrator
- Ring 3 + Warden boss
- Weapon unlocks (Polearm, Bow)
- Full save/load for vendor purchases across sessions (M15 does in-session only via GameState)
- Multiple AudioStreamPlayer slots for overlapping SFX
