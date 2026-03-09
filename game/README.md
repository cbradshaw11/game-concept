# The Long Walk (Godot MVP Scaffold)

## What is implemented
- Godot 4 project scaffold
- JSON-backed data loading for rings, enemies, and weapons
- Slice 1 loop plumbing: Sanctuary -> Ring 1 encounter -> extraction banking
- Deterministic seeded encounter generator
- Headless deterministic replay test script

## Run locally (with Godot 4 installed)
- Open project: `game/project.godot`
- Main scene: `res://scenes/main.tscn`

## Run deterministic test
```bash
godot4 --headless --path game -s res://scripts/tests/replay_test.gd
```

## Next implementation targets
1. Replace demo auto-run with UI-driven flow (base prep, enter ring, extract)
2. Add actual combat controller and enemy state machines
3. Extend tests for reward scaling and death-loss rules
