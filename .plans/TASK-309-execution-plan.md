# TASK-309 Execution Plan: Ring 1 Combat Balance Pass

## Goal
Tune inner-ring enemy stats in enemies.json so an unupgraded player (100 HP, blade_iron for 14 damage) drains 20-35% HP per encounter. No single attack exceeds 40 HP.

## Depends on: TASK-302 (real enemy damage wired), TASK-303 (weapon stats wired)

## THIS IS A DATA-ONLY TASK — NO CODE CHANGES

## Target Budget
- Player: 100 HP, 3 inner encounters per run
- Each encounter: 20-35 HP drain (20-35%)
- Max single hit: 40 HP (never one-shot unupgraded player)
- Enemy HP: ~60-80 HP (blade_iron at 14 damage needs 4-6 hits to kill)
- Encounter should take ~3-5 attack exchanges

## Inner-ring enemy types to tune
Check enemies.json for current inner-ring enemy ids (likely: scavenger_grunt, ridge_sentinel, dust_crawler or similar)

For each inner-ring enemy, tune:
- `damage`: max 40, target 8-20 per hit
- `health`: 60-80 HP
- `poise_damage`: meaningful but not instant-stagger spam (target 15-25 per hit, max_poise=100)
- `speed` and `attack_speed`: keep existing or minor adjustments

## Reference Weapon Damage Values
- blade_iron: 14 damage/hit
- polearm_iron: 12 damage/hit
- bow_iron: 11 damage/hit

## Implementation Steps

### Step 1: Read current enemies.json values
File: `game/data/enemies.json`

Identify all entries with `"ring_availability"` containing `"inner"`.
Note current damage, health, poise_damage values.

### Step 2: Read encounter_templates.json
File: `game/data/encounter_templates.json`

Understand how many enemies spawn per inner encounter (1-3 enemies?).
Total encounter HP drain = (enemy_damage * attack_count_before_kill) * enemy_count

### Step 3: Calculate and apply tuned values
For each inner-ring enemy type, calculate the HP drain budget:
```
attacks_to_kill_enemy = ceil(enemy_health / weapon_damage)
# e.g., 70 HP / 14 dmg = 5 attacks to kill
enemy_hits_player = attacks_to_kill_enemy  # rough approximation
hp_drain = enemy_hits_player * enemy_damage
```

Adjust until hp_drain per encounter lands in 20-35 HP range.

### Step 4: Document encounter budget in this plan
After tuning, record the final values:
```
scavenger_grunt: health=65, damage=10, poise_damage=15
  blade_iron encounter: ~5 hits to kill, ~4 hits taken = 40 HP drain [ADJUST DOWN]
```

## Verification
```bash
python3 -c "import json; e=json.load(open('game/data/enemies.json')); inner=[x for x in e['enemies'] if 'inner' in x.get('ring_availability','')]; assert all(x['damage']<=40 for x in inner), 'damage exceeds threshold'; print('balance check: PASS')"
```

## Key Files
- `game/data/enemies.json` (primary — tune inner-ring values)
- `game/data/encounter_templates.json` (read-only — how many enemies per encounter)
- `game/data/weapons.json` (read-only — player damage reference)

## Acceptance Criteria
- All inner-ring enemy damage values <= 40
- Encounter budget documented (20-35% HP drain per encounter)
- No code changes — data only
