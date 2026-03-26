## M25 Test: Template data integrity — all templates have required fields,
## enemy ids exist in enemies.json, weights are in valid range 1-10.
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load data files
	var templates_file := FileAccess.open("res://data/encounter_templates.json", FileAccess.READ)
	var templates_data: Dictionary = JSON.parse_string(templates_file.get_as_text())
	templates_file.close()

	var enemies_file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	var enemies_data: Dictionary = JSON.parse_string(enemies_file.get_as_text())
	enemies_file.close()

	var templates: Array = templates_data.get("templates", [])

	# Build set of valid enemy ids
	var valid_enemy_ids: Dictionary = {}
	for enemy in enemies_data.get("enemies", []):
		valid_enemy_ids[str(enemy.get("id", ""))] = true

	# ─── All templates have required fields ─────────────────────────────────
	var required_fields := ["id", "ring", "name", "enemy_ids", "weight"]
	var all_have_fields := true
	var missing_report := ""
	for template in templates:
		for field in required_fields:
			if not template.has(field):
				all_have_fields = false
				missing_report += "%s missing '%s'; " % [template.get("id", "???"), field]
	if all_have_fields:
		print("PASS: all %d templates have required fields (id, ring, name, enemy_ids, weight)" % templates.size())
		passed += 1
	else:
		printerr("FAIL: missing fields — %s" % missing_report)
		failed += 1

	# ─── All enemy_ids reference valid enemies ──────────────────────────────
	var all_ids_valid := true
	var bad_ids := ""
	for template in templates:
		for eid in template.get("enemy_ids", []):
			if not valid_enemy_ids.has(str(eid)):
				all_ids_valid = false
				bad_ids += "%s has unknown enemy '%s'; " % [template.get("id", "???"), eid]
	if all_ids_valid:
		print("PASS: all enemy_ids in templates reference valid enemies from enemies.json")
		passed += 1
	else:
		printerr("FAIL: invalid enemy ids — %s" % bad_ids)
		failed += 1

	# ─── All weights are in range 1-10 ──────────────────────────────────────
	var all_weights_valid := true
	var bad_weights := ""
	for template in templates:
		var w := int(template.get("weight", 0))
		if w < 1 or w > 10:
			all_weights_valid = false
			bad_weights += "%s has weight %d; " % [template.get("id", "???"), w]
	if all_weights_valid:
		print("PASS: all template weights are in range 1-10")
		passed += 1
	else:
		printerr("FAIL: out-of-range weights — %s" % bad_weights)
		failed += 1

	# ─── All template ids are unique ────────────────────────────────────────
	var seen_ids: Dictionary = {}
	var duplicates := ""
	for template in templates:
		var tid := str(template.get("id", ""))
		if seen_ids.has(tid):
			duplicates += "'%s' " % tid
		seen_ids[tid] = true
	if duplicates == "":
		print("PASS: all %d template ids are unique" % templates.size())
		passed += 1
	else:
		printerr("FAIL: duplicate template ids — %s" % duplicates)
		failed += 1

	# ─── All templates have valid ring values ───────────────────────────────
	var valid_rings := {"inner": true, "mid": true, "outer": true}
	var all_rings_valid := true
	for template in templates:
		if not valid_rings.has(str(template.get("ring", ""))):
			all_rings_valid = false
	if all_rings_valid:
		print("PASS: all templates have valid ring values (inner/mid/outer)")
		passed += 1
	else:
		printerr("FAIL: some templates have invalid ring values")
		failed += 1

	# ─── Total template count ───────────────────────────────────────────────
	if templates.size() >= 31:
		print("PASS: template count is %d (expected >= 31)" % templates.size())
		passed += 1
	else:
		printerr("FAIL: template count is %d (expected >= 31)" % templates.size())
		failed += 1

	print("\ntemplate_data_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
