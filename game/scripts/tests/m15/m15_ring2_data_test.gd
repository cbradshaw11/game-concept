## M15 Test: Verify Ring 2 ("mid") data in rings.json (M15 T7, T9)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var rings_data: Variant = _load_json("res://data/rings.json")
	if rings_data == null or typeof(rings_data) != TYPE_DICTIONARY:
		printerr("FAIL: rings.json missing or invalid")
		quit(1)
		return

	var rings: Array = rings_data.get("rings", [])

	# Find mid ring
	var mid_ring: Dictionary = {}
	for ring in rings:
		if str(ring.get("id", "")) == "mid":
			mid_ring = ring
			break

	if mid_ring.is_empty():
		printerr("FAIL: 'mid' ring not found in rings.json")
		quit(1)
		return

	print("PASS: mid ring entry exists in rings.json")
	checks_passed += 1

	# index should be 2
	if int(mid_ring.get("index", -1)) == 2:
		print("PASS: mid ring index is 2")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring index should be 2, got %s" % mid_ring.get("index", "?"))
		checks_failed += 1

	# combat_enabled should be true
	if bool(mid_ring.get("combat_enabled", false)):
		print("PASS: mid ring combat_enabled = true")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring combat_enabled should be true")
		checks_failed += 1

	# xp_multiplier >= 1.4 (M15 spec says 1.5)
	var xp_mult := float(mid_ring.get("xp_multiplier", 0.0))
	if xp_mult >= 1.4:
		print("PASS: mid ring xp_multiplier >= 1.4 (%.2f)" % xp_mult)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring xp_multiplier too low: %.2f" % xp_mult)
		checks_failed += 1

	# loot_multiplier >= 1.4
	var loot_mult := float(mid_ring.get("loot_multiplier", 0.0))
	if loot_mult >= 1.4:
		print("PASS: mid ring loot_multiplier >= 1.4 (%.2f)" % loot_mult)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring loot_multiplier too low: %.2f" % loot_mult)
		checks_failed += 1

	# contract_target >= 4 (harder than inner)
	var contract_target := int(mid_ring.get("contract_target", 0))
	if contract_target >= 4:
		print("PASS: mid ring contract_target >= 4 (%d)" % contract_target)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring contract_target should be >= 4, got %d" % contract_target)
		checks_failed += 1

	# unlock_condition should be set
	var unlock_cond := str(mid_ring.get("unlock_condition", ""))
	if unlock_cond != "":
		print("PASS: mid ring has unlock_condition: '%s'" % unlock_cond)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring missing unlock_condition")
		checks_failed += 1

	# background field should be set
	var bg := str(mid_ring.get("background", ""))
	if bg != "":
		print("PASS: mid ring has background: '%s'" % bg)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring missing background field")
		checks_failed += 1

	# Check encounter templates have mid ring entries
	var templates_data: Variant = _load_json("res://data/encounter_templates.json")
	if templates_data != null and typeof(templates_data) == TYPE_DICTIONARY:
		var templates: Array = templates_data.get("templates", [])
		var mid_templates := 0
		for tmpl in templates:
			if str(tmpl.get("ring", "")) == "mid":
				mid_templates += 1
		if mid_templates > 0:
			print("PASS: encounter_templates.json has %d mid ring templates" % mid_templates)
			checks_passed += 1
		else:
			printerr("FAIL: no mid ring templates in encounter_templates.json")
			checks_failed += 1

	if checks_failed == 0:
		print("PASS: M15 Ring 2 data test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M15 Ring 2 data test (%d failed)" % checks_failed)
		quit(1)
