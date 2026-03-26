## M30 Test: Resonance Wraith data validation — enemies.json entry, encounter templates,
## enemy ids reference valid entries
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── resonance_wraith exists in enemies.json ────────────────────────
	var enemies_file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	var enemies_data: Dictionary = JSON.parse_string(enemies_file.get_as_text())
	enemies_file.close()

	var wraith_data: Dictionary = {}
	var all_enemy_ids: Array[String] = []
	for enemy in enemies_data.get("enemies", []):
		var eid := str(enemy.get("id", ""))
		all_enemy_ids.append(eid)
		if eid == "resonance_wraith":
			wraith_data = enemy

	if not wraith_data.is_empty():
		print("PASS: resonance_wraith found in enemies.json")
		passed += 1
	else:
		printerr("FAIL: resonance_wraith not found in enemies.json")
		failed += 1

	# ─── Wraith has correct ring assignment ─────────────────────────────
	var rings: Array = wraith_data.get("rings", [])
	if "outer" in rings:
		print("PASS: resonance_wraith assigned to outer ring")
		passed += 1
	else:
		printerr("FAIL: resonance_wraith rings=%s, expected outer" % str(rings))
		failed += 1

	# ─── Wraith has phase_phantom profile ───────────────────────────────
	if str(wraith_data.get("behavior_profile", "")) == "phase_phantom":
		print("PASS: resonance_wraith uses phase_phantom behavior profile")
		passed += 1
	else:
		printerr("FAIL: resonance_wraith profile=%s, expected phase_phantom" % wraith_data.get("behavior_profile", ""))
		failed += 1

	# ─── Wraith has phase_duration and vulnerable_duration fields ───────
	var has_phase := wraith_data.has("phase_duration") and wraith_data.has("vulnerable_duration")
	if has_phase:
		print("PASS: resonance_wraith has phase_duration=%.1f and vulnerable_duration=%.1f" % [wraith_data["phase_duration"], wraith_data["vulnerable_duration"]])
		passed += 1
	else:
		printerr("FAIL: resonance_wraith missing phase_duration or vulnerable_duration")
		failed += 1

	# ─── Wraith stats are correct ──────────────────────────────────────
	if int(wraith_data.get("health", 0)) == 95 and int(wraith_data.get("damage", 0)) == 18:
		print("PASS: resonance_wraith stats correct (health=95, damage=18)")
		passed += 1
	else:
		printerr("FAIL: resonance_wraith stats — health=%s damage=%s" % [wraith_data.get("health", "?"), wraith_data.get("damage", "?")])
		failed += 1

	# ─── New encounter templates exist ──────────────────────────────────
	var templates_file := FileAccess.open("res://data/encounter_templates.json", FileAccess.READ)
	var templates_data: Dictionary = JSON.parse_string(templates_file.get_as_text())
	templates_file.close()

	var phantom_screen: Dictionary = {}
	var twin_phantoms: Dictionary = {}
	for template in templates_data.get("templates", []):
		var tid := str(template.get("id", ""))
		if tid == "outer_phantom_screen":
			phantom_screen = template
		elif tid == "outer_twin_phantoms":
			twin_phantoms = template

	if not phantom_screen.is_empty():
		print("PASS: outer_phantom_screen template found")
		passed += 1
	else:
		printerr("FAIL: outer_phantom_screen template not found in encounter_templates.json")
		failed += 1

	if not twin_phantoms.is_empty():
		print("PASS: outer_twin_phantoms template found")
		passed += 1
	else:
		printerr("FAIL: outer_twin_phantoms template not found in encounter_templates.json")
		failed += 1

	# ─── Template enemy_ids reference valid enemies ─────────────────────
	var phantom_screen_valid := true
	for eid in phantom_screen.get("enemy_ids", []):
		if str(eid) not in all_enemy_ids:
			phantom_screen_valid = false
			break
	if phantom_screen_valid and not phantom_screen.is_empty():
		print("PASS: outer_phantom_screen enemy_ids all reference valid enemies")
		passed += 1
	else:
		printerr("FAIL: outer_phantom_screen has invalid enemy_ids — %s" % str(phantom_screen.get("enemy_ids", [])))
		failed += 1

	var twin_phantoms_valid := true
	for eid in twin_phantoms.get("enemy_ids", []):
		if str(eid) not in all_enemy_ids:
			twin_phantoms_valid = false
			break
	if twin_phantoms_valid and not twin_phantoms.is_empty():
		print("PASS: outer_twin_phantoms enemy_ids all reference valid enemies")
		passed += 1
	else:
		printerr("FAIL: outer_twin_phantoms has invalid enemy_ids — %s" % str(twin_phantoms.get("enemy_ids", [])))
		failed += 1

	# ─── Both templates are outer ring ──────────────────────────────────
	var both_outer := str(phantom_screen.get("ring", "")) == "outer" and str(twin_phantoms.get("ring", "")) == "outer"
	if both_outer:
		print("PASS: both new templates assigned to outer ring")
		passed += 1
	else:
		printerr("FAIL: template ring assignments — phantom_screen=%s twin_phantoms=%s" % [phantom_screen.get("ring", "?"), twin_phantoms.get("ring", "?")])
		failed += 1

	# ─── Templates contain resonance_wraith ─────────────────────────────
	var ps_has_wraith: bool = "resonance_wraith" in phantom_screen.get("enemy_ids", [])
	var tp_has_wraith: bool = "resonance_wraith" in twin_phantoms.get("enemy_ids", [])
	if ps_has_wraith and tp_has_wraith:
		print("PASS: both templates include resonance_wraith")
		passed += 1
	else:
		printerr("FAIL: templates missing resonance_wraith — phantom_screen=%s twin_phantoms=%s" % [ps_has_wraith, tp_has_wraith])
		failed += 1

	# ─── Summary ────────────────────────────────────────────────────────
	print("")
	print("wraith_encounter_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
