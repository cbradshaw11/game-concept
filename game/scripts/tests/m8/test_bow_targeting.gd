extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Load weapons.json directly via FileAccess
	var file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if file == null:
		failures.append("Test 1: could not open res://data/weapons.json")
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed := JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		failures.append("Test 1: failed to parse weapons.json")
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
		return

	var weapons: Array = parsed.get("weapons", [])

	# Test 1: bow_iron has ranged_priority: true
	var bow_data: Dictionary = {}
	for w in weapons:
		if w.get("id") == "bow_iron":
			bow_data = w
			break
	if bow_data.is_empty():
		failures.append("Test 1: bow_iron not found in weapons.json")
	elif not bow_data.get("ranged_priority", false):
		failures.append("Test 1: bow_iron should have ranged_priority=true, got %s" % str(bow_data.get("ranged_priority", "absent")))

	# Test 2: blade_iron does NOT have ranged_priority (absent or false)
	var blade_data: Dictionary = {}
	for w in weapons:
		if w.get("id") == "blade_iron":
			blade_data = w
			break
	if blade_data.is_empty():
		failures.append("Test 2: blade_iron not found in weapons.json")
	elif blade_data.get("ranged_priority", false) == true:
		failures.append("Test 2: blade_iron should NOT have ranged_priority=true")

	# Test 3: polearm_iron does NOT have ranged_priority (absent or false)
	var polearm_data: Dictionary = {}
	for w in weapons:
		if w.get("id") == "polearm_iron":
			polearm_data = w
			break
	if polearm_data.is_empty():
		failures.append("Test 3: polearm_iron not found in weapons.json")
	elif polearm_data.get("ranged_priority", false) == true:
		failures.append("Test 3: polearm_iron should NOT have ranged_priority=true")

	if failures.is_empty():
		print("PASS: test_bow_targeting")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
