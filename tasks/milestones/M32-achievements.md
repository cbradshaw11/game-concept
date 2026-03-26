# M32 — Achievements: Local Achievement Tracking

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** 20 local achievements, AchievementManager autoload, toast notifications, sanctuary gallery, lifetime stat tracking

---

## Overview

M32 adds a local achievement system that gives players recognition for milestones they hit naturally and some they have to hunt for. 20 achievements across 4 categories (First Steps, Combat Mastery, Progression, Secrets) are tracked entirely locally in GameState with no external service dependency. Achievements unlock via signal-driven checks after meaningful game events, display a toast notification overlay, and are browsable in a sanctuary gallery.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Create achievements.json with 20 achievements across 4 categories | DONE |
| T2 | Create AchievementManager autoload + update GameState save (v11) | DONE |
| T3 | Achievement toast notification overlay (top-center, 4s auto-dismiss) | DONE |
| T4 | Achievement gallery in sanctuary (grouped by category, progress display) | DONE |
| T5 | Self-review — verify all trigger points and timing | DONE |
| T6 | Test suite — 3 files: achievement_data_test, achievement_manager_test, achievement_progress_test | DONE |
| T7 | Milestone summary | DONE |

---

## Achievements

| ID | Name | Category | Hidden | Condition |
|----|------|----------|--------|-----------|
| first_blood | First Blood | First Steps | No | Complete first encounter |
| first_extraction | First Extraction | First Steps | No | Extract for first time |
| first_death | A Learning Experience | First Steps | No | Die for first time |
| first_mid | Mid Reaches | First Steps | No | Reach the Mid Ring |
| first_artifact | The Long Walk | First Steps | No | Retrieve the Artifact |
| poise_master | Poise Master | Combat Mastery | No | 50 lifetime poise breaks |
| no_damage_encounter | Ghost | Combat Mastery | Yes | Complete encounter with 0 damage taken |
| warden_survivor | Survived the Warden | Combat Mastery | No | Retrieve Artifact (beat Warden) |
| kill_count_100 | Veteran | Combat Mastery | No | 100 lifetime kills |
| kill_count_500 | Itinerant | Combat Mastery | No | 500 lifetime kills |
| ten_runs | Ten Runs | Progression | No | Complete 10 runs |
| five_artifacts | Collector | Progression | No | Retrieve Artifact 5 times |
| unlock_all_shrines | Resonance Sage | Progression | No | Purchase all 12 permanent unlocks |
| challenge_complete | Harder Road | Progression | No | Complete any challenge run |
| all_challenges | No Mercy | Progression | No | Complete all 8 challenges |
| read_all_lore | Archivist | Secrets | No | Collect all 5 lore fragments in one run |
| modifier_stacker | Loaded | Secrets | No | Have 5 active run modifiers at once |
| cursed_silver_artifact | Spite Run | Secrets | Yes | Retrieve Artifact with cursed_silver active |
| death_pact_win | On the Edge | Secrets | Yes | Retrieve Artifact with death_pact active |
| itinerant_legacy | Legacy | Secrets | No | Purchase itinerant_legacy unlock |

---

## Key Changes

### Data
- `game/data/achievements.json` — 20 achievements with id, name, description, flavor_text, category, hidden; category display names and order

### Autoloads
- `game/autoload/achievement_manager.gd` — New singleton: loads achievements.json, unlock/is_unlocked/get_progress API, signal-driven check methods for each trigger point, achievement_unlocked signal for toast
- `game/autoload/game_state.gd` — Save v11: added unlocked_achievements, lifetime_kills, lifetime_poise_breaks, completed_challenges; record_poise_break(), record_challenge_completed() helpers; encounter_damage_taken per-encounter tracking; lifetime_kills increment in record_enemy_killed()
- `game/project.godot` — Registered AchievementManager autoload

### Combat
- `game/scenes/combat/combat_arena.gd` — Added GameState.record_poise_break() at both poise break locations (single target and sweep damage)

### UI
- `game/scripts/ui/flow_ui.gd` — Achievement toast (PanelContainer overlay, z_index 20, gold star header, 4s auto-dismiss); achievement gallery panel (full-screen, grouped by category, unlocked/locked/hidden states, progress display for count-based achievements); "Achievements" nav button in sanctuary; achievement_panel visibility management in all _show_* methods; shrine purchase triggers achievement check

### Tests
- `game/scripts/tests/m32/achievement_data_test.gd` — 6 tests: count, required fields, unique ids, bool hidden, 3 hidden, 4 categories
- `game/scripts/tests/m32/achievement_manager_test.gd` — 7 tests: lookup, duplicate guard, is_unlocked, save fields, to_save_state, migration guards, autoload exists
- `game/scripts/tests/m32/achievement_progress_test.gd` — 10 tests: thresholds, lifetime tracking, signal connections, combat hooks, damage tracking, challenge dedup, UI integration

---

## Deferred to M+1

- Achievement notification queue (if multiple unlock simultaneously, they currently replace each other)
- Achievement-gated cosmetic rewards
- Achievement progress bars in gallery
- Steam / platform achievement integration
- Achievement unlock sound distinct from ui_confirm
