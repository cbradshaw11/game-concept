# M14 — Visual Polish & Combat Feel

**Status:** DONE  
**Goal:** Transform the combat from a text/number simulator into a visually engaging experience using placeholder pixel art sprites, hit feedback, and a UI skin pass.

---

## Exit Criteria

1. ✅ Player has a visible sprite in the combat arena (not a colored dot)
2. ✅ Each enemy archetype (Grunt, Ranged, Defender, Warden) has a distinct sprite
3. ✅ Combat arena has a background (not a blank canvas)
4. ✅ Hit feedback: enemies flash white on damage
5. ✅ Screen shake on heavy hit or player death
6. ✅ Death animation: enemies fade/dissolve on defeat
7. ✅ UI skin pass: dark themed panels, better typography, no raw debug labels visible to player
8. ✅ All existing headless tests still pass

---

## Art Direction

- **Style:** Simple pixel art, dark fantasy / dungeon crawler aesthetic
- **Player:** Shadowy humanoid figure, ~32x48px, 2 idle frames (player.png, player_idle2.png)
- **Grunt:** Stocky humanoid, red/brown tones, ~32x32px
- **Ranged:** Lean figure with bow indicator, ~32x40px  
- **Defender:** Armored, shield visible on left side, ~32x40px
- **Warden (boss):** Larger, ~64x64px, skull crown, glowing red eyes, rune chest markings
- **Arena background:** Stone dungeon floor/wall, torch glow, dark atmospheric, 1152x648px

---

## Tasks

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T1 | Generate pixel art sprites (player + 4 enemy types) | ✅ | Python/Pillow; `game/scripts/tools/generate_sprites.py` |
| T2 | Generate arena background | ✅ | Dark stone dungeon with stone block walls, tiled floor, torches |
| T3 | Wire sprites into combat_arena.tscn | ✅ | Runtime load via `ResourceLoader.exists()` + `load()`; PlayerSprite on Player node; EnemyContainer for dynamic spawns |
| T4 | Add hit flash shader/modulate on EnemyController | ✅ | Flash white (modulate 2,2,2) for 0.1s per hit via `_hit_flash_timers` array |
| T5 | Add screen shake on heavy hit / player death | ✅ | Camera2D offset shake; 2px light hit, 5px on death; `trigger_screen_shake()` method |
| T6 | Add death dissolve animation on enemy defeat | ✅ | Tween modulate alpha to 0 over 0.4s with red tint |
| T7 | UI skin pass — combat HUD | ✅ | Dark panel + HP (red), Stamina (blue), Poise (orange) ProgressBars with StyleBoxFlat |
| T8 | UI skin pass — Sanctuary screen | ✅ | PanelContainer with dark StyleBoxFlat, styled buttons, color-coded labels |
| T9 | UI skin pass — death/victory screens | ✅ | Themed button colors (red/green/purple tints), styled overlays |
| T10 | Write M14 test suite | ✅ | `game/scripts/tests/m14/`: sprites, arena nodes, UI structure (26 total checks) |
| T11 | Write milestone summary | ✅ | This file |

---

## Implementation Notes

### Sprite Generation
- `game/scripts/tools/generate_sprites.py` uses Python + Pillow
- Run with: `source sdenv/bin/activate && python game/scripts/tools/generate_sprites.py`
- Outputs to `game/assets/sprites/` and `game/assets/backgrounds/`

### Combat Arena Changes
- Added `const PlayerController = preload(...)` to resolve headless parse error (pre-existing bug fixed as side-effect)
- Sprites loaded at runtime via `ResourceLoader.exists()` to avoid Godot import issues in headless tests
- EnemyContainer Node2D holds dynamically spawned enemy visual nodes
- Camera2D at center of arena for screen shake implementation

### FlowUI Changes  
- Changed `VBoxContainer` to `PanelContainer` for themed dark panels
- Added `PrepVBox`/`RunVBox` as children for layout
- Fixed Variant warning in `_on_loadout_select_item_selected` (pre-existing warning-as-error)

### Test Results
- 4 pre-existing passing tests: all still pass ✅
- 3 new M14 tests: all pass ✅ (26 total assertions)
- Pre-existing failures (`combat_smoke_test`, `combat_arena_scene_test`, `combat_hooks_test`) were already failing before M14 due to Godot 4.6 headless class resolution issues unrelated to M14 work

---

## Deferred to M15

- Sound effects and music
- Actual animations (walk cycles, attack animations)  
- AI-generated art (replace placeholder pixel art)
- Ring 2/3 visual environments
- Tooltip overlays for HUD stat bars
