extends SceneTree
## M34 — Save version v10 tests
## Verifies: save writes v10, v9 save migrates cleanly, all new fields have defaults

const SaveSystem = preload("res://scripts/systems/save_system.gd")

func _init() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Test 1: SAVE_VERSION is 10 ──────────────────────────────────────────
	if SaveSystem.SAVE_VERSION == 10:
		print("PASS: SAVE_VERSION is 10")
		checks_passed += 1
	else:
		printerr("FAIL: SAVE_VERSION should be 10, got %d" % SaveSystem.SAVE_VERSION)
		checks_failed += 1

	# ── Test 2: save_state writes _save_version field ────────────────────────
	var test_data := {"banked_xp": 42}
	# We can't write to disk in headless easily, so test that save_state
	# injects the version into the dict (it mutates in-place before write)
	SaveSystem.save_state(test_data)
	if test_data.has("_save_version") and int(test_data["_save_version"]) == 10:
		print("PASS: save_state injects _save_version = 10 into data")
		checks_passed += 1
	else:
		printerr("FAIL: save_state should inject _save_version = 10")
		checks_failed += 1

	# ── Test 3: v9 save (missing M27-M32 fields) migrates cleanly ────────────
	# Simulate a v9 save — has everything up to collected_fragments but NOT
	# resonance_shards, unlocked_achievements, etc.
	var v9_save := {
		"banked_xp": 100,
		"banked_loot": 50,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"extractions_by_ring": {"inner": 2},
		"vendor_upgrades": {"iron_will": 1},
		"run_history": [],
		"artifact_retrieved": false,
		"total_runs": 5,
		"total_extractions": 3,
		"total_deaths": 2,
		"deepest_ring_reached": "mid",
		"artifact_retrievals": 0,
		"fastest_extraction_seconds": 120.5,
		"collected_fragments": ["frag_01"],
		# NOTE: no resonance_shards, permanent_unlocks, unlocked_achievements,
		# lifetime_kills, lifetime_poise_breaks, completed_challenges
	}

	var defaults := _get_default_save_state()
	var migrated := SaveSystem._merge_with_defaults(v9_save, defaults)

	# Preserved v9 fields
	if int(migrated.get("banked_xp", 0)) == 100:
		print("PASS: v9 migration preserves banked_xp")
		checks_passed += 1
	else:
		printerr("FAIL: v9 migration lost banked_xp, got %d" % int(migrated.get("banked_xp", 0)))
		checks_failed += 1

	if migrated.get("collected_fragments", []).size() == 1:
		print("PASS: v9 migration preserves collected_fragments")
		checks_passed += 1
	else:
		printerr("FAIL: v9 migration lost collected_fragments")
		checks_failed += 1

	# New v10 fields get defaults
	if int(migrated.get("resonance_shards", -1)) == 0:
		print("PASS: v9→v10 migration: resonance_shards defaults to 0")
		checks_passed += 1
	else:
		printerr("FAIL: resonance_shards should default to 0, got %s" % str(migrated.get("resonance_shards")))
		checks_failed += 1

	if int(migrated.get("resonance_spent", -1)) == 0:
		print("PASS: v9→v10 migration: resonance_spent defaults to 0")
		checks_passed += 1
	else:
		printerr("FAIL: resonance_spent should default to 0")
		checks_failed += 1

	if typeof(migrated.get("permanent_unlocks")) == TYPE_ARRAY and migrated.get("permanent_unlocks", []).is_empty():
		print("PASS: v9→v10 migration: permanent_unlocks defaults to []")
		checks_passed += 1
	else:
		printerr("FAIL: permanent_unlocks should default to []")
		checks_failed += 1

	if typeof(migrated.get("unlocked_achievements")) == TYPE_ARRAY and migrated.get("unlocked_achievements", []).is_empty():
		print("PASS: v9→v10 migration: unlocked_achievements defaults to []")
		checks_passed += 1
	else:
		printerr("FAIL: unlocked_achievements should default to []")
		checks_failed += 1

	if int(migrated.get("lifetime_kills", -1)) == 0:
		print("PASS: v9→v10 migration: lifetime_kills defaults to 0")
		checks_passed += 1
	else:
		printerr("FAIL: lifetime_kills should default to 0")
		checks_failed += 1

	if int(migrated.get("lifetime_poise_breaks", -1)) == 0:
		print("PASS: v9→v10 migration: lifetime_poise_breaks defaults to 0")
		checks_passed += 1
	else:
		printerr("FAIL: lifetime_poise_breaks should default to 0")
		checks_failed += 1

	if typeof(migrated.get("completed_challenges")) == TYPE_ARRAY and migrated.get("completed_challenges", []).is_empty():
		print("PASS: v9→v10 migration: completed_challenges defaults to []")
		checks_passed += 1
	else:
		printerr("FAIL: completed_challenges should default to []")
		checks_failed += 1

	# ── Test 4: All default_save_state fields are present after migration ────
	var missing_keys: Array = []
	for key in defaults.keys():
		if not migrated.has(key):
			missing_keys.append(key)
	if missing_keys.is_empty():
		print("PASS: all default_save_state keys present after v9→v10 migration")
		checks_passed += 1
	else:
		printerr("FAIL: missing keys after migration: %s" % str(missing_keys))
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M34 save v10 tests (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M34 save v10 tests (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)

func _get_default_save_state() -> Dictionary:
	## Mirror of GameState.default_save_state() for test isolation
	return {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"extractions_by_ring": {},
		"vendor_upgrades": {},
		"run_history": [],
		"artifact_retrieved": false,
		"total_runs": 0,
		"total_extractions": 0,
		"total_deaths": 0,
		"deepest_ring_reached": "",
		"artifact_retrievals": 0,
		"fastest_extraction_seconds": 0.0,
		"collected_fragments": [],
		"resonance_shards": 0,
		"resonance_spent": 0,
		"permanent_unlocks": [],
		"unlocked_achievements": [],
		"lifetime_kills": 0,
		"lifetime_poise_breaks": 0,
		"completed_challenges": [],
	}
