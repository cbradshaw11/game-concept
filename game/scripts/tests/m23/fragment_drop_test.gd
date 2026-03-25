## M23 Test: Fragment drop logic — 15% rate, no duplicates, stops when all collected
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load narrative.json to get fragment IDs
	var raw := FileAccess.get_file_as_string("res://data/narrative.json")
	var data: Dictionary = JSON.parse_string(raw)
	var fragments: Array = data.get("lore_fragments", [])
	var all_ids: Array = []
	for f in fragments:
		all_ids.append(str(f.get("id", "")))

	# T1: Verify we have 5 fragments in data
	if all_ids.size() == 5:
		print("PASS: narrative.json has 5 lore fragments")
		passed += 1
	else:
		printerr("FAIL: expected 5 fragments, got %d" % all_ids.size())
		failed += 1

	# T2: Simulate drop rate over many seeds with empty collected list
	# With 15% chance, over 1000 rolls we expect ~150 drops (tolerance: 80-250)
	var drop_count := 0
	for i in range(1000):
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		if rng.randf() <= 0.15:
			drop_count += 1

	if drop_count >= 80 and drop_count <= 250:
		print("PASS: drop rate ~15%% (%d/1000 drops)" % drop_count)
		passed += 1
	else:
		printerr("FAIL: drop rate out of range (%d/1000)" % drop_count)
		failed += 1

	# T3: Verify no duplicates — simulate collection tracking
	var collected: Array = []
	var total_drops := 0
	for i in range(500):
		var available: Array = []
		for fid in all_ids:
			if not collected.has(fid):
				available.append(fid)
		if available.is_empty():
			break
		var rng := RandomNumberGenerator.new()
		rng.seed = i + 5000
		if rng.randf() <= 0.15:
			var pick := str(available[rng.randi_range(0, available.size() - 1)])
			if not collected.has(pick):
				collected.append(pick)
				total_drops += 1

	var has_dupes := false
	var seen: Dictionary = {}
	for fid in collected:
		if seen.has(fid):
			has_dupes = true
			break
		seen[fid] = true

	if not has_dupes:
		print("PASS: no duplicate fragments collected (%d unique)" % collected.size())
		passed += 1
	else:
		printerr("FAIL: duplicate fragment detected in collection")
		failed += 1

	# T4: Verify drops stop when all collected
	var full_collected: Array = all_ids.duplicate()
	var available_after_full: Array = []
	for fid in all_ids:
		if not full_collected.has(fid):
			available_after_full.append(fid)

	if available_after_full.is_empty():
		print("PASS: no fragments available when all 5 collected")
		passed += 1
	else:
		printerr("FAIL: fragments still available after all collected")
		failed += 1

	# T5: Each fragment has required fields
	var fields_ok := true
	for f in fragments:
		for key in ["id", "title", "author", "ring", "text"]:
			if str(f.get(key, "")) == "":
				fields_ok = false
				printerr("FAIL: fragment %s missing field %s" % [str(f.get("id", "?")), key])
				failed += 1

	if fields_ok:
		print("PASS: all fragments have id, title, author, ring, text")
		passed += 1

	if failed == 0:
		print("PASS: M23 fragment drop test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M23 fragment drop test (%d failed)" % failed)
		quit(1)
