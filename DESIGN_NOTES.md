# DESIGN NOTES

## Enemy Standardization Standard (pending implementation)

Every enemy must have:

### Movement Identity
Each enemy's movement should reflect what it actually IS — not generic "walk toward player".
Examples:
- **Mage** — teleports short distances, never runs
- **Flying enemy** — wing-flap bob, bounces in the air, swoops down to attack
- **Ninja/assassin** — quick dashes, repositions constantly, disappears and reappears
- **Spider** — erratic scurry with direction changes, low to ground
- **Armored knight** — slow, heavy, deliberate — commits to each step
- **Ghost/wraith** — floats, phases, drifts unpredictably

### Attack Identity
Each enemy must have a visually distinct attack that looks like the right tool for what it is:
- Web projectile ≠ magic orb ≠ sword swing ≠ arrow — they should look different
- Attack shape, speed, color, and size should telegraph the type
- Charge-up / wind-up animations must be visible and readable

### Indicators Required
ALL enemies must show:
1. **Movement indicator** — bob, bounce, stride, flap, scurry, drift (whatever fits)
2. **Pre-attack tell** — a visible change before the attack fires (crouch, glow, pause, wind-up)
3. **Attack visual** — the actual attack must have a distinct look (projectile, swing line, AoE flash, etc.)

### Implementation pattern (when building new enemies)
1. Define in `enemies.json` with rings, stats, behavior_profile
2. Add to `enemy_spawner.gd` SPRITE_MAP + SPEED_MAP + tint color
3. Add movement logic to `_update_enemies()` in `world_scene.gd`
4. Add attack logic (if ranged/special) to dedicated `_update_X_attacks()` function
5. Add animation to `_animate_enemies()` — movement bob AND pre-attack pose

