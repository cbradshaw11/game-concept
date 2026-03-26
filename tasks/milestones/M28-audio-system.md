# M28 — Audio System: Sound Effect Architecture and Hooks

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** Full AudioManager rewrite with SFX/music registries, 17 SFX hooks, 7 music tracks, fade support, placeholder assets, silent-fail on missing files

---

## Overview

M28 lays the complete audio architecture for The Long Walk. The AudioManager autoload was rewritten from scratch with a registry-based design: 17 SFX entries and 7 music tracks, all mapped by string id. Audio buses (SFX, Music) are created dynamically if not present. Music supports fade-in/fade-out via tweens. All play calls fail silently with a warning when files are missing — no crashes. Placeholder WAV/OGG files are provided so all paths resolve. Dropping in real audio assets later requires zero code changes.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Rewrite AudioManager autoload — SFX/music registries, bus setup, fade support, silent-fail | DONE |
| T2 | Create 17 placeholder WAV + 7 OGG stub files under game/audio/ | DONE |
| T3 | Wire 17 SFX hooks in combat_arena.gd, main.gd, flow_ui.gd, title_screen.gd, run_summary.gd | DONE |
| T4 | Wire 7 music transitions — title, sanctuary, combat (per-ring), warden, victory | DONE |
| T5 | SettingsManager integration — N/A, no SettingsManager exists; AudioManager manages buses directly | DONE |
| T6 | Self-review pass — verified all hooks, updated legacy callers (run_summary.gd) | DONE |
| T7 | Test suite — 2 files, 22 assertions (audio_manager_test, audio_hooks_test) | DONE |
| T8 | Milestone summary | DONE |

---

## SFX Registry (17 entries)

| Sound ID | Hook Location |
|----------|--------------|
| hit_player | combat_arena — player takes damage |
| hit_enemy | combat_arena — enemy takes damage |
| enemy_death | combat_arena — enemy killed |
| player_death | combat_arena — player dies |
| dodge | combat_arena — player dodges |
| guard_break | combat_arena — guard activated |
| poise_break | combat_arena — enemy staggered |
| warden_phase | combat_arena — Warden phase transition |
| extraction | main — successful extraction |
| artifact_pickup | main — artifact retrieved |
| ring_enter | main — entering a ring |
| lore_fragment | main — lore fragment collected |
| upgrade_purchase | main — vendor purchase |
| ui_confirm | flow_ui/title_screen/run_summary — confirm buttons |
| ui_cancel | flow_ui — back/decline buttons |
| modifier_accept | flow_ui — modifier card accepted |
| shard_earn | flow_ui — Resonance Shrine unlock purchased |

## Music Registry (7 tracks)

| Track ID | Trigger |
|----------|---------|
| title | Title screen shown |
| sanctuary | Prep screen / returning to sanctuary |
| combat_inner | Ring 1 combat |
| combat_mid | Ring 2 combat |
| combat_outer | Ring 3 combat |
| warden | Warden boss gate dismissed |
| victory | Extraction or artifact victory |

---

## Architecture Notes

- AudioManager creates SFX and Music buses dynamically via `_ensure_bus()` if they don't exist in the project's audio bus layout
- Legacy convenience helpers (`play_attack`, `play_hit`, `play_ui_click`, etc.) preserved as thin wrappers delegating to `play_sfx()`
- Music fade uses Godot Tweens: fade-in from -40 dB, fade-out to -40 dB then stop
- All external callers guard with `if AudioManager:` for safety in headless/test contexts
- Placeholder generator script at `game/scripts/tools/generate_audio_placeholders.gd` can regenerate stubs

## Deferred to M29+

- Real audio assets (replace placeholder files)
- Spatial audio / positional SFX for combat
- Audio settings UI (volume sliders)
- Ambient sound layers per ring
