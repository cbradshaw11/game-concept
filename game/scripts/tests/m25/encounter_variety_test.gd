## M25 Test: Encounter variety — ring template counts, weighted selection behavior.
extends SceneTree

const RingDirector = preload("res://scripts/systems/ring_director.gd")

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

	# ─── Each ring has at least 6 templates ─────────────────────────────────
	var ring_counts: Dictionary = {"inner": 0, "mid": 0, "outer": 0}
	for template in templates:
		var ring := str(template.get("ring", ""))
		if ring_counts.has(ring):
			ring_counts[ring] = int(ring_counts[ring]) + 1

	for ring_id in ["inner", "mid", "outer"]:
		var count: int = ring_counts[ring_id]
		if count >= 6:
			print("PASS: %s ring has %d templates (>= 6)" % [ring_id, count])
			passed += 1
		else:
			printerr("FAIL: %s ring has %d templates (expected >= 6)" % [ring_id, count])
			failed += 1

	# ─── RingDirector generates template encounters for all rings ───────────
	var rd := RingDirector.new()
	for ring_id in ["inner", "mid", "outer"]:
		var encounter := rd.generate_encounter(42, ring_id, enemies_data, templates_data)
		if encounter.has("template_id") and str(encounter["template_id"]) != "":
			print("PASS: %s ring encounter uses template '%s'" % [ring_id, encounter["template_id"]])
			passed += 1
		else:
			printerr("FAIL: %s ring encounter did not select a template" % ring_id)
			failed += 1

	# ─── Weighted selection produces variety over many seeds ────────────────
	# Run 100 encounters for inner ring and verify we get more than 1 unique template
	var seen_templates: Dictionary = {}
	for i in range(100):
		var encounter := rd.generate_encounter(i * 7 + 1, "inner", enemies_data, templates_data)
		var tid := str(encounter.get("template_id", ""))
		if tid != "":
			seen_templates[tid] = true
	if seen_templates.size() >= 3:
		print("PASS: 100 inner encounters produced %d distinct templates (>= 3)" % seen_templates.size())
		passed += 1
	else:
		printerr("FAIL: 100 inner encounters produced only %d distinct templates" % seen_templates.size())
		failed += 1

	# ─── Template encounters include enemy data ─────────────────────────────
	var enc := rd.generate_encounter(99, "mid", enemies_data, templates_data)
	var enemies: Array = enc.get("enemies", [])
	if enemies.size() > 0 and enemies[0].has("id"):
		print("PASS: template encounter enemies contain full enemy data (id field present)")
		passed += 1
	else:
		printerr("FAIL: template encounter enemies missing full data")
		failed += 1

	# ─── Template encounters pass through template_name ─────────────────────
	if enc.has("template_name") and str(enc["template_name"]) != "":
		print("PASS: encounter includes template_name '%s'" % enc["template_name"])
		passed += 1
	else:
		printerr("FAIL: encounter missing template_name")
		failed += 1

	# ─── Flavor text passed through for templates that have it ──────────────
	var has_flavor := false
	for i in range(50):
		var test_enc := rd.generate_encounter(i * 13, "outer", enemies_data, templates_data)
		if test_enc.has("flavor_text") and str(test_enc["flavor_text"]) != "":
			has_flavor = true
			break
	if has_flavor:
		print("PASS: template encounters include flavor_text when present")
		passed += 1
	else:
		printerr("FAIL: no flavor_text found in any outer ring encounter")
		failed += 1

	print("\nencounter_variety_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
