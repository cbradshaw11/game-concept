# TASK-502 Execution Plan: Content Volume Pass

## Goal
Expand encounter templates to >= 5 per ring with no duplicate compositions.
Add 5 new enemy types to enemies.json. Fix inner_patrol_a/inner_ranged_mix duplicate.
Create check_content_volume.py CI script.

## Depends on: nothing (Wave 1)

## Key Files
- `game/data/encounter_templates.json` (fix duplicate, add new templates)
- `game/data/enemies.json` (add 5 new enemies)
- `scripts/ci/check_content_volume.py` (new CI validation script)

## Read Before Implementing
Read these files:
- game/data/encounter_templates.json (understand current templates and format)
- game/data/enemies.json (understand enemy fields: id, name, health, poise, damage, behavior_profile, ring_availability or rings)
- game/scripts/core/enemy_controller.gd (confirm behavior_profile values that exist: frontline_basic, flank_aggressive, kite_volley, guard_counter, zone_control, elite_pressure)

---

## Slice 1: Fix duplicate and expand enemies.json

Current issue: inner_patrol_a and inner_ranged_mix both have enemy_ids: ["scavenger_grunt", "shieldbearer"].

Fix inner_ranged_mix to use different enemies once new inner enemies are added.

Add to enemies.json "enemies" array:

```json
{
  "id": "dust_runner",
  "name": "Dust Runner",
  "health": 35,
  "poise": 20,
  "damage": 8,
  "behavior_profile": "frontline_basic",
  "ring_availability": "inner",
  "rings": ["inner"]
},
{
  "id": "siege_crossbowman",
  "name": "Siege Crossbowman",
  "health": 45,
  "poise": 15,
  "damage": 11,
  "behavior_profile": "kite_volley",
  "ring_availability": "inner",
  "rings": ["inner"]
},
{
  "id": "iron_vanguard",
  "name": "Iron Vanguard",
  "health": 90,
  "poise": 60,
  "damage": 14,
  "behavior_profile": "guard_counter",
  "ring_availability": "mid",
  "rings": ["mid"]
},
{
  "id": "rift_sentinel",
  "name": "Rift Sentinel",
  "health": 120,
  "poise": 50,
  "damage": 18,
  "behavior_profile": "elite_pressure",
  "ring_availability": "outer",
  "rings": ["outer"]
},
{
  "id": "void_sniper",
  "name": "Void Sniper",
  "health": 70,
  "poise": 20,
  "damage": 22,
  "behavior_profile": "kite_volley",
  "ring_availability": "outer",
  "rings": ["outer"]
}
```

Adapt field names to match existing enemy format (read enemies.json first — the exact fields vary: some use ring_availability, some use rings array, some use both).

---

## Slice 2: Update encounter_templates.json

Fix inner_ranged_mix (was duplicate of inner_patrol_a):
```json
{
  "id": "inner_ranged_mix",
  "ring": "inner",
  "enemy_ids": ["siege_crossbowman", "scavenger_grunt"]
}
```

Add new inner templates:
```json
{
  "id": "inner_runner_pack",
  "ring": "inner",
  "enemy_ids": ["dust_runner", "dust_runner", "scavenger_grunt"]
},
{
  "id": "inner_crossbow_screen",
  "ring": "inner",
  "enemy_ids": ["siege_crossbowman", "shieldbearer"]
}
```

Add new mid templates:
```json
{
  "id": "mid_vanguard_push",
  "ring": "mid",
  "enemy_ids": ["iron_vanguard", "ash_flanker"]
},
{
  "id": "mid_vanguard_screen",
  "ring": "mid",
  "enemy_ids": ["iron_vanguard", "ridge_archer"]
}
```

Add new outer templates:
```json
{
  "id": "outer_sentinel_pair",
  "ring": "outer",
  "enemy_ids": ["rift_sentinel", "void_sniper"]
},
{
  "id": "outer_sniper_volley",
  "ring": "outer",
  "enemy_ids": ["void_sniper", "void_sniper"]
}
```

After changes: inner should have 5 templates, mid 5, outer 5.

---

## Slice 3: check_content_volume.py

Create scripts/ci/check_content_volume.py:

```python
#!/usr/bin/env python3
"""Content volume validation for The Long Walk."""
import json
import sys
import os

def load(path):
    with open(path) as f:
        return json.load(f)

def check_template_counts(templates, min_count=5):
    counts = {}
    for t in templates:
        ring = t["ring"]
        counts[ring] = counts.get(ring, 0) + 1
    failures = []
    for ring in ["inner", "mid", "outer"]:
        n = counts.get(ring, 0)
        if n < min_count:
            failures.append(f"  {ring}: {n} templates (need >= {min_count})")
    return failures

def check_no_duplicate_compositions(templates):
    seen = {}
    dupes = []
    for t in templates:
        ring = t["ring"]
        key = (ring, tuple(sorted(t.get("enemy_ids", []))))
        if key in seen:
            dupes.append(f"  '{t['id']}' duplicates '{seen[key]}' in ring '{ring}'")
        else:
            seen[key] = t["id"]
    return dupes

def check_enemy_counts(enemies, minimums):
    counts = {}
    for e in enemies:
        for ring in e.get("rings", []):
            counts[ring] = counts.get(ring, 0) + 1
    failures = []
    for ring, minimum in minimums.items():
        n = counts.get(ring, 0)
        if n < minimum:
            failures.append(f"  {ring}: {n} enemies (need >= {minimum})")
    return failures

def check_all_ids_resolve(templates, enemies):
    known = {e["id"] for e in enemies}
    failures = []
    for t in templates:
        for eid in t.get("enemy_ids", []):
            if eid not in known:
                failures.append(f"  template '{t['id']}' references unknown enemy '{eid}'")
    return failures

def check_template_sizes(templates, min_size=1, max_size=5):
    failures = []
    for t in templates:
        n = len(t.get("enemy_ids", []))
        if not (min_size <= n <= max_size):
            failures.append(f"  template '{t['id']}': {n} enemies (valid range {min_size}-{max_size})")
    return failures

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    templates_path = os.path.join(base, "game", "data", "encounter_templates.json")
    enemies_path = os.path.join(base, "game", "data", "enemies.json")

    templates_data = load(templates_path)
    enemies_data = load(enemies_path)

    templates = templates_data["templates"]
    enemies = enemies_data["enemies"]

    all_failures = []

    failures = check_template_counts(templates, min_count=5)
    if failures:
        print("FAIL - template count per ring:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - template count per ring")

    failures = check_no_duplicate_compositions(templates)
    if failures:
        print("FAIL - duplicate compositions:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - no duplicate compositions")

    failures = check_enemy_counts(enemies, {"inner": 4, "mid": 5, "outer": 5})
    if failures:
        print("FAIL - enemy count per ring:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - enemy count per ring")

    failures = check_all_ids_resolve(templates, enemies)
    if failures:
        print("FAIL - unresolved enemy references:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - all template enemy_ids resolve")

    failures = check_template_sizes(templates)
    if failures:
        print("FAIL - template sizes out of range:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - template sizes in range")

    if all_failures:
        print(f"\n{len(all_failures)} check(s) failed.")
        sys.exit(1)
    else:
        print("\nAll content volume checks passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
```

---

## Verification Commands
```bash
python3 scripts/ci/check_content_volume.py
grep -c '"ring": "inner"' game/data/encounter_templates.json
grep -c '"ring": "mid"' game/data/encounter_templates.json
grep -c '"ring": "outer"' game/data/encounter_templates.json
python3 -c "import json; e=json.load(open('game/data/enemies.json')); print([x['id'] for x in e['enemies']])"
```

## Acceptance Criteria
- AC1: check_content_volume.py exits 0
- AC2-AC4: >= 5 templates per ring
- AC5: No duplicate compositions

## Notes
Run check_content_volume.py before committing to catch any mistakes. If enemies.json uses
ring_availability (string) instead of rings (array), the enemy count check needs adaptation.
Look at the actual enemy format first and adjust the check_enemy_counts function accordingly.
The script path resolution uses os.path to find game/data relative to scripts/ci/.
