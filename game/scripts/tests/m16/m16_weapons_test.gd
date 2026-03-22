## M16 Test: Verify polearm and bow weapon stats in weapons.json (M16 T1, T2)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var weapons_data: Variant = _load_json("res://data/weapons.json")
	if weapons_data == null or typeof(weapons_data) != TYPE_DICTIONARY:
		printerr("FAIL: weapons.json missing or invalid")
		quit(1)
		return

	var weapons: Array = weapons_data.get("weapons", [])
	var by_id: Dictionary = {}
	for w in weapons:
		by_id[str(w.get("id", ""))] = w

	# ── Polearm checks ──────────────────────────────────────────────────────
	if not by_id.has("polearm_iron"):
		printerr("FAIL: polearm_iron not found in weapons.json")
		checks_failed += 1
	else:
		var p: Dictionary = by_id["polearm_iron"]
		print("PASS: polearm_iron exists in weapons.json")
		checks_passed += 1

		# family
		if str(p.get("family", "")) == "polearm":
			print("PASS: polearm family = 'polearm'")
			checks_passed += 1
		else:
			printerr("FAIL: polearm family should be 'polearm', got '%s'" % p.get("family", ""))
			checks_failed += 1

		# light attack: 12 dmg per spec
		var light_dmg := int(p.get("light_damage", 0))
		if light_dmg == 12:
			print("PASS: polearm light_damage = 12")
			checks_passed += 1
		else:
			printerr("FAIL: polearm light_damage should be 12, got %d" % light_dmg)
			checks_failed += 1

		# heavy attack: 28 dmg per spec
		var heavy_dmg := int(p.get("heavy_damage", 0))
		if heavy_dmg == 28:
			print("PASS: polearm heavy_damage = 28")
			checks_passed += 1
		else:
			printerr("FAIL: polearm heavy_damage should be 28, got %d" % heavy_dmg)
			checks_failed += 1

		# guard efficiency: 0.5 per spec (worse than blade at 0.7)
		var guard := float(p.get("guard_efficiency", 0.0))
		if guard <= 0.6:
			print("PASS: polearm guard_efficiency <= 0.6 (%.2f)" % guard)
			checks_passed += 1
		else:
			printerr("FAIL: polearm guard_efficiency should be <= 0.6, got %.2f" % guard)
			checks_failed += 1

		# sweep mechanic on light
		var light_mech := str(p.get("light_mechanic", ""))
		if light_mech == "sweep_all":
			print("PASS: polearm light_mechanic = 'sweep_all'")
			checks_passed += 1
		else:
			printerr("FAIL: polearm light_mechanic should be 'sweep_all', got '%s'" % light_mech)
			checks_failed += 1

		# sweep ratio ~0.6
		var sweep_ratio := float(p.get("light_sweep_ratio", 0.0))
		if absf(sweep_ratio - 0.6) < 0.01:
			print("PASS: polearm light_sweep_ratio = 0.6")
			checks_passed += 1
		else:
			printerr("FAIL: polearm light_sweep_ratio should be 0.6, got %.2f" % sweep_ratio)
			checks_failed += 1

		# heavy mechanic: lunge_poise
		var heavy_mech := str(p.get("heavy_mechanic", ""))
		if heavy_mech == "lunge_poise":
			print("PASS: polearm heavy_mechanic = 'lunge_poise'")
			checks_passed += 1
		else:
			printerr("FAIL: polearm heavy_mechanic should be 'lunge_poise', got '%s'" % heavy_mech)
			checks_failed += 1

		# unlock cost: 150
		var unlock_cost := int(p.get("unlock_cost", -1))
		if unlock_cost == 150:
			print("PASS: polearm unlock_cost = 150")
			checks_passed += 1
		else:
			printerr("FAIL: polearm unlock_cost should be 150, got %d" % unlock_cost)
			checks_failed += 1

	# ── Bow checks ──────────────────────────────────────────────────────────
	if not by_id.has("bow_iron"):
		printerr("FAIL: bow_iron not found in weapons.json")
		checks_failed += 1
	else:
		var b: Dictionary = by_id["bow_iron"]
		print("PASS: bow_iron exists in weapons.json")
		checks_passed += 1

		# family
		if str(b.get("family", "")) == "bow":
			print("PASS: bow family = 'bow'")
			checks_passed += 1
		else:
			printerr("FAIL: bow family should be 'bow', got '%s'" % b.get("family", ""))
			checks_failed += 1

		# light: 18 dmg
		var light_dmg := int(b.get("light_damage", 0))
		if light_dmg == 18:
			print("PASS: bow light_damage = 18")
			checks_passed += 1
		else:
			printerr("FAIL: bow light_damage should be 18, got %d" % light_dmg)
			checks_failed += 1

		# heavy: 32 dmg
		var heavy_dmg := int(b.get("heavy_damage", 0))
		if heavy_dmg == 32:
			print("PASS: bow heavy_damage = 32")
			checks_passed += 1
		else:
			printerr("FAIL: bow heavy_damage should be 32, got %d" % heavy_dmg)
			checks_failed += 1

		# guard: 0.3 (worst guard)
		var guard := float(b.get("guard_efficiency", 0.0))
		if guard <= 0.35:
			print("PASS: bow guard_efficiency <= 0.35 (%.2f)" % guard)
			checks_passed += 1
		else:
			printerr("FAIL: bow guard_efficiency should be <= 0.35, got %.2f" % guard)
			checks_failed += 1

		# heavy mechanic: charged_suppress
		var heavy_mech := str(b.get("heavy_mechanic", ""))
		if heavy_mech == "charged_suppress":
			print("PASS: bow heavy_mechanic = 'charged_suppress'")
			checks_passed += 1
		else:
			printerr("FAIL: bow heavy_mechanic should be 'charged_suppress', got '%s'" % heavy_mech)
			checks_failed += 1

		# heavy_suppress_ticks: 1
		var suppress_ticks := int(b.get("heavy_suppress_ticks", 0))
		if suppress_ticks == 1:
			print("PASS: bow heavy_suppress_ticks = 1")
			checks_passed += 1
		else:
			printerr("FAIL: bow heavy_suppress_ticks should be 1, got %d" % suppress_ticks)
			checks_failed += 1

		# unlock cost: 200
		var unlock_cost := int(b.get("unlock_cost", -1))
		if unlock_cost == 200:
			print("PASS: bow unlock_cost = 200")
			checks_passed += 1
		else:
			printerr("FAIL: bow unlock_cost should be 200, got %d" % unlock_cost)
			checks_failed += 1

	# ── Iron Blade still exists ─────────────────────────────────────────────
	if by_id.has("blade_iron"):
		print("PASS: blade_iron still present")
		checks_passed += 1
	else:
		printerr("FAIL: blade_iron missing from weapons.json")
		checks_failed += 1

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 weapons test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 weapons test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
