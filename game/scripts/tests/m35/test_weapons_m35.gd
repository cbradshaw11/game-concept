## M35 Test: Verify new weapons (Twin Fangs, War Hammer, Resonance Staff)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Load weapons.json ────────────────────────────────────────────────────
	var weapons_data: Variant = _load_json("res://data/weapons.json")
	if weapons_data == null or typeof(weapons_data) != TYPE_DICTIONARY:
		printerr("FAIL: weapons.json missing or invalid")
		quit(1)
		return

	var weapons: Array = weapons_data.get("weapons", [])
	var by_id: Dictionary = {}
	for w in weapons:
		by_id[str(w.get("id", ""))] = w

	# ── Twin Fangs ───────────────────────────────────────────────────────────
	if not by_id.has("twin_fangs"):
		printerr("FAIL: twin_fangs not found in weapons.json")
		checks_failed += 1
	else:
		var tf: Dictionary = by_id["twin_fangs"]
		print("PASS: twin_fangs exists in weapons.json")
		checks_passed += 1

		if str(tf.get("family", "")) == "dagger":
			print("PASS: twin_fangs family = 'dagger'")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs family should be 'dagger', got '%s'" % tf.get("family", ""))
			checks_failed += 1

		if int(tf.get("light_damage", 0)) == 8:
			print("PASS: twin_fangs light_damage = 8")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs light_damage should be 8, got %d" % int(tf.get("light_damage", 0)))
			checks_failed += 1

		if int(tf.get("poise_damage_heavy", 0)) == 15:
			print("PASS: twin_fangs poise_damage_heavy = 15")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs poise_damage_heavy should be 15, got %d" % int(tf.get("poise_damage_heavy", 0)))
			checks_failed += 1

		var cooldown := float(tf.get("attack_cooldown", 0.0))
		if is_equal_approx(cooldown, 0.6):
			print("PASS: twin_fangs attack_cooldown = 0.6")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs attack_cooldown should be 0.6, got %.2f" % cooldown)
			checks_failed += 1

		var gp := float(tf.get("guard_penetration", -1.0))
		if is_equal_approx(gp, 0.0):
			print("PASS: twin_fangs guard_penetration = 0.0")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs guard_penetration should be 0.0, got %.2f" % gp)
			checks_failed += 1

	# ── War Hammer ───────────────────────────────────────────────────────────
	if not by_id.has("war_hammer"):
		printerr("FAIL: war_hammer not found in weapons.json")
		checks_failed += 1
	else:
		var wh: Dictionary = by_id["war_hammer"]
		print("PASS: war_hammer exists in weapons.json")
		checks_passed += 1

		if str(wh.get("family", "")) == "hammer":
			print("PASS: war_hammer family = 'hammer'")
			checks_passed += 1
		else:
			printerr("FAIL: war_hammer family should be 'hammer', got '%s'" % wh.get("family", ""))
			checks_failed += 1

		if int(wh.get("light_damage", 0)) == 28:
			print("PASS: war_hammer light_damage = 28")
			checks_passed += 1
		else:
			printerr("FAIL: war_hammer light_damage should be 28, got %d" % int(wh.get("light_damage", 0)))
			checks_failed += 1

		if int(wh.get("poise_damage_heavy", 0)) == 40:
			print("PASS: war_hammer poise_damage_heavy = 40")
			checks_passed += 1
		else:
			printerr("FAIL: war_hammer poise_damage_heavy should be 40, got %d" % int(wh.get("poise_damage_heavy", 0)))
			checks_failed += 1

		var cooldown := float(wh.get("attack_cooldown", 0.0))
		if is_equal_approx(cooldown, 1.8):
			print("PASS: war_hammer attack_cooldown = 1.8")
			checks_passed += 1
		else:
			printerr("FAIL: war_hammer attack_cooldown should be 1.8, got %.2f" % cooldown)
			checks_failed += 1

	# ── Resonance Staff ──────────────────────────────────────────────────────
	if not by_id.has("resonance_staff"):
		printerr("FAIL: resonance_staff not found in weapons.json")
		checks_failed += 1
	else:
		var rs: Dictionary = by_id["resonance_staff"]
		print("PASS: resonance_staff exists in weapons.json")
		checks_passed += 1

		if str(rs.get("family", "")) == "staff":
			print("PASS: resonance_staff family = 'staff'")
			checks_passed += 1
		else:
			printerr("FAIL: resonance_staff family should be 'staff', got '%s'" % rs.get("family", ""))
			checks_failed += 1

		if int(rs.get("light_damage", 0)) == 15:
			print("PASS: resonance_staff light_damage = 15")
			checks_passed += 1
		else:
			printerr("FAIL: resonance_staff light_damage should be 15, got %d" % int(rs.get("light_damage", 0)))
			checks_failed += 1

		var cooldown := float(rs.get("attack_cooldown", 0.0))
		if is_equal_approx(cooldown, 1.1):
			print("PASS: resonance_staff attack_cooldown = 1.1")
			checks_passed += 1
		else:
			printerr("FAIL: resonance_staff attack_cooldown should be 1.1, got %.2f" % cooldown)
			checks_failed += 1

		var gp := float(rs.get("guard_penetration", 0.0))
		if is_equal_approx(gp, 0.3):
			print("PASS: resonance_staff guard_penetration = 0.3")
			checks_passed += 1
		else:
			printerr("FAIL: resonance_staff guard_penetration should be 0.3, got %.2f" % gp)
			checks_failed += 1

	# ── All weapons have guard_penetration field ─────────────────────────────
	var all_have_gp := true
	for w in weapons:
		if not w.has("guard_penetration"):
			all_have_gp = false
			printerr("FAIL: weapon '%s' missing guard_penetration field" % w.get("id", "?"))
			checks_failed += 1
	if all_have_gp:
		print("PASS: all weapons have guard_penetration field")
		checks_passed += 1

	# ── Shop items ───────────────────────────────────────────────────────────
	var shop_data: Variant = _load_json("res://data/shop_items.json")
	if shop_data == null or typeof(shop_data) != TYPE_DICTIONARY:
		printerr("FAIL: shop_items.json missing or invalid")
		checks_failed += 1
	else:
		var items: Array = shop_data.get("shop_items", [])
		var shop_by_id: Dictionary = {}
		for item in items:
			shop_by_id[str(item.get("id", ""))] = item

		# Twin Fangs: 80 silver
		if shop_by_id.has("twin_fangs") and int(shop_by_id["twin_fangs"].get("cost", 0)) == 80:
			print("PASS: twin_fangs in shop_items at 80 silver")
			checks_passed += 1
		else:
			printerr("FAIL: twin_fangs should be in shop_items.json at cost 80")
			checks_failed += 1

		# War Hammer: 90 silver
		if shop_by_id.has("war_hammer") and int(shop_by_id["war_hammer"].get("cost", 0)) == 90:
			print("PASS: war_hammer in shop_items at 90 silver")
			checks_passed += 1
		else:
			printerr("FAIL: war_hammer should be in shop_items.json at cost 90")
			checks_failed += 1

		# Resonance Staff: 100 silver
		if shop_by_id.has("resonance_staff") and int(shop_by_id["resonance_staff"].get("cost", 0)) == 100:
			print("PASS: resonance_staff in shop_items at 100 silver")
			checks_passed += 1
		else:
			printerr("FAIL: resonance_staff should be in shop_items.json at cost 100")
			checks_failed += 1

	# ── Narrative flavor text ────────────────────────────────────────────────
	var narrative_data: Variant = _load_json("res://data/narrative.json")
	if narrative_data == null or typeof(narrative_data) != TYPE_DICTIONARY:
		printerr("FAIL: narrative.json missing or invalid")
		checks_failed += 1
	else:
		var weapon_flavor: Dictionary = narrative_data.get("weapons", {})
		for wid in ["twin_fangs", "war_hammer", "resonance_staff"]:
			if weapon_flavor.has(wid) and str(weapon_flavor[wid]) != "":
				print("PASS: narrative.json has flavor text for %s" % wid)
				checks_passed += 1
			else:
				printerr("FAIL: narrative.json missing flavor text for %s" % wid)
				checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	print("")
	print("M35 weapon tests: %d passed, %d failed" % [checks_passed, checks_failed])
	quit(1 if checks_failed > 0 else 0)
