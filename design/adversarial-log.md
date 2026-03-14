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
