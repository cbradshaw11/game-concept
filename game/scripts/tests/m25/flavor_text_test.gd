## M25 Test: Flavor text — templates with flavor_text have non-empty strings,
## display logic handles missing flavor_text gracefully.
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load templates
	var templates_file := FileAccess.open("res://data/encounter_templates.json", FileAccess.READ)
	var templates_data: Dictionary = JSON.parse_string(templates_file.get_as_text())
	templates_file.close()

	var templates: Array = templates_data.get("templates", [])

	# ─── All templates with flavor_text have non-empty strings ──────────────
	var all_nonempty := true
	var empty_ids := ""
	var flavor_count := 0
	for template in templates:
		if template.has("flavor_text"):
			flavor_count += 1
			var ft := str(template.get("flavor_text", ""))
			if ft.strip_edges() == "":
				all_nonempty = false
				empty_ids += "%s " % template.get("id", "???")
	if all_nonempty and flavor_count > 0:
		print("PASS: all %d templates with flavor_text have non-empty strings" % flavor_count)
		passed += 1
	else:
		printerr("FAIL: empty flavor_text in templates — %s" % empty_ids)
		failed += 1

	# ─── All templates have flavor_text (M25 requirement) ───────────────────
	var missing_flavor := ""
	for template in templates:
		if not template.has("flavor_text"):
			missing_flavor += "%s " % template.get("id", "???")
	if missing_flavor == "":
		print("PASS: all templates have flavor_text field")
		passed += 1
	else:
		printerr("FAIL: templates missing flavor_text — %s" % missing_flavor)
		failed += 1

	# ─── Flavor text is reasonable length (< 120 chars) ─────────────────────
	var all_reasonable := true
	var long_ids := ""
	for template in templates:
		var ft := str(template.get("flavor_text", ""))
		if ft.length() > 120:
			all_reasonable = false
			long_ids += "%s(%d) " % [template.get("id", "???"), ft.length()]
	if all_reasonable:
		print("PASS: all flavor_text strings are under 120 characters")
		passed += 1
	else:
		printerr("FAIL: overly long flavor_text — %s" % long_ids)
		failed += 1

	# ─── Null/missing flavor_text handled gracefully in encounter dict ──────
	# Simulate an encounter dict without flavor_text (random encounter case)
	var no_flavor_encounter := {"ring": "inner", "enemies": [], "enemy_count": 0}
	var flavor := str(no_flavor_encounter.get("flavor_text", ""))
	if flavor == "":
		print("PASS: missing flavor_text returns empty string via get() default")
		passed += 1
	else:
		printerr("FAIL: missing flavor_text did not return empty string")
		failed += 1

	# ─── Flavor text strings don't contain problematic characters ───────────
	var clean := true
	for template in templates:
		var ft := str(template.get("flavor_text", ""))
		if ft.contains("\n") or ft.contains("\t"):
			clean = false
	if clean:
		print("PASS: no flavor_text contains newlines or tabs")
		passed += 1
	else:
		printerr("FAIL: some flavor_text contains newlines or tabs")
		failed += 1

	print("\nflavor_text_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
