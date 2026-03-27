# M36: Player Attack Feedback

**Status: DONE**
**Date Completed:** 2026-03-26

---

## Goal

Add player-side visual and audio feedback when attacking. Previously all feedback originated from the enemy (hit flash, hit stop, screen shake on death). Now the player character flashes on swing and attack SFX play from the player side.

---

## Exit Criteria

- [x] Player sprite flashes light yellow-white (Color(1.2, 1.2, 0.8)) on attack — 80ms hold, 120ms lerp back
- [x] `_player_attack_flash_timer` var + `_update_player_attack_flash(delta)` in combat_arena.gd
- [x] `swing` SFX plays on light attack (`_on_attack_triggered`)
- [x] `heavy_swing` SFX plays on heavy attack (`execute_heavy_attack`)
- [x] Both SFX entries added to AudioManager SFX_REGISTRY with silent-fail placeholder paths
- [x] Tests pass: `test_attack_feedback.gd`
- [x] Milestone summary committed

---

## Tasks

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 1 | Player attack flash (modulate + timer) | `combat_arena.gd` | Done |
| 2 | Swing SFX on light attack | `combat_arena.gd`, `audio_manager.gd` | Done |
| 3 | Heavy swing SFX on heavy attack | `combat_arena.gd`, `audio_manager.gd` | Done |
| 4 | Tests | `tests/m36/test_attack_feedback.gd` | Done |
| 5 | Milestone summary | `tasks/milestones/M36-attack-feedback.md` | Done |

---

## Deferred to M+1

- Actual swing/heavy_swing .wav audio files (currently silent-fail placeholders)
- Per-weapon attack SFX variants (e.g., different swing sound for War Hammer vs Twin Fangs)
- Player hit-taken flash (distinct from attack flash)
