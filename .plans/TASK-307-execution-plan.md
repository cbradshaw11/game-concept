# TASK-307 Execution Plan: Combat HUD (HP, Stamina, Poise)

## Goal
Replace the placeholder CombatStatus text label in combat_arena.tscn with three ProgressBar nodes (HP, stamina, poise). Values update live via player signals.

## Depends on: TASK-301 (health_changed signal)
Note: TASK-306 adds poise_changed signal — HUD should wire it if available, else skip poise bar gracefully.

## Current State
- combat_arena.tscn has a single `CombatStatus` Label showing text dump
- No ProgressBar nodes exist
- PlayerController has stamina but no health_changed/poise_changed signals yet

## Implementation Steps

### Step 1: Add ProgressBar nodes to combat_arena.tscn
File: `game/scenes/combat/combat_arena.tscn`

Add a HUD container (HBoxContainer or VBoxContainer anchored top-left) with:
- `HPBar` (ProgressBar, red, max_value=100)
- `StaminaBar` (ProgressBar, yellow, max_value=100)
- `PoiseBar` (ProgressBar, blue, max_value=100)

Godot tscn format snippet:
```
[node name="HUD" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 1

[node name="HPBar" type="ProgressBar" parent="HUD"]
max_value = 100.0

[node name="StaminaBar" type="ProgressBar" parent="HUD"]
max_value = 100.0

[node name="PoiseBar" type="ProgressBar" parent="HUD"]
max_value = 100.0
```

Keep CombatStatus label or remove it — replace its role with the bars.

### Step 2: Wire signal handlers in combat_arena.gd
File: `game/scenes/combat/combat_arena.gd`

Add node refs:
```gdscript
@onready var hp_bar: ProgressBar = $HUD/HPBar
@onready var stamina_bar: ProgressBar = $HUD/StaminaBar
@onready var poise_bar: ProgressBar = $HUD/PoiseBar
```

In `_ready()` after player is spawned/assigned:
```gdscript
player.health_changed.connect(_on_health_changed)
player.stamina_changed.connect(_on_stamina_changed)
if player.has_signal("poise_changed"):
    player.poise_changed.connect(_on_poise_changed)
```

Add handlers:
```gdscript
func _on_health_changed(current: int, maximum: int) -> void:
    hp_bar.max_value = maximum
    hp_bar.value = current
    # Low health color change
    if float(current) / float(maximum) < 0.25:
        hp_bar.modulate = Color(0.5, 0.0, 0.0)  # dark red
    else:
        hp_bar.modulate = Color(1.0, 0.2, 0.2)  # normal red

func _on_stamina_changed(current: float, maximum: int) -> void:
    stamina_bar.max_value = maximum
    stamina_bar.value = current

func _on_poise_changed(current: int, maximum: int) -> void:
    poise_bar.max_value = maximum
    poise_bar.value = current
```

Note: PlayerController must also emit `stamina_changed` — add this signal to `regenerate_stamina()` and `try_attack()`/`try_dodge()` if not already present.

### Step 3: Add stamina_changed signal to PlayerController
File: `game/scripts/core/player_controller.gd`

Add signal:
```gdscript
signal stamina_changed(current: float, maximum: int)
```

Emit in `regenerate_stamina()` and after stamina spend in try_attack/try_dodge.

## Key Files
- `game/scenes/combat/combat_arena.tscn` (primary — add ProgressBar nodes)
- `game/scenes/combat/combat_arena.gd` (primary — wire signals to bars)
- `game/scripts/core/player_controller.gd` (add stamina_changed signal emission)

## Acceptance Criteria
- Three ProgressBar nodes in combat_arena.tscn scene tree
- combat_arena.gd connects health_changed/stamina_changed/poise_changed to bar updates
- HP bar turns dark red when HP < 25% of max
- HUD does not obscure the combat play area
