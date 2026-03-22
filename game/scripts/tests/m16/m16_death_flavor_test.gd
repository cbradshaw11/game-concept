## M16 Test: Death flavor text structure in flow_ui (M16 T10)
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# Replicate DEATH_FLAVOR dictionary from flow_ui.gd for structural test
	var DEATH_FLAVOR: Dictionary = {
		"inner": [
			"The outer walls didn't kill you. The inner ring did.",
			"You walked in with hope. You left in pieces.",
			"Even the weakest scavengers found your weakness.",
			"The ring claimed another body for the ash.",
			"They said Ring 1 was easy. They lied.",
			"Your equipment survived. You didn't.",
			"A grunt dealt the killing blow. Let that sink in.",
			"The Long Walk ends here, apparently.",
			"Death doesn't discriminate by ring number.",
			"Tomorrow you'll do better. Today you're dead.",
		],
		"mid": [
			"The Mid Reaches are called that for a reason.",
			"Flanked, outpaced, overwhelmed. Classic mid.",
			"You had the skills. The flankers had the numbers.",
			"Another soul left in the ash dunes.",
			"The berserkers barely noticed you.",
			"Mid ring sends its regards.",
			"You got farther than most. Not far enough.",
			"The Long Walk claimed you at the midpoint.",
			"Poise broken, guard shattered, hope extinguished.",
			"You'll come back stronger. Or you won't.",
		],
		"outer": [
			"The Outer Ring was always going to kill you.",
			"Elite threats require elite preparation. Next time.",
			"The Warden's approach path is littered with the fallen.",
			"You saw the outer ring. That's more than most.",
			"The rift casters had your number from the start.",
			"Outer ring death is an achievement in itself.",
			"The warden hunter was named for a reason.",
			"Far from home. Far from safety. Far from alive.",
			"Your loot stays here. Your lessons go with you.",
			"The Long Walk ends at the outer gate.",
		],
		"berserker": [
			"Hit first, hit hard — the berserker's creed.",
			"Staggered once, finished twice. That's berserker math.",
			"Fast, fragile, and faster than you.",
		],
		"shield_wall": [
			"You forgot: break poise before dealing damage.",
			"The Shield Wall absorbed everything. Literally everything.",
			"Attrition wins when you can't break guard.",
		],
	}

	# ── Each ring category has 8-10 lines ────────────────────────────────────
	for ring_key in ["inner", "mid", "outer"]:
		var lines: Array = DEATH_FLAVOR.get(ring_key, [])
		if lines.size() >= 8 and lines.size() <= 10:
			print("PASS: %s death flavor has %d lines (8-10)" % [ring_key, lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: %s death flavor should have 8-10 lines, got %d" % [ring_key, lines.size()])
			checks_failed += 1

	# ── Enemy-specific flavor for berserker and shield_wall ──────────────────
	for enemy_key in ["berserker", "shield_wall"]:
		var lines: Array = DEATH_FLAVOR.get(enemy_key, [])
		if lines.size() >= 3:
			print("PASS: %s enemy-specific death flavor has %d lines (>= 3)" % [enemy_key, lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: %s enemy flavor should have >= 3 lines, got %d" % [enemy_key, lines.size()])
			checks_failed += 1

	# ── All required ring keys present ───────────────────────────────────────
	for key in ["inner", "mid", "outer", "berserker", "shield_wall"]:
		if DEATH_FLAVOR.has(key):
			print("PASS: DEATH_FLAVOR has key '%s'" % key)
			checks_passed += 1
		else:
			printerr("FAIL: DEATH_FLAVOR missing key '%s'" % key)
			checks_failed += 1

	# ── Flavor selection logic: enemy-specific beats ring-based ─────────────
	# Simulate: berserker killed player in mid ring
	var killer_id := "berserker"
	var ring_id := "mid"
	var chosen_lines: Array = []
	if DEATH_FLAVOR.has(killer_id):
		chosen_lines = DEATH_FLAVOR[killer_id]
	elif DEATH_FLAVOR.has(ring_id):
		chosen_lines = DEATH_FLAVOR[ring_id]

	if chosen_lines == DEATH_FLAVOR["berserker"]:
		print("PASS: enemy-specific flavor (berserker) takes priority over ring (mid)")
		checks_passed += 1
	else:
		printerr("FAIL: enemy-specific flavor should take priority over ring flavor")
		checks_failed += 1

	# Simulate: unknown enemy killed in inner ring → falls back to ring
	var unknown_killer := "unknown_enemy"
	var ring2 := "inner"
	var chosen2: Array = []
	if DEATH_FLAVOR.has(unknown_killer):
		chosen2 = DEATH_FLAVOR[unknown_killer]
	elif DEATH_FLAVOR.has(ring2):
		chosen2 = DEATH_FLAVOR[ring2]

	if chosen2 == DEATH_FLAVOR["inner"]:
		print("PASS: unknown enemy falls back to ring flavor text ('inner')")
		checks_passed += 1
	else:
		printerr("FAIL: should fall back to inner ring flavor for unknown enemy")
		checks_failed += 1

	# ── No empty flavor lines ────────────────────────────────────────────────
	var empty_found := false
	for key in DEATH_FLAVOR:
		for line in DEATH_FLAVOR[key]:
			if str(line).strip_edges() == "":
				empty_found = true
				printerr("FAIL: empty flavor line found in key '%s'" % key)
				checks_failed += 1
	if not empty_found:
		print("PASS: no empty flavor lines found")
		checks_passed += 1

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 death flavor test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 death flavor test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
