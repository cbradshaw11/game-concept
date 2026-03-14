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

REQUIRED_ENEMY_FIELDS = ["id", "role", "rings", "health", "poise", "damage", "poise_damage", "behavior_profile"]

def check_enemy_schema(enemies):
    failures = []
    for e in enemies:
        for field in REQUIRED_ENEMY_FIELDS:
            if field not in e:
                failures.append(f"  enemy '{e.get('id','?')}' missing required field '{field}'")
    return failures

def main():
    base = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    templates_path = os.path.join(base, "game", "data", "encounter_templates.json")
    enemies_path = os.path.join(base, "game", "data", "enemies.json")

    templates_data = load(templates_path)
    enemies_data = load(enemies_path)

    templates = templates_data["templates"]
    enemies = enemies_data["enemies"]

    all_failures = []

    failures = check_template_counts(templates, min_count=9)
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

    failures = check_enemy_schema(enemies)
    if failures:
        print("FAIL - enemy schema incomplete:")
        for f in failures:
            print(f)
        all_failures.extend(failures)
    else:
        print("PASS - enemy schema complete")

    if all_failures:
        print(f"\n{len(all_failures)} check(s) failed.")
        sys.exit(1)
    else:
        print("\nAll content volume checks passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
