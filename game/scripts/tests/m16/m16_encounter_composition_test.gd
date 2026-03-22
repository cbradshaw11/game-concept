## M16 Test: Encounter templates max-2-same-type and new enemies in mid/outer (M16 T7)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var templates_data: Variant = _load_json("res://data/encounter_templates.json")
	if templates_data == null or typeof(templates_data) != TYPE_DICTIONARY:
		printerr("FAIL: encounter_templates.json missing or invalid")
		quit(1)
		return

	var templates: Array = templates_data.get("templates", [])

	# ── At least 10 templates total ──────────────────────────────────────────
	if templates.size() >= 10:
		print("PASS: encounter_templates.json has %d templates (>= 10)" % templates.size())
		checks_passed += 1
	else:
		printerr("FAIL: encounter_templates.json should have >= 10 templates, got %d" % templates.size())
		checks_failed += 1

	# ── Max 2 of the same enemy type per template ────────────────────────────
	var max_same_violation := false
	for template in templates:
		var tmpl_id := str(template.get("id", "?"))
		var enemy_ids: Array = template.get("enemy_ids", [])
		var type_counts: Dictionary = {}
		for eid in enemy_ids:
			var key := str(eid)
			type_counts[key] = int(type_counts.get(key, 0)) + 1
		for eid in type_counts:
			if int(type_counts[eid]) > 2:
				printerr("FAIL: template '%s' has %d of '%s' (max 2 allowed)" % [tmpl_id, type_counts[eid], eid])
				checks_failed += 1
				max_same_violation = true

	if not max_same_violation:
		print("PASS: all templates enforce max 2 of same enemy type")
		checks_passed += 1

	# ── Mid ring has >= 4 templates ──────────────────────────────────────────
	var mid_count := 0
	for tmpl in templates:
		if str(tmpl.get("ring", "")) == "mid":
			mid_count += 1
	if mid_count >= 4:
		print("PASS: mid ring has %d templates (>= 4)" % mid_count)
		checks_passed += 1
	else:
		printerr("FAIL: mid ring should have >= 4 templates, got %d" % mid_count)
		checks_failed += 1

	# ── Outer ring has >= 3 templates ───────────────────────────────────────
	var outer_count := 0
	for tmpl in templates:
		if str(tmpl.get("ring", "")) == "outer":
			outer_count += 1
	if outer_count >= 3:
		print("PASS: outer ring has %d templates (>= 3)" % outer_count)
		checks_passed += 1
	else:
		printerr("FAIL: outer ring should have >= 3 templates, got %d" % outer_count)
		checks_failed += 1

	# ── Berserker appears in at least one mid or outer template ─────────────
	var berserker_in_template := false
	for tmpl in templates:
		var ring := str(tmpl.get("ring", ""))
		if ring in ["mid", "outer"]:
			if "berserker" in tmpl.get("enemy_ids", []):
				berserker_in_template = true
				break
	if berserker_in_template:
		print("PASS: berserker appears in at least one mid/outer template")
		checks_passed += 1
	else:
		printerr("FAIL: berserker should appear in at least one mid/outer template")
		checks_failed += 1

	# ── Shield Wall appears in at least one mid or outer template ───────────
	var shield_wall_in_template := false
	for tmpl in templates:
		var ring := str(tmpl.get("ring", ""))
		if ring in ["mid", "outer"]:
			if "shield_wall" in tmpl.get("enemy_ids", []):
				shield_wall_in_template = true
				break
	if shield_wall_in_template:
		print("PASS: shield_wall appears in at least one mid/outer template")
		checks_passed += 1
	else:
		printerr("FAIL: shield_wall should appear in at least one mid/outer template")
		checks_failed += 1

	# ── Berserker NOT in inner ring templates ────────────────────────────────
	var berserker_in_inner := false
	for tmpl in templates:
		if str(tmpl.get("ring", "")) == "inner":
			if "berserker" in tmpl.get("enemy_ids", []):
				berserker_in_inner = true
				break
	if not berserker_in_inner:
		print("PASS: berserker does not appear in inner ring templates")
		checks_passed += 1
	else:
		printerr("FAIL: berserker should NOT appear in inner ring templates")
		checks_failed += 1

	# ── RingDirector max-2 enforcement test (logic unit test) ───────────────
	const RingDirector = preload("res://scripts/systems/ring_director.gd")
	var director := RingDirector.new()

	# Build a fake enemies_data with only one enemy type to test type-count enforcement
	var fake_enemies_data := {
		"enemies": [
			{"id": "grunt_test", "rings": ["inner"], "health": 50, "poise": 10, "damage": 5, "behavior_profile": "test"},
		]
	}
	# Run many seeds and check no encounter has > 2 of same type
	var violation_found := false
	for test_seed in range(10):
		var encounter := director.generate_encounter(test_seed * 1234, "inner", fake_enemies_data)
		var encountered_enemies: Array = encounter.get("enemies", [])
		var type_counts: Dictionary = {}
		for e in encountered_enemies:
			var eid := str(e.get("id", ""))
			type_counts[eid] = int(type_counts.get(eid, 0)) + 1
		for eid in type_counts:
			if int(type_counts[eid]) > 2:
				violation_found = true

	if not violation_found:
		print("PASS: RingDirector enforces max 2 same enemy type (10 seeds tested)")
		checks_passed += 1
	else:
		printerr("FAIL: RingDirector allowed > 2 of same enemy type in encounter")
		checks_failed += 1

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 encounter composition test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 encounter composition test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
