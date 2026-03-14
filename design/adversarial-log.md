# Adversarial Log -- M11: The Long Walk Becomes Legible

_Bugs will be appended here after adversarial testing._

## M11 Adversarial Round -- 2026-03-14

### CRIT
- [FIXED][CRIT] game/scripts/tests/m6/test_m6_save_migration.gd:78 -- asserts save_version == 4, production now emits 6; CI will fail or is not running this test
- [FIXED][CRIT] game/scenes/combat/combat_arena.gd:29 -- @onready `_combat_tutorial_overlay` points to scene-defined Panel that is NEVER shown; dynamic `_tutorial_overlay` is the actual overlay; dead reference causes architectural confusion and orphaned scene node

### HIGH
- [FIXED][HIGH] game/autoload/game_state.gd:149 -- `rings_story_seen` loaded as untyped Array; should use typed constructor `Array(data.get(...), TYPE_STRING, "", null)` to match pattern used by rings_cleared
- [FIXED][HIGH] game/scripts/ui/flow_ui.gd:586 -- `_on_visit_vendor_pressed` has no `is_instance_valid` guard; double-click creates two vendor instances; one is leaked
- [FIXED][HIGH] game/scripts/ui/flow_ui.gd:440 -- death panel loot retention hardcoded "25%% retention" string; shows incorrect value when `deep_pockets` permanent upgrade grants 35% retention
- [FIXED][HIGH] game/scripts/systems/ring_director.gd:23 -- random fallback path seeds RNG with `_combine_seed(seed, ring_id)` without `encounters_cleared`; template path includes it (line 61); asymmetric seeding means fallback always produces same encounter for same (seed, ring_id)
- [FIXED][HIGH] game/data/enemies.json -- warden_herald has no exclusion flag; random enemy pool includes it; can appear as 1-3 enemies in normal encounters bypassing mini-boss template gating

### MED
- [FIXED][MED] game/data/enemies.json -- warden_herald damage 21 > outer_warden damage 18; mini-boss hits harder than the boss it foreshadows; balance inversion
- [MED] game/autoload/game_state.gd:152 -- total_runs migration from v5 capped at run_history.size() (max 20); players with >20 runs will have understated count
- [MED] game/scripts/ui/flow_ui.gd -- story modal has no pause guard; player can open pause menu during modal
- [MED] game/scripts/ui/run_history.gd:17,36 -- _compute_lifetime_stats derives total_runs from history.size() not GameState.total_runs; diverges for >20 run players

### LOW
- [LOW] game/scenes/combat/combat_arena.gd:230 -- _dismiss_frame guard blocks player's first post-tutorial attack if attack fires on same frame as button dismiss
- [LOW] game/scripts/ui/flow_ui.gd:380 -- save_state return value discarded; silent failure on disk full
- [LOW] game/scripts/ui/flow_ui.gd -- story modal has no min-size constraint; may render tiny on non-standard resolutions
- [FIXED][LOW] game/scripts/ui/flow_ui.gd:609 -- history_button functional connection may be missing from _ready(); verify scene inspector has it

## M11 Adversarial Round -- 2026-03-14

### CRIT
- [FIXED][CRIT] game/scripts/tests/m6/test_m6_save_migration.gd:78 -- asserts save_version == 4, production now emits 6; CI will fail or is not running this test
- [FIXED][CRIT] game/scenes/combat/combat_arena.gd:29 -- @onready `_combat_tutorial_overlay` points to scene-defined Panel that is NEVER shown; dynamic `_tutorial_overlay` is the actual overlay; dead reference causes architectural confusion and orphaned scene node

### HIGH
- [FIXED][HIGH] game/autoload/game_state.gd:149 -- `rings_story_seen` loaded as untyped Array; should use typed constructor `Array(data.get(...), TYPE_STRING, "", null)` to match pattern used by rings_cleared
- [FIXED][HIGH] game/scripts/ui/flow_ui.gd:586 -- `_on_visit_vendor_pressed` has no `is_instance_valid` guard; double-click creates two vendor instances; one is leaked
- [FIXED][HIGH] game/scripts/ui/flow_ui.gd:440 -- death panel loot retention hardcoded "25%% retention" string; shows incorrect value when `deep_pockets` permanent upgrade grants 35% retention
- [FIXED][HIGH] game/scripts/systems/ring_director.gd:23 -- random fallback path seeds RNG with `_combine_seed(seed, ring_id)` without `encounters_cleared`; template path includes it (line 61); asymmetric seeding means fallback always produces same encounter for same (seed, ring_id)
- [FIXED][HIGH] game/data/enemies.json -- warden_herald has no exclusion flag; random enemy pool includes it; can appear as 1-3 enemies in normal encounters bypassing mini-boss template gating

### MED
- [FIXED][MED] game/data/enemies.json -- warden_herald damage 21 > outer_warden damage 18; mini-boss hits harder than the boss it foreshadows; balance inversion
- [MED] game/autoload/game_state.gd:152 -- total_runs migration from v5 capped at run_history.size() (max 20); players with >20 runs will have understated count
- [MED] game/scripts/ui/flow_ui.gd -- story modal has no pause guard; player can open pause menu during modal
- [MED] game/scripts/ui/run_history.gd:17,36 -- _compute_lifetime_stats derives total_runs from history.size() not GameState.total_runs; diverges for >20 run players

### LOW
- [LOW] game/scenes/combat/combat_arena.gd:230 -- _dismiss_frame guard blocks player's first post-tutorial attack if attack fires on same frame as button dismiss
- [LOW] game/scripts/ui/flow_ui.gd:380 -- save_state return value discarded; silent failure on disk full
- [LOW] game/scripts/ui/flow_ui.gd -- story modal has no min-size constraint; may render tiny on non-standard resolutions
- [FIXED][LOW] game/scripts/ui/flow_ui.gd:609 -- history_button functional connection may be missing from _ready(); verify scene inspector has it
# Adversarial Log -- M12: Close the Loop

_Bugs will be appended here after adversarial testing._

## M12 Adversarial Round -- 2026-03-14

### CRIT
_None._

### HIGH
- [HIGH] enemy_controller.gd:94-95 -- `else: state = EnemyState.ATTACK` when attack_cooldown_timer > 0 sets orphaned ATTACK state with no damage emission and no cooldown reset. Enemies in attack range during cooldown display ATTACK state but never deal damage until state is disrupted externally.
- [HIGH] combat_arena.gd:338 -- guard_counter closure captures `pc = player` via local var. If player node is freed mid-encounter, `pc.guarding` access crashes in Godot 4 (null-instance error, not silent false). Needs `is_instance_valid(pc)` guard before property access.
- [HIGH] main.gd:201-213 -- TASK-1203 combat music inline block bypasses `_stop_music()` and `_play_music()`. Sanctuary track is hard-cut (not faded) when combat starts. All other transitions use `_stop_music()` + `_play_music()`; this one does not. Also duplicates fade tween logic from `_play_music()`.
- [HIGH] flow_ui.gd:420-424 -- Story modal `on_dismiss.call()` executes unconditionally after dismiss button pressed, even if `_story_modal` was freed by a concurrent second `_show_story_modal()` call. Can cause double-execution of `_finish_extraction()`, corrupting prep screen state.

### MED / LOW
- [MED] flow_ui.gd:112-122 -- One-frame ESC race: if player presses ESC in the exact frame that modal dismiss sets `_story_modal = null` but before `_show_prep()` hides `run_screen`, `_handle_pause_input` succeeds and sets `_is_paused = true`. After `_show_prep()` runs, pause menu is invisible but game is paused -- no recovery path.
- [MED] flow_ui.gd:409 -- Story modal `PanelContainer` has no max height. If `first_extraction_log` text is long, "Continue" button pushed off-screen. Softlock: player cannot dismiss modal.
- [MED] game_state.gd:208 -- `run_number` field computed as `run_history.size() + 1` before append. After 20-run cap, size stays at 20 so run 22 gets `run_number = 21` -- collision. Should use `total_runs + 1` (monotonic).
- [MED] combat_arena.gd:333-334 -- kite_volley profile: `preferred_min_range = 1.5` but zone 0 distance is always 0.5. Kite enemies in zone 0 never meet attack condition (distance >= preferred_min_range fails). Enemy chases forever at close range but never attacks. Whether intentional (force player to manage distance) requires design decision.
- [MED] ring_director.gd:70 -- Template with unknown enemy ID emits push_warning but silently produces shorter enemy list while returning original `selected.size()` count. `encounter_cleared.emit(encounter_enemy_count)` fires with wrong count, corrupting loot/reward calculation.
- [LOW] combat_arena.gd:345 -- `_apply_behavior_profile` wildcard `_: pass` silently ignores unknown profile names. No push_warning emitted, making data typos invisible.
- [LOW] game_state.gd:148-153 -- v5->v6 migration sets `total_runs = run_history.size()` (max 20). True run count irrecoverable for pre-v6 players with >20 runs. Known and accepted migration limitation.
