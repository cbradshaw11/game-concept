# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**The Long Walk** is the MVP implementation for HEARTHWARD, a skill-based dungeon crawler with roguelike progression. Built in Godot 4.6 (GDScript). The main game scene is `res://scenes/main.tscn`.

---

## Commands

### Run a single test (headless)
```bash
godot4 --headless --path game -s res://scripts/tests/<test_file>.gd
# Example:
godot4 --headless --path game -s res://scripts/tests/combat_smoke_test.gd
```

### Run the full test suite
```bash
scripts/ci/headless_tests.sh
```

### Run lint checks
```bash
scripts/ci/lint.sh
```

### Open the game in editor
Open `game/project.godot` in Godot 4.6+. Press F5 to run.

---

## Architecture

### Autoload Singletons (always available globally)

Registered in `project.godot` in dependency order:

1. **SettingsManager** (`game/autoload/settings_manager.gd`) — Persists audio bus volumes and display settings to `user://settings.json`. No dependencies.

2. **GameState** (`game/autoload/game_state.gd`) — Single source of truth for all run state: current ring, banked/unbanked XP and loot, active upgrades, active modifiers, run history (last 20), resonance shards, permanent unlocks, achievement stats, and lifetime progression. Emits signals (`run_started`, `encounter_completed`, `extracted`, `player_died`, `artifact_retrieved_signal`, `fragment_collected`) that drive UI and system transitions. Save format uses merge-with-defaults migration (currently v11 fields covering M21–M32 additions).

3. **DataStore** (`game/autoload/data_store.gd`) — Loads 8 JSON files on `_ready()`: `rings.json`, `enemies.json`, `weapons.json`, `encounter_templates.json`, `upgrades.json`, `shop_items.json`, `modifiers.json`, `achievements.json`. All game content is data-driven from these files.

4. **AudioManager** (`game/autoload/audio_manager.gd`) — SFX and music playback. 17 SFX entries + 7 music tracks. Silent-fail on missing audio files (push_warning, no crash). Creates SFX and Music audio buses at runtime. Depends on SettingsManager for volume levels.

5. **NarrativeManager** (`game/autoload/narrative_manager.gd`) — Loads `narrative.json` and exposes the narrative text API: prologue beats, ring entry/extraction/death flavor, NPC dialogue (Genn vendor), lore fragments, Warden intro. Depends on DataStore.

6. **ModifierManager** (`game/autoload/modifier_manager.gd`) — Run modifier cards. 20 modifiers across 3 tiers loaded from `modifiers.json`. Manages `active_modifiers` array, stat bonus aggregation (`get_stat_bonus()`), boolean flag checks (`has_flag()`). Clears on run start via `run_started` signal. Depends on DataStore, GameState.

7. **ChallengeManager** (`game/autoload/challenge_manager.gd`) — 8 challenge runs with unlock conditions (total_runs, artifact_retrievals thresholds). Enforcement hooks in main.gd (time_pressure timer, warden_hunt extraction block, one_life instant death, naked_run vendor lock, silent_run skip lore/modifiers). `end_run()` clears active challenge. Depends on GameState, DataStore.

8. **AchievementManager** (`game/autoload/achievement_manager.gd`) — 20 local achievements across 4 categories. Connects to GameState signals for automatic checking (`check_after_encounter`, `check_after_extraction`, `check_after_death`, `check_after_artifact`, `check_after_lore_collection`, `check_after_run_start`). Toast notifications via FlowUI. Depends on GameState, ModifierManager, ChallengeManager.

### Game Loop (main.gd)

`game/scripts/main.gd` is the central orchestrator. It instantiates and wires together four systems:
- **RingDirector** - Generates encounters deterministically using `seed(abs(seed + ring_id.hash() + encounters_cleared))`. Two paths: authored templates from `encounter_templates.json` or random enemy picks from ring availability.
- **RewardSystem** - Calculates XP/loot (`base = 20 * enemy_count` XP, `12 * enemy_count` loot) scaled by ring multipliers and active upgrade bonuses.
- **ContractSystem** - Tracks encounters_cleared vs ring_contract_target; blocks extraction until complete.
- **SaveSystem** - Reads/writes `user://savegame.json`. Merges loaded data with defaults to handle missing keys across versions.

### Combat

`game/scenes/combat/combat_arena.tscn` hosts real-time combat. Key controllers:

- **PlayerController** (`game/scripts/core/player_controller.gd`) - CharacterBody2D. Manages health (100 base), stamina (100 base, 18/s regen), poise, guard (% absorption, breaks at 30 damage), and dodge (22 stamina, 220ms i-frames). Applies active upgrades and conditional modifiers.

- **EnemyController** (`game/scripts/core/enemy_controller.gd`) - RefCounted state machine: `IDLE → CHASE → WIND_UP → ATTACK → STAGGER → DEAD`. Boss (Warden) has three phases triggered at 70% and 35% HP, increasing damage by 25%/50% and reducing attack cooldowns.

### UI Layer

`FlowUI` (`game/scripts/ui/flow_ui.gd`) manages scene transitions: title → prologue → sanctuary → ring selection → combat → victory/death. Each screen is a subscene loaded by FlowUI in response to GameState signals. Sanctuary hub has navigation to: Vendor, Resonance Shrine, Challenge Runs, Achievements, Recovered Notes, How to Play, Settings.

### Script/Scene Layout

```
game/scripts/
├── core/          # PlayerController, EnemyController, behavior_profiles
├── systems/       # RingDirector, RewardSystem, ContractSystem, SaveSystem, Telemetry
├── ui/            # FlowUI and all screen controllers (run_summary, title_screen, how_to_play, etc.)
├── tests/         # 70+ test files (milestone-scoped under m4/ through m35/)
│   ├── m4/-m13/   # Core gameplay tests
│   ├── m18/-m24/  # Boss, death, onboarding, stats, economy, fragments, behavior tests
│   └── combat/    # Combat-specific subtests
└── tools/         # Asset generation

game/scenes/
├── main.tscn              # Root scene
├── combat/combat_arena.tscn
└── ui/                    # One .tscn per screen

game/data/                 # All JSON data files
game/audio/                # SFX and music assets (sfx/, music/)
```

---

## Testing Conventions

Tests are headless GDScript files that `print("PASS: ...")` or `print("FAIL: ...")`. The CI harness (`scripts/ci/headless_tests.sh`) checks for these markers.

Two test modes used in the harness:
- `run_test` - 60s timeout, hard fail on non-zero exit
- `run_scene_test` - 10s timeout (tolerates Godot physics shutdown hang), parses PASS/FAIL markers

Milestone-scoped tests live under `game/scripts/tests/m4/` through `game/scripts/tests/m38/`. When adding features for a milestone, add tests in the matching subdirectory.

---

## CI

All PRs must pass four GitHub Actions workflows: `headless-tests`, `lint`, `smoke-scene`, and `task-specific-tests`. The Godot import cache (`game/.godot`) is cached in CI for speed. Godot version pinned to 4.2.2 stable in CI (headless binary).

---

## Data Files

All JSON is under `game/data/`. When adding new rings, enemies, or upgrades, update the relevant JSON file rather than hardcoding in GDScript. DataStore exposes typed lookup methods (e.g., `DataStore.get_ring(id)`, `DataStore.get_enemies_for_ring(ring_id)`). Key data files: `rings.json`, `enemies.json`, `weapons.json`, `encounter_templates.json`, `upgrades.json`, `shop_items.json`, `modifiers.json`, `achievements.json`, `narrative.json`.

---

## Milestone Summaries

A summary file **must** be written and committed as the final step of every milestone, alongside the test suite commit. No milestone is complete without it.

- Location: `tasks/milestones/MN-<slug>.md`
- Format: matches the existing files in that directory (Goal, Exit Criteria, Tasks table, Wave Dispatch Plan, Deferred to M+1)
- Status: `DONE`
- Commit it with the test suite: `feat: TASK-NNN MN test suite + milestone summary`

Missing summaries break project continuity. M6-M13 had to be reconstructed from git history after the fact because this was skipped. Milestones M24–M33 cover the overnight batch (behavior profiles through integration pass). M34 covers save v10 + controls. M35 adds 3 new weapons (Twin Fangs, War Hammer, Resonance Staff) with guard_penetration combat mechanic. M36 adds player attack flash + SFX hooks. M37 is the weapon system overhaul: per-family visual/audio attack distinction (9 families), 4 new weapons (Iron Greatsword, Iron Crossbow, Resonance Orb, Void Lance), and 3 new combat mechanics (ranged_pierce, arcane_burst, drain_stamina). M38 is the three-slot weapon system: melee/ranged/magic slots with independent cooldowns, three input bindings (attack_melee LMB/Z, attack_ranged Q, attack_magic R), category-filtered vendor UI, and save v11.

---

## Save Versioning

GameState uses merge-with-defaults migration: `default_save_state()` defines all fields, and `SaveSystem._merge_with_defaults()` fills missing keys from old saves. `SaveSystem.SAVE_VERSION` is currently **11** (M38), covering all fields through M38 (three-slot weapon loadout: equipped_melee, equipped_ranged, equipped_magic). `save_state()` injects `_save_version` into the save file. When adding fields to GameState, add them to both `default_save_state()` and `to_save_state()`, with a migration guard comment in `apply_save_state()`, and bump `SAVE_VERSION`.
