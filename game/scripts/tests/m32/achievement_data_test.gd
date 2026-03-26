extends SceneTree
## M32 — Achievement data validation
## Verifies: all 20 achievements have required fields, unique ids, hidden is bool

func _init() -> void:
	var path := "res://data/achievements.json"
	if not FileAccess.file_exists(path):
		printerr("FAIL: achievements.json not found")
		quit(1)
		return

	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("FAIL: achievements.json is not a valid dictionary")
		quit(1)
		return

	var achievements: Array = parsed.get("achievements", [])

	# Test 1: Exactly 20 achievements
	if achievements.size() == 20:
		print("PASS: achievements.json contains exactly 20 achievements")
	else:
		printerr("FAIL: expected 20 achievements, got %d" % achievements.size())

	# Test 2: All required fields present
	var required_fields := ["id", "name", "description", "flavor_text", "category", "hidden"]
	var all_fields_ok := true
	for ach in achievements:
		for field in required_fields:
			if not ach.has(field):
				printerr("FAIL: achievement '%s' missing field '%s'" % [str(ach.get("id", "???")), field])
				all_fields_ok = false
	if all_fields_ok:
		print("PASS: all achievements have required fields (id, name, description, flavor_text, category, hidden)")
	else:
		printerr("FAIL: some achievements are missing required fields")

	# Test 3: All ids are unique
	var ids: Array = []
	var duplicates: Array = []
	for ach in achievements:
		var aid := str(ach.get("id", ""))
		if ids.has(aid):
			duplicates.append(aid)
		ids.append(aid)
	if duplicates.is_empty():
		print("PASS: all achievement ids are unique")
	else:
		printerr("FAIL: duplicate achievement ids: %s" % str(duplicates))

	# Test 4: hidden field is bool for all achievements
	var hidden_ok := true
	for ach in achievements:
		if typeof(ach.get("hidden")) != TYPE_BOOL:
			printerr("FAIL: achievement '%s' hidden field is not bool (type=%d)" % [str(ach.get("id", "???")), typeof(ach.get("hidden"))])
			hidden_ok = false
	if hidden_ok:
		print("PASS: all achievements have bool hidden field")

	# Test 5: Exactly 3 hidden achievements
	var hidden_count := 0
	for ach in achievements:
		if bool(ach.get("hidden", false)):
			hidden_count += 1
	if hidden_count == 3:
		print("PASS: exactly 3 hidden achievements")
	else:
		printerr("FAIL: expected 3 hidden achievements, got %d" % hidden_count)

	# Test 6: Categories data present
	var categories: Dictionary = parsed.get("categories", {})
	var order: Array = parsed.get("category_order", [])
	if categories.size() == 4 and order.size() == 4:
		print("PASS: 4 categories with order defined")
	else:
		printerr("FAIL: expected 4 categories, got %d categories and %d order entries" % [categories.size(), order.size()])

	quit(0)
