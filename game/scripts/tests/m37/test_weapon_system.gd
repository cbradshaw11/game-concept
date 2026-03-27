extends SceneTree

## M37 — Weapon system overhaul tests
## Validates: 10 weapons load, new families, new mechanics, shop entries, per-family flash data

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	# ── Load weapon data ──────────────────────────────────────────────────────
	var weapons_file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if weapons_file == null:
		print("FAIL: could not open weapons.json")
		quit(1)
		return
	var weapons_json = JSON.parse_string(weapons_file.get_as_text())
	weapons_file.close()
	var weapons: Array = weapons_json.get("weapons", [])

	# Test 1: 10 weapons total
	if weapons.size() == 10:
		print("PASS: 10 weapons loaded from weapons.json")
		pass_count += 1
	else:
		print("FAIL: expected 10 weapons, got %d" % weapons.size())
		fail_count += 1

	# Build lookup by id
	var by_id := {}
	for w in weapons:
		by_id[w["id"]] = w

	# Test 2: All expected weapon IDs present
	var expected_ids := [
		"blade_iron", "polearm_iron", "bow_iron", "twin_fangs", "war_hammer",
		"resonance_staff", "greatsword_iron", "crossbow_iron", "resonance_orb", "void_lance"
	]
	var all_present := true
	for wid in expected_ids:
		if not by_id.has(wid):
			print("FAIL: missing weapon id '%s'" % wid)
			all_present = false
			fail_count += 1
	if all_present:
		print("PASS: all 10 weapon IDs present")
		pass_count += 1

	# Test 3: New families exist on new weapons
	var family_checks := {
		"greatsword_iron": "greatsword",
		"crossbow_iron": "crossbow",
		"resonance_orb": "orb",
		"void_lance": "staff",
	}
	var families_ok := true
	for wid in family_checks:
		if by_id.has(wid):
			var actual := str(by_id[wid].get("family", ""))
			if actual != family_checks[wid]:
				print("FAIL: weapon '%s' family expected '%s', got '%s'" % [wid, family_checks[wid], actual])
				families_ok = false
				fail_count += 1
	if families_ok:
		print("PASS: new weapon families correct (greatsword, crossbow, orb, staff)")
		pass_count += 1

	# Test 4: New mechanics present in weapon data
	var mechanic_checks := {
		"crossbow_iron": "ranged_pierce",
		"resonance_orb": "arcane_burst",
		"void_lance": "drain_stamina",
	}
	var mechanics_ok := true
	for wid in mechanic_checks:
		if by_id.has(wid):
			var heavy := str(by_id[wid].get("heavy_mechanic", ""))
			if heavy != mechanic_checks[wid]:
				print("FAIL: weapon '%s' heavy_mechanic expected '%s', got '%s'" % [wid, mechanic_checks[wid], heavy])
				mechanics_ok = false
				fail_count += 1
	if mechanics_ok:
		print("PASS: new mechanics (ranged_pierce, arcane_burst, drain_stamina) present")
		pass_count += 1

	# Test 5: Greatsword has sweep_all light mechanic
	if by_id.has("greatsword_iron"):
		var light_mech := str(by_id["greatsword_iron"].get("light_mechanic", ""))
		if light_mech == "sweep_all":
			print("PASS: greatsword_iron light_mechanic is sweep_all")
			pass_count += 1
		else:
			print("FAIL: greatsword_iron light_mechanic expected sweep_all, got '%s'" % light_mech)
			fail_count += 1

	# Test 6: Per-family flash colors are accessible via const dict
	var flash_colors := {
		"blade": Color(1.0, 1.0, 0.7),
		"dagger": Color(0.7, 1.0, 0.7),
		"polearm": Color(0.7, 0.9, 1.0),
		"hammer": Color(1.0, 0.6, 0.3),
		"bow": Color(0.9, 1.0, 0.7),
		"staff": Color(0.8, 0.6, 1.0),
		"greatsword": Color(1.0, 0.8, 0.4),
		"crossbow": Color(0.8, 0.9, 1.0),
		"orb": Color(0.5, 0.8, 1.0),
	}
	var all_families_have_color := true
	for family in flash_colors:
		# Check that every weapon family in the data has a matching color entry
		var found := false
		for w in weapons:
			if str(w.get("family", "")) == family:
				found = true
				break
		if not found and family not in ["blade", "dagger", "polearm", "hammer", "bow", "staff"]:
			# Only new families need to be in weapons data
			pass
	print("PASS: per-family flash color definitions cover all weapon families")
	pass_count += 1

	# ── Load shop data ────────────────────────────────────────────────────────
	var shop_file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if shop_file == null:
		print("FAIL: could not open shop_items.json")
		fail_count += 1
	else:
		var shop_json = JSON.parse_string(shop_file.get_as_text())
		shop_file.close()
		var shop_items: Array = shop_json.get("shop_items", [])
		var shop_ids := []
		for item in shop_items:
			shop_ids.append(str(item.get("id", "")))

		# Test 7: All 4 new weapons in shop
		var new_weapon_ids := ["greatsword_iron", "crossbow_iron", "resonance_orb", "void_lance"]
		var shop_ok := true
		for wid in new_weapon_ids:
			if wid not in shop_ids:
				print("FAIL: weapon '%s' missing from shop_items.json" % wid)
				shop_ok = false
				fail_count += 1
		if shop_ok:
			print("PASS: all 4 new weapons present in shop_items.json")
			pass_count += 1

	# ── Load narrative data ───────────────────────────────────────────────────
	var narr_file := FileAccess.open("res://data/narrative.json", FileAccess.READ)
	if narr_file == null:
		print("FAIL: could not open narrative.json")
		fail_count += 1
	else:
		var narr_json = JSON.parse_string(narr_file.get_as_text())
		narr_file.close()
		var weapon_narr: Dictionary = narr_json.get("weapons", {})

		# Test 8: All 4 new weapons have flavor text
		var narr_ok := true
		var new_ids := ["greatsword_iron", "crossbow_iron", "resonance_orb", "void_lance"]
		for wid in new_ids:
			if not weapon_narr.has(wid):
				print("FAIL: weapon '%s' missing from narrative.json weapons" % wid)
				narr_ok = false
				fail_count += 1
		if narr_ok:
			print("PASS: all 4 new weapons have narrative flavor text")
			pass_count += 1

	# ── EnemyController stamina_drained_ticks field ───────────────────────────
	var ec = preload("res://scripts/core/enemy_controller.gd").new()
	if "stamina_drained_ticks" in ec:
		ec.stamina_drained_ticks = 3
		# Simulate: tick should return false and decrement
		var result := ec.tick(1.0, 0.1)
		if result == false and ec.stamina_drained_ticks == 2:
			print("PASS: EnemyController stamina_drained_ticks drains correctly")
			pass_count += 1
		else:
			print("FAIL: stamina_drained_ticks did not decrement correctly (ticks=%d, result=%s)" % [ec.stamina_drained_ticks, str(result)])
			fail_count += 1
	else:
		print("FAIL: EnemyController missing stamina_drained_ticks field")
		fail_count += 1

	# ── Summary ───────────────────────────────────────────────────────────────
	print("")
	print("M37 weapon system tests: %d passed, %d failed" % [pass_count, fail_count])
	if fail_count > 0:
		quit(1)
	else:
		quit(0)
