# TASK-305 Execution Plan: Dodge Invulnerability Frames

## Goal
Implement a true i-frame window on dodge. During the window, `take_damage()` returns 0 and fires `attack_evaded`. Stamina cost applies regardless. Back-to-back dodge spamming is blocked by cooldown.

## Depends on: TASK-301 (take_damage), TASK-302 (enemy damage)

## Current State
- `PlayerController.dodge_triggered` signal exists and fires on dodge input
- Stamina cost already applies in `try_dodge()`
- No i-frame state exists — damage during dodge applies normally
- `weapons.json:global_combat.dodge_iframe_ms = 220`

## Implementation Steps

### Step 1: Add i-frame state to PlayerController
File: `game/scripts/core/player_controller.gd`

```gdscript
signal attack_evaded()

var is_invulnerable: bool = false
var dodge_iframe_duration: float = 0.22  # 220ms, read from weapons.json
var dodge_cooldown_duration: float = 0.5  # prevent spam — not in weapons.json, define const
var dodge_cooldown_timer: float = 0.0
```

### Step 2: Start i-frame window on dodge
File: `game/scripts/core/player_controller.gd`

In `try_dodge()` after stamina check:
```gdscript
func _start_iframe_window() -> void:
    is_invulnerable = true
    await get_tree().create_timer(dodge_iframe_duration).timeout
    is_invulnerable = false

    dodge_cooldown_timer = dodge_cooldown_duration

func try_dodge() -> void:
    if stamina < dodge_stamina_cost:
        return
    if dodge_cooldown_timer > 0:
        return  # cooldown active — block spam
    stamina -= dodge_stamina_cost
    dodge_triggered.emit()
    _start_iframe_window()
```

Track cooldown in `_process(delta)`:
```gdscript
func _process(delta: float) -> void:
    # ... existing stamina regen ...
    if dodge_cooldown_timer > 0:
        dodge_cooldown_timer -= delta
```

### Step 3: Modify take_damage() to respect i-frame
File: `game/scripts/core/player_controller.gd`

```gdscript
func take_damage(amount: int) -> void:
    if is_invulnerable:
        attack_evaded.emit()
        return  # 0 damage during i-frame

    # ... existing guard + health logic ...
```

### Step 4: Load iframe duration from weapons.json
In `_ready()`:
```gdscript
var combat_data = DataStore.get_global_combat()
dodge_iframe_duration = combat_data.get("dodge_iframe_ms", 220) / 1000.0
```

### Step 5: Write unit test stub
File: `game/scripts/tests/test_dodge_iframes.gd`

Pattern:
- Trigger dodge, immediately call take_damage → assert HP unchanged, attack_evaded emitted
- Wait > iframe duration, call take_damage → assert HP reduced normally
- Trigger dodge twice rapidly → assert only first dodge activates i-frame

## Key Files
- `game/scripts/core/player_controller.gd` (primary — add i-frame state)
- `game/data/weapons.json` (read-only — dodge_iframe_ms)
- `game/scenes/combat/combat_arena.gd` (read-only — calls take_damage)

## Acceptance Criteria
- I-frame duration reads from `weapons.json:global_combat.dodge_iframe_ms`
- `take_damage()` during window: returns 0, fires `attack_evaded`
- `take_damage()` outside window: applies normally
- Dodge spam does not chain i-frames (cooldown enforced)
