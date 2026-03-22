## M16 Test: Verify Berserker and Shield Wall enemy data in enemies.json (M16 T5, T6, T11)
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var enemies_data: Variant = _load_json("res://data/enemies.json")
	if enemies_data == null or typeof(enemies_data) != TYPE_DICTIONARY:
		printerr("FAIL: enemies.json missing or invalid")
		quit(1)
		return

	var enemies: Array = enemies_data.get("enemies", [])
	var by_id: Dictionary = {}
	for e in enemies:
		by_id[str(e.get("id", ""))] = e

	# ── Berserker ───────────────────────────────────────────────────────────
	if not by_id.has("berserker"):
		printerr("FAIL: berserker not found in enemies.json")
		checks_failed += 1
	else:
		var b: Dictionary = by_id["berserker"]
		print("PASS: berserker exists in enemies.json")
		checks_passed += 1

		# HP: 45 (low)
		var hp := int(b.get("health", 0))
		if hp == 45:
			print("PASS: berserker health = 45")
			checks_passed += 1
		else:
			printerr("FAIL: berserker health should be 45, got %d" % hp)
			checks_failed += 1

		# Poise: 8 (low — staggers easily)
		var poise := int(b.get("poise", -1))
		if poise == 8:
			print("PASS: berserker poise = 8")
			checks_passed += 1
		else:
			printerr("FAIL: berserker poise should be 8, got %d" % poise)
			checks_failed += 1

		# Damage: 22 (high)
		var dmg := int(b.get("damage", 0))
		if dmg == 22:
			print("PASS: berserker damage = 22")
			checks_passed += 1
		else:
			printerr("FAIL: berserker damage should be 22, got %d" % dmg)
			checks_failed += 1

		# Available in mid and outer (not inner)
		var rings: Array = b.get("rings", [])
		if "mid" in rings and "outer" in rings:
			print("PASS: berserker available in mid and outer rings")
			checks_passed += 1
		else:
			printerr("FAIL: berserker should be in mid+outer rings, got %s" % str(rings))
			checks_failed += 1

		if not ("inner" in rings):
			print("PASS: berserker NOT in inner ring (correct)")
			checks_passed += 1
		else:
			printerr("FAIL: berserker should not appear in inner ring")
			checks_failed += 1

	# ── Shield Wall ─────────────────────────────────────────────────────────
	if not by_id.has("shield_wall"):
		printerr("FAIL: shield_wall not found in enemies.json")
		checks_failed += 1
	else:
		var sw: Dictionary = by_id["shield_wall"]
		print("PASS: shield_wall exists in enemies.json")
		checks_passed += 1

		# HP: 80 (high)
		var hp := int(sw.get("health", 0))
		if hp == 80:
			print("PASS: shield_wall health = 80")
			checks_passed += 1
		else:
			printerr("FAIL: shield_wall health should be 80, got %d" % hp)
			checks_failed += 1

		# Poise: 40 (high — hard to stagger)
		var poise := int(sw.get("poise", -1))
		if poise >= 35:
			print("PASS: shield_wall poise >= 35 (%d)" % poise)
			checks_passed += 1
		else:
			printerr("FAIL: shield_wall poise should be >= 35, got %d" % poise)
			checks_failed += 1

		# Damage: 8 (low)
		var dmg := int(sw.get("damage", 0))
		if dmg <= 10:
			print("PASS: shield_wall damage <= 10 (%d)" % dmg)
			checks_passed += 1
		else:
			printerr("FAIL: shield_wall damage should be <= 10, got %d" % dmg)
			checks_failed += 1

		# Guard efficiency: ~0.8
		var guard_eff := float(sw.get("guard_efficiency", 0.0))
		if guard_eff >= 0.75:
			print("PASS: shield_wall guard_efficiency >= 0.75 (%.2f)" % guard_eff)
			checks_passed += 1
		else:
			printerr("FAIL: shield_wall guard_efficiency should be >= 0.75, got %.2f" % guard_eff)
			checks_failed += 1

		# Available in mid and outer
		var rings: Array = sw.get("rings", [])
		if "mid" in rings and "outer" in rings:
			print("PASS: shield_wall available in mid and outer rings")
			checks_passed += 1
		else:
			printerr("FAIL: shield_wall should be in mid+outer rings, got %s" % str(rings))
			checks_failed += 1

	# ── Balance: Ring 1 enemies should have lower HP post-M16 tuning ────────
	# scavenger_grunt should be < 60 (was 60, now 52)
	if by_id.has("scavenger_grunt"):
		var grunt_hp := int(by_id["scavenger_grunt"].get("health", 0))
		if grunt_hp < 60:
			print("PASS: scavenger_grunt HP tuned down < 60 (%d)" % grunt_hp)
			checks_passed += 1
		else:
			printerr("FAIL: scavenger_grunt HP should be < 60 for Ring 1 balance, got %d" % grunt_hp)
			checks_failed += 1

	# shieldbearer should be < 85 (was 85)
	if by_id.has("shieldbearer"):
		var sb_hp := int(by_id["shieldbearer"].get("health", 0))
		if sb_hp < 85:
			print("PASS: shieldbearer HP tuned down < 85 (%d)" % sb_hp)
			checks_passed += 1
		else:
			printerr("FAIL: shieldbearer HP should be < 85 for Ring 1 balance, got %d" % sb_hp)
			checks_failed += 1

	# ── Total enemy count should be >= 8 ────────────────────────────────────
	if enemies.size() >= 8:
		print("PASS: enemies.json has %d enemy types (>= 8)" % enemies.size())
		checks_passed += 1
	else:
		printerr("FAIL: enemies.json should have >= 8 enemy types, got %d" % enemies.size())
		checks_failed += 1

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 enemies test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 enemies test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
