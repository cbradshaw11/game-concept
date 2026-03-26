## M26 Test: Modifier data — verify all 20 run_modifiers have required fields,
## correct weights per tier, no duplicate ids
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load modifiers.json directly
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Variant = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		printerr("FAIL: modifiers.json is not a valid dictionary")
		quit()
		return

	var run_modifiers: Array = data.get("run_modifiers", [])

	# ─── Exactly 20 run modifiers ─────────────────────────────────────────
	if run_modifiers.size() == 20:
		print("PASS: run_modifiers has exactly 20 entries")
		passed += 1
	else:
		printerr("FAIL: run_modifiers has %d entries, expected 20" % run_modifiers.size())
		failed += 1

	# ─── No duplicate ids ─────────────────────────────────────────────────
	var ids: Dictionary = {}
	var has_dupes := false
	for mod in run_modifiers:
		var mid := str(mod.get("id", ""))
		if ids.has(mid):
			has_dupes = true
			printerr("FAIL: duplicate run_modifier id: %s" % mid)
			failed += 1
		ids[mid] = true
	if not has_dupes:
		print("PASS: no duplicate run_modifier ids")
		passed += 1

	# ─── Required fields on every modifier ────────────────────────────────
	var required_fields := ["id", "name", "description", "flavor", "tier", "weight", "effects"]
	var all_fields_ok := true
	for mod in run_modifiers:
		for field in required_fields:
			if not mod.has(field):
				all_fields_ok = false
				printerr("FAIL: modifier '%s' missing field '%s'" % [mod.get("id", "?"), field])
				failed += 1
	if all_fields_ok:
		print("PASS: all 20 modifiers have required fields (id, name, description, flavor, tier, weight, effects)")
		passed += 1

	# ─── Tier distribution: 6 common, 7 uncommon, 7 rare ──────────────────
	var tier_counts := {1: 0, 2: 0, 3: 0}
	for mod in run_modifiers:
		var t := int(mod.get("tier", 0))
		tier_counts[t] = int(tier_counts.get(t, 0)) + 1

	if tier_counts[1] == 6:
		print("PASS: 6 tier-1 (common) modifiers")
		passed += 1
	else:
		printerr("FAIL: tier-1 count is %d, expected 6" % tier_counts[1])
		failed += 1

	if tier_counts[2] == 7:
		print("PASS: 7 tier-2 (uncommon) modifiers")
		passed += 1
	else:
		printerr("FAIL: tier-2 count is %d, expected 7" % tier_counts[2])
		failed += 1

	if tier_counts[3] == 7:
		print("PASS: 7 tier-3 (rare) modifiers")
		passed += 1
	else:
		printerr("FAIL: tier-3 count is %d, expected 7" % tier_counts[3])
		failed += 1

	# ─── Correct weights per tier ─────────────────────────────────────────
	var weight_ok := true
	for mod in run_modifiers:
		var t := int(mod.get("tier", 0))
		var w := int(mod.get("weight", 0))
		var expected_w := 10 if t == 1 else (5 if t == 2 else 2)
		if w != expected_w:
			weight_ok = false
			printerr("FAIL: modifier '%s' tier %d has weight %d, expected %d" % [mod.get("id", "?"), t, w, expected_w])
			failed += 1
	if weight_ok:
		print("PASS: all modifiers have correct weight for their tier (t1=10, t2=5, t3=2)")
		passed += 1

	# ─── Effects is always a dictionary ────────────────────────────────────
	var effects_ok := true
	for mod in run_modifiers:
		if typeof(mod.get("effects", null)) != TYPE_DICTIONARY:
			effects_ok = false
			printerr("FAIL: modifier '%s' effects is not a dictionary" % mod.get("id", "?"))
			failed += 1
	if effects_ok:
		print("PASS: all modifiers have effects as Dictionary")
		passed += 1

	# ─── Summary ──────────────────────────────────────────────────────────
	print("")
	print("modifier_data_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
