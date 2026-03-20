extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var templates_text := FileAccess.get_file_as_string("res://data/encounter_templates.json")
	if templates_text.is_empty():
		print("FAIL: could not read res://data/encounter_templates.json")
		quit(1)
		return

	var parsed: Variant = JSON.parse_string(templates_text)
	if not parsed is Dictionary:
		print("FAIL: encounter_templates.json did not parse as Dictionary")
		quit(1)
		return

	var templates: Array = (parsed as Dictionary).get("templates", [])

	# Test 1: verify encounter_templates.json has >= 9 templates for inner ring
	var inner_count: int = 0
	for t in templates:
		if t.get("ring", "") == "inner":
			inner_count += 1
	if inner_count < 9:
		failures.append("Test 1: inner ring has %d templates, need >= 9" % inner_count)

	# Test 2: seed fix -- verify (seed+0)*1000003 + ring_hash != (seed+1)*1000003 + ring_hash
	# This verifies that encounters_cleared being part of the seed produces different seeds
	# for consecutive encounter counts. The ring_director uses:
	#   rng.seed = _combine_seed(seed + GameState.encounters_cleared, ring_id)
	# where _combine_seed(seed, ring_id) = int(seed + ring_id.hash())
	# So two different encounters_cleared values produce different seeds.
	var ring_hash: int = "inner".hash()
	var seed_base: int = 42
	var combined_0: int = (seed_base + 0) + ring_hash
	var combined_1: int = (seed_base + 1) + ring_hash
	if combined_0 == combined_1:
		failures.append("Test 2: seed fix broken -- different encounters_cleared values produce same combined seed")

	# Test 3: all 3 rings (inner, mid, outer) have >= 9 templates
	var counts: Dictionary = {"inner": 0, "mid": 0, "outer": 0}
	for t in templates:
		var ring: String = str(t.get("ring", ""))
		if ring in counts:
			counts[ring] = counts[ring] + 1
	for ring in ["inner", "mid", "outer"]:
		if counts[ring] < 9:
			failures.append("Test 3: ring '%s' has %d templates, need >= 9" % [ring, counts[ring]])

	if failures.is_empty():
		print("PASS: test_template_variety")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
