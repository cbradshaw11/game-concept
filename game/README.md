# The Long Walk (Godot MVP Scaffold)

## What is implemented
- Godot 4 project scaffold
- JSON-backed data loading for rings, enemies, and weapons
- UI-driven Slice 1 flow: Sanctuary prep -> Ring 1 run -> encounter resolution -> extraction
- First enemy state machine controller (idle/chase/attack/stagger/dead)
- Deterministic seeded encounter generator
- Headless verifier tests for replay determinism, progression integrity, enemy states, and reward scaling

## Run locally (with Godot 4 installed)
- Open project: `game/project.godot`
- Main scene: `res://scenes/main.tscn`

## Run tests (headless)
```bash
godot4 --headless --path game -s res://scripts/tests/replay_test.gd
godot4 --headless --path game -s res://scripts/tests/enemy_state_test.gd
godot4 --headless --path game -s res://scripts/tests/progression_integrity_test.gd
godot4 --headless --path game -s res://scripts/tests/reward_scaling_test.gd
godot4 --headless --path game -s res://scripts/tests/save_load_integrity_test.gd
```

## Next implementation targets
1. Replace simulated encounter resolution with real combat scene and enemy instances
2. Add Sanctuary shop and loadout equipment persistence
3. Implement contract objectives and Ring 2 content slice
