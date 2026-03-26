## M31 Test: Challenge run data validation — all 8 challenges have required fields,
## shard bonuses are positive, unlock conditions reference valid GameState fields
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load modifiers.json directly
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Dictionary = JSON.parse_string(raw)
	var challenges: Array = data.get("challenge_runs", [])

	# Test 1: 8 challenge runs defined
	if challenges.size() == 8:
		print("PASS: 8 challenge runs defined")
		passed += 1
	else:
		print("FAIL: expected 8 challenge runs, got %d" % challenges.size())
		failed += 1

	# Test 2: All challenges have required fields
	var required_fields := ["id", "name", "description", "unlock_type", "unlock_threshold", "shard_bonus"]
	var all_valid := true
	for ch in challenges:
		for field in required_fields:
			if not ch.has(field):
				print("FAIL: challenge '%s' missing field '%s'" % [str(ch.get("id", "?")), field])
				all_valid = false
				failed += 1
	if all_valid:
		print("PASS: all challenges have required fields (id, name, description, unlock_type, unlock_threshold, shard_bonus)")
		passed += 1

	# Test 3: All shard bonuses are positive
	var bonuses_ok := true
	for ch in challenges:
		if int(ch.get("shard_bonus", 0)) <= 0:
			bonuses_ok = false
			print("FAIL: challenge '%s' has non-positive shard_bonus" % str(ch.get("id", "?")))
			failed += 1
	if bonuses_ok:
		print("PASS: all shard bonuses are positive")
		passed += 1

	# Test 4: No duplicate ids
	var ids: Array = []
	var dup_found := false
	for ch in challenges:
		var cid := str(ch.get("id", ""))
		if ids.has(cid):
			dup_found = true
			print("FAIL: duplicate challenge id '%s'" % cid)
			failed += 1
		ids.append(cid)
	if not dup_found:
		print("PASS: no duplicate challenge ids")
		passed += 1

	# Test 5: unlock_type is valid (total_runs or artifact_retrievals)
	var valid_types := ["total_runs", "artifact_retrievals"]
	var types_ok := true
	for ch in challenges:
		var ut := str(ch.get("unlock_type", ""))
		if not valid_types.has(ut):
			types_ok = false
			print("FAIL: challenge '%s' has invalid unlock_type '%s'" % [str(ch.get("id", "?")), ut])
			failed += 1
	if types_ok:
		print("PASS: all unlock_type values are valid GameState fields")
		passed += 1

	# Test 6: Expected challenge ids are present
	var expected_ids := ["iron_road", "time_pressure", "one_life", "naked_run", "escalation", "warden_hunt", "cursed_ground", "silent_run"]
	var all_present := true
	for eid in expected_ids:
		if not ids.has(eid):
			all_present = false
			print("FAIL: expected challenge '%s' not found" % eid)
			failed += 1
	if all_present:
		print("PASS: all 8 expected challenge ids present")
		passed += 1

	# Test 7: time_pressure has time_limits dict
	var tp := {}
	for ch in challenges:
		if str(ch.get("id", "")) == "time_pressure":
			tp = ch
	if not tp.is_empty() and tp.has("time_limits"):
		var limits: Variant = tp.get("time_limits", {})
		if typeof(limits) == TYPE_DICTIONARY and limits.has("inner") and limits.has("mid") and limits.has("outer"):
			print("PASS: time_pressure has time_limits for inner/mid/outer")
			passed += 1
		else:
			print("FAIL: time_pressure time_limits missing ring keys")
			failed += 1
	else:
		print("FAIL: time_pressure missing time_limits field")
		failed += 1

	# Test 8: warden_hunt uses artifact_retrievals unlock
	var wh := {}
	for ch in challenges:
		if str(ch.get("id", "")) == "warden_hunt":
			wh = ch
	if not wh.is_empty() and str(wh.get("unlock_type", "")) == "artifact_retrievals":
		print("PASS: warden_hunt uses artifact_retrievals unlock type")
		passed += 1
	else:
		print("FAIL: warden_hunt should use artifact_retrievals unlock type")
		failed += 1

	print("\nChallenge data tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
