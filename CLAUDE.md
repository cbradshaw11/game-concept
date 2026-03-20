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

- **GameState** (`game/autoload/game_state.gd`) - Single source of truth for all run state: current ring, banked/unbanked XP and loot, active upgrades, active modifiers, run history (last 20), and permanent progression. Emits signals (`run_started`, `encounter_completed`, `extracted`, `player_died`) that drive UI and system transitions. Save format is versioned (currently v6) with backward-compatible migration guards.

- **DataStore** (`game/autoload/data_store.gd`) - Loads 7 JSON files on `_ready()`: `rings.json`, `enemies.json`, `weapons.json`, `encounter_templates.json`, `upgrades.json`, `shop_items.json`, `modifiers.json`. All game content is data-driven from these files.

- **SettingsManager** (`game/autoload/settings_manager.gd`) - Persists audio bus volumes and display settings to `user://settings.json`.

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

`FlowUI` (`game/scripts/ui/flow_ui.gd`) manages scene transitions: title → prologue → sanctuary → ring selection → combat → victory/death. Each screen is a subscene loaded by FlowUI in response to GameState signals.

### Script/Scene Layout

```
game/scripts/
├── core/          # PlayerController, EnemyController
├── systems/       # RingDirector, RewardSystem, ContractSystem, SaveSystem, Telemetry
├── ui/            # FlowUI and all screen controllers
├── tests/         # 48+ test files (milestone-scoped under m4/-m13/, combat/ subtests)
└── tools/         # Asset generation

game/scenes/
├── main.tscn              # Root scene
├── combat/combat_arena.tscn
└── ui/                    # One .tscn per screen
```

---

## Testing Conventions

Tests are headless GDScript files that `print("PASS: ...")` or `print("FAIL: ...")`. The CI harness (`scripts/ci/headless_tests.sh`) checks for these markers.

Two test modes used in the harness:
- `run_test` - 60s timeout, hard fail on non-zero exit
- `run_scene_test` - 10s timeout (tolerates Godot physics shutdown hang), parses PASS/FAIL markers

Milestone-scoped tests live under `game/scripts/tests/m4/` through `game/scripts/tests/m13/`. When adding features for a milestone, add tests in the matching subdirectory.

---

## CI

All PRs must pass four GitHub Actions workflows: `headless-tests`, `lint`, `smoke-scene`, and `task-specific-tests`. The Godot import cache (`game/.godot`) is cached in CI for speed. Godot version pinned to 4.2.2 stable in CI (headless binary).

---

## Data Files

All JSON is under `game/data/`. When adding new rings, enemies, or upgrades, update the relevant JSON file rather than hardcoding in GDScript. DataStore exposes typed lookup methods (e.g., `DataStore.get_ring(id)`, `DataStore.get_enemies_for_ring(ring_id)`).

---

## Milestone Summaries

A summary file **must** be written and committed as the final step of every milestone, alongside the test suite commit. No milestone is complete without it.

- Location: `tasks/milestones/MN-<slug>.md`
- Format: matches the existing files in that directory (Goal, Exit Criteria, Tasks table, Wave Dispatch Plan, Deferred to M+1)
- Status: `DONE`
- Commit it with the test suite: `feat: TASK-NNN MN test suite + milestone summary`

Missing summaries break project continuity. M6-M13 had to be reconstructed from git history after the fact because this was skipped.

---

## Save Versioning

When adding fields to GameState, always add a migration guard in the save loading path and increment the save version constant. Check existing v1-v6 migrations in `game_state.gd` as reference.
