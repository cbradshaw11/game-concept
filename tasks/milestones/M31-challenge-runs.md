# M31 — Challenge Runs: Unlockable Hard Mode Modifiers

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** 8 unlockable challenge runs, ChallengeManager autoload, sanctuary UI, full enforcement across combat, extraction, vendor, lore, and modifier systems

---

## Overview

M31 adds replayability beyond pure skill improvement. Challenge runs are opt-in full-run modifiers that impose specific restrictions (no healing, time limits, permanent death, vendor lockout, escalating enemies, forced Warden fight, increased damage, stripped systems). Players unlock challenges by accumulating total runs or artifact retrievals, select them before a run from the sanctuary, and earn bonus Resonance Shards on successful completion.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add 8 challenge runs to modifiers.json challenge_runs array | DONE |
| T2 | Create ChallengeManager autoload — select, clear, has_challenge, shard bonus, unlock checks | DONE |
| T3 | Challenge Select UI in sanctuary — list, lock/unlock states, select/deselect, flavor text | DONE |
| T4 | Enforce all 8 challenge rules across game systems | DONE |
| T5 | Self-review pass — timer clearing, re-entrancy guard, escalation cap | DONE |
| T6 | Test suite — 3 files: challenge_data_test, challenge_unlock_test, challenge_enforcement_test | DONE |
| T7 | Milestone summary | DONE |

---

## Challenge Runs

| ID | Name | Description | Unlock | Shard Bonus |
|----|------|-------------|--------|-------------|
| iron_road | Iron Road | No healing between encounters | 3 runs | +30 |
| time_pressure | Time Pressure | Ring time limits (4/6/8 min) | 5 runs | +40 |
| one_life | One Life | Permanent death, no retry, no rewards | 5 runs | +60 |
| naked_run | Naked Run | Cannot purchase vendor upgrades | 8 runs | +50 |
| escalation | Escalation | +1 enemy per encounter (cap +4) | 8 runs | +45 |
| warden_hunt | Warden Hunt | Must defeat Warden, no early extraction | 1 artifact | +80 |
| cursed_ground | Cursed Ground | All enemies +25% damage | 10 runs | +35 |
| silent_run | Silent Run | No lore fragments, no modifier cards | 10 runs | +25 |

---

## Key Changes

### Data
- `game/data/modifiers.json` — Added `challenge_runs` array with 8 entries, each containing id, name, description, flavor, unlock_type, unlock_threshold, shard_bonus, and challenge-specific fields (time_limits, extra_enemy_cap)

### Autoloads
- `game/autoload/challenge_manager.gd` — New singleton: active_challenge tracking, get_available_challenges(), select_challenge(), has_challenge(), get_shard_bonus(), end_run()
- `game/autoload/data_store.gd` — Added get_challenge_runs() and get_challenge_run() lookup helpers
- `game/autoload/game_state.gd` — Updated award_run_shards() to add challenge shard bonus on non-death completion and clear challenge via ChallengeManager.end_run()
- `game/project.godot` — Registered ChallengeManager autoload

### UI
- `game/scripts/ui/flow_ui.gd` — Added challenge_panel with full CRUD UI (setup, show, refresh), "Challenge Runs" nav button in sanctuary, locked/unlocked/selected states per challenge, visibility management across all screen switches, naked_run vendor lockout display, on_extract_blocked_challenge() for warden_hunt message

### Enforcement Points
- `game/scenes/combat/combat_arena.gd` — iron_road: skip HP reset between encounters; cursed_ground: 1.25x enemy damage multiplier
- `game/scripts/main.gd` — warden_hunt: block extraction if artifact not retrieved; one_life: no retry/no rewards on death with re-entrancy guard; naked_run: block vendor purchases; silent_run: skip fragment drops and modifier card offers; time_pressure: Timer-based per-ring countdown with forced death on expiry, timer cleared on extraction/death/boss defeat
- `game/scripts/systems/ring_director.gd` — escalation: add min(encounters_cleared, 4) extra enemies to each encounter

### Tests
- `game/scripts/tests/m31/challenge_data_test.gd` — 8 tests: count, required fields, positive bonuses, no duplicates, valid unlock types, expected IDs, time_limits structure, warden_hunt unlock type
- `game/scripts/tests/m31/challenge_unlock_test.gd` — 8 tests: per-challenge threshold verification, shard bonus values match spec
- `game/scripts/tests/m31/challenge_enforcement_test.gd` — 10 tests: design validation per challenge, escalation math, shard-on-completion-only

---

## Deferred to M+1

- Challenge-specific HUD timer display for time_pressure (currently enforced but not shown)
- Challenge completion tracking / statistics (which challenges completed, best times)
- Stacking multiple challenges simultaneously
- Challenge leaderboards
