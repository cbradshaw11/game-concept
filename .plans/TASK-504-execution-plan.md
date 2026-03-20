# TASK-504 Execution Plan: Audio Combat Readability Floor

## Goal
Create 4 placeholder audio files. Add AudioStreamPlayer nodes to combat_arena.tscn.
Wire playback to combat events. Add WIND_UP state to EnemyController.

## Depends on: nothing (Wave 1)

## Key Files
- `game/audio/` (new directory with 4 .wav files)
- `game/scenes/combat/combat_arena.tscn` (add 4 AudioStreamPlayer nodes)
- `game/scenes/combat/combat_arena.gd` (wire audio playback to events)
- `game/scripts/core/enemy_controller.gd` (add WIND_UP state)

## Read Before Implementing
Read:
- game/scenes/combat/combat_arena.gd (understand events: player attacks, takes damage, dodges, dies)
- game/scripts/core/enemy_controller.gd (understand state machine: IDLE, CHASE, ATTACK — add WIND_UP before ATTACK)
- game/scripts/core/player_controller.gd (understand signals: health_changed, stamina_changed, or similar death/dodge signals)

---

## Slice 1: Create placeholder audio files

Godot 4 can load minimal valid WAV files. Create game/audio/ directory and 4 WAV files.

Option A (simplest): Create minimal valid WAV files using Python:
```python
import struct, os
os.makedirs("game/audio", exist_ok=True)

def make_silent_wav(filename):
    # Minimal valid WAV: 44-byte header + empty data chunk
    with open(filename, 'wb') as f:
        # RIFF header
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36))  # file size - 8
        f.write(b'WAVE')
        # fmt chunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))   # chunk size
        f.write(struct.pack('<H', 1))    # PCM
        f.write(struct.pack('<H', 1))    # mono
        f.write(struct.pack('<I', 44100)) # sample rate
        f.write(struct.pack('<I', 44100)) # byte rate
        f.write(struct.pack('<H', 1))    # block align
        f.write(struct.pack('<H', 8))    # bits per sample
        # data chunk
        f.write(b'data')
        f.write(struct.pack('<I', 0))    # no audio data

for name in ['hit_land.wav', 'damage_taken.wav', 'dodge_guard_success.wav', 'player_death.wav']:
    make_silent_wav(f'game/audio/{name}')
print("Created 4 placeholder WAV files")
```

Run this script from the project root or create the files inline using Bash/Write tools.

---

## Slice 2: Add AudioStreamPlayer nodes to combat_arena.tscn

In the tscn file, add 4 AudioStreamPlayer nodes as children of the root node.
Each should reference its corresponding audio file.

Pattern in Godot 4 tscn format:
```
[node name="HitLandPlayer" type="AudioStreamPlayer" parent="."]
stream = ExtResource("...")  # or use load path
autoplay = false
```

If direct tscn editing is complex, add them via script in _ready():
```gdscript
# In combat_arena.gd _ready():
_hit_land_player = AudioStreamPlayer.new()
_hit_land_player.stream = load("res://audio/hit_land.wav")
add_child(_hit_land_player)
# repeat for other 3 players
```

---

## Slice 3: Wire audio playback to combat events

In combat_arena.gd, find where each combat event occurs and add audio playback:

```gdscript
# When player successfully lands attack:
_hit_land_player.play()

# When player takes damage:
_damage_taken_player.play()

# When player dodges (i-frames triggered) or guard absorbs:
_dodge_guard_player.play()

# When player dies (health reaches 0):
_death_player.play()
```

Find the exact locations by searching for:
- Light/heavy attack success handlers
- Player damage application (where HP is reduced)
- Dodge i-frame activation
- Death handler / state transition

---

## Slice 4: Add WIND_UP state to EnemyController

Read enemy_controller.gd state machine. The current states should be something like:
IDLE, CHASE, ATTACK (or similar).

Add WIND_UP as an intermediate state before attack fires:

```gdscript
enum EnemyState { IDLE, CHASE, WIND_UP, ATTACK }
# or whatever naming convention the existing code uses

var wind_up_timer: float = 0.0
const WIND_UP_DURATION: float = 0.2

# In tick() where ATTACK would previously be entered:
# Instead of immediately attacking, enter WIND_UP:
if distance_to_player <= attack_range and ...:
    if current_state != EnemyState.WIND_UP:
        current_state = EnemyState.WIND_UP
        wind_up_timer = WIND_UP_DURATION
        # visual flash (if enemy has a sprite reference, modulate it)
        # if no sprite access from here, signal CombatArena to flash

# In WIND_UP state tick():
wind_up_timer -= delta
if wind_up_timer <= 0:
    current_state = EnemyState.ATTACK
    # emit attack
```

If EnemyController is a RefCounted with no Node access, the visual flash must be handled
in CombatArena by listening to a signal like `wind_up_started.emit()`.

---

## Verification Commands
```bash
ls game/audio/
grep -n 'hit_land\|damage_taken\|dodge_guard\|player_death' game/scenes/combat/combat_arena.gd
grep -n 'WIND_UP\|wind_up\|telegraph\|attack_delay' game/scripts/core/enemy_controller.gd
grep -n 'AudioStreamPlayer' game/scenes/combat/combat_arena.tscn
```

## Acceptance Criteria
- AC1: ls game/audio/ shows 4 files
- AC2: Audio playback calls in combat_arena.gd
- AC3: WIND_UP state in enemy_controller.gd
- AC4: AudioStreamPlayer nodes in combat_arena.tscn

## Notes
If EnemyController has no sprite access (it extends RefCounted, not Node), the
modulate flash must be done in CombatArena. Add a signal `wind_up_started` to
EnemyController and handle the visual there. The functional test requirement is
only that WIND_UP state exists and delays attack -- visual flash is best-effort.
Placeholder WAV files are zero-length audio. They will not produce sound but
will satisfy the structural acceptance criteria. Real audio is M6.
