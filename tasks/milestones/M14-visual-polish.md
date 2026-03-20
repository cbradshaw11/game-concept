# M14 — Visual Polish & Combat Feel

**Status:** Planning  
**Goal:** Transform the combat from a text/number simulator into a visually engaging experience using placeholder pixel art sprites, hit feedback, and a UI skin pass.

---

## Exit Criteria

1. Player has a visible sprite in the combat arena (not a colored dot)
2. Each enemy archetype (Grunt, Ranged, Defender, Warden) has a distinct sprite
3. Combat arena has a background (not a blank canvas)
4. Hit feedback: enemies flash white on damage
5. Screen shake on heavy hit or player death
6. Death animation: enemies fade/dissolve on defeat
7. UI skin pass: dark themed panels, better typography, no raw debug labels visible to player
8. All existing headless tests still pass

---

## Art Direction

- **Style:** Simple pixel art, dark fantasy / dungeon crawler aesthetic
- **Player:** Shadowy humanoid figure, ~32x48px, simple idle animation (2 frames)
- **Grunt:** Stocky humanoid, red/brown tones, ~32x32px
- **Ranged:** Lean figure with bow/ranged weapon indicator, ~32x40px  
- **Defender:** Armored, shield visible, ~32x40px
- **Warden (boss):** Larger, ~64x64px, distinct silhouette
- **Arena background:** Stone dungeon floor/wall, dark atmospheric, 1152x648px or project resolution

---

## Tasks

| ID | Task | Notes |
|----|------|-------|
| T1 | Generate pixel art sprites (player + 4 enemy types) | Use Python Pillow to generate programmatic pixel art placeholders |
| T2 | Generate arena background | Dark stone dungeon, programmatic or simple gradient with details |
| T3 | Wire sprites into combat_arena.tscn | Replace colored shape nodes with Sprite2D nodes |
| T4 | Add hit flash shader/modulate on EnemyController | Flash white for 0.1s on damage |
| T5 | Add screen shake on heavy hit / player death | CameraShake via Tween in combat arena |
| T6 | Add death dissolve animation on enemy defeat | Modulate alpha to 0 over 0.4s |
| T7 | UI skin pass — combat HUD | Dark panels, colored stat bars (HP=red, Stamina=blue, Poise=orange) |
| T8 | UI skin pass — Sanctuary screen | Match dark theme, cleaner layout |
| T9 | UI skin pass — death/victory screens | Styled overlays, not raw labels |
| T10 | Write M14 test suite | Verify sprites exist, shader present, UI nodes present |
| T11 | Write milestone summary | Required per CLAUDE.md conventions |

---

## Deferred to M15

- Sound effects and music
- Actual animations (walk cycles, attack animations)  
- AI-generated art (replace placeholder pixel art)
- Ring 2/3 visual environments
