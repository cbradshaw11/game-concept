## M16 Test: Verify modifier pool (6 modifiers, 3 choices per run) (M16 T8)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var mods_data: Variant = _load_json("res://data/modifiers.json")
	if mods_data == null or typeof(mods_data) != TYPE_DICTIONARY:
		printerr("FAIL: modifiers.json missing or invalid")
		quit(1)
		return

	var modifiers: Array = mods_data.get("modifiers", [])

	# ── Modifier count: exactly 6 ────────────────────────────────────────────
	if modifiers.size() == 6:
		print("PASS: modifiers.json has exactly 6 modifiers")
		checks_passed += 1
	else:
		printerr("FAIL: modifiers.json should have 6 modifiers, got %d" % modifiers.size())
		checks_failed += 1

	# ── choices_per_run: 3 ───────────────────────────────────────────────────
	var choices_per_run := int(mods_data.get("choices_per_run", 0))
	if choices_per_run == 3:
		print("PASS: choices_per_run = 3")
		checks_passed += 1
	else:
		printerr("FAIL: choices_per_run should be 3, got %d" % choices_per_run)
		checks_failed += 1

	# ── Required modifier IDs present ───────────────────────────────────────
	var by_id: Dictionary = {}
	for mod in modifiers:
		by_id[str(mod.get("id", ""))] = mod

	var required_ids := ["swift", "death_wish", "iron_skin", "relentless", "berserker", "ghost_step"]
	for req_id in required_ids:
		if by_id.has(req_id):
			print("PASS: modifier '%s' exists" % req_id)
			checks_passed += 1
		else:
			printerr("FAIL: modifier '%s' not found" % req_id)
			checks_failed += 1

	# ── Each modifier has required fields ────────────────────────────────────
	for mod in modifiers:
		var mod_id := str(mod.get("id", ""))
		if mod_id == "":
			printerr("FAIL: modifier missing 'id' field")
			checks_failed += 1
			continue
		if not mod.has("name"):
			printerr("FAIL: modifier '%s' missing 'name'" % mod_id)
			checks_failed += 1
		elif not mod.has("description"):
			printerr("FAIL: modifier '%s' missing 'description'" % mod_id)
			checks_failed += 1
		elif not mod.has("effect"):
			printerr("FAIL: modifier '%s' missing 'effect'" % mod_id)
			checks_failed += 1
		elif not mod.has("value"):
			printerr("FAIL: modifier '%s' missing 'value'" % mod_id)
			checks_failed += 1
		else:
			checks_passed += 1

	# ── Spot-check specific modifiers ────────────────────────────────────────
	# swift: -20% light stamina cost
	if by_id.has("swift"):
		var swift: Dictionary = by_id["swift"]
		if str(swift.get("effect", "")) == "light_stamina_cost_pct":
			print("PASS: swift effect = 'light_stamina_cost_pct'")
			checks_passed += 1
		else:
			printerr("FAIL: swift effect should be 'light_stamina_cost_pct'")
			checks_failed += 1
		if float(swift.get("value", 0.0)) < 0.0:
			print("PASS: swift value is negative (cost reduction)")
			checks_passed += 1
		else:
			printerr("FAIL: swift value should be negative (cost reduction)")
			checks_failed += 1

	# iron_skin: +15 max HP
	if by_id.has("iron_skin"):
		var iron: Dictionary = by_id["iron_skin"]
		if int(iron.get("value", 0)) == 15:
			print("PASS: iron_skin value = 15")
			checks_passed += 1
		else:
			printerr("FAIL: iron_skin value should be 15, got %d" % int(iron.get("value", 0)))
			checks_failed += 1

	# ghost_step: +50ms i-frames
	if by_id.has("ghost_step"):
		var ghost_step_mod: Dictionary = by_id["ghost_step"]
		if int(ghost_step_mod.get("value", 0)) == 50:
			print("PASS: ghost_step value = 50ms")
			checks_passed += 1
		else:
			printerr("FAIL: ghost_step value should be 50, got %d" % int(ghost_step_mod.get("value", 0)))
			checks_failed += 1

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 modifiers test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 modifiers test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
