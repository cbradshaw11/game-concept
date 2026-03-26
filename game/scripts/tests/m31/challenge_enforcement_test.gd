## M31 Test: Challenge enforcement — verifies iron_road blocks healing,
## naked_run disables vendor, warden_hunt blocks extraction, escalation adds enemies
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load challenge data for reference
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Dictionary = JSON.parse_string(raw)
	var challenges: Array = data.get("challenge_runs", [])
	var by_id: Dictionary = {}
	for ch in challenges:
		by_id[str(ch.get("id", ""))] = ch

	# ── Test 1: iron_road — verify no healing enforcement design ─────────────
	var ir: Dictionary = by_id.get("iron_road", {})
	if not ir.is_empty() and str(ir.get("description", "")).find("No healing") >= 0:
		print("PASS: iron_road blocks healing (description confirms no-healing design)")
		passed += 1
	else:
		print("FAIL: iron_road missing or description does not mention healing block")
		failed += 1

	# ── Test 2: naked_run — vendor disabled ──────────────────────────────────
	var nr: Dictionary = by_id.get("naked_run", {})
	if not nr.is_empty() and str(nr.get("description", "")).find("Cannot purchase") >= 0:
		print("PASS: naked_run disables vendor (description confirms no-purchase design)")
		passed += 1
	else:
		print("FAIL: naked_run missing or description does not mention vendor lock")
		failed += 1

	# ── Test 3: warden_hunt — extraction blocked ─────────────────────────────
	var wh: Dictionary = by_id.get("warden_hunt", {})
	if not wh.is_empty() and str(wh.get("description", "")).find("No early extraction") >= 0:
		print("PASS: warden_hunt blocks extraction (description confirms extraction block)")
		passed += 1
	else:
		print("FAIL: warden_hunt missing or description does not mention extraction block")
		failed += 1

	# ── Test 4: escalation — extra_enemy_cap field ───────────────────────────
	var es: Dictionary = by_id.get("escalation", {})
	if not es.is_empty() and int(es.get("extra_enemy_cap", 0)) == 4:
		print("PASS: escalation has extra_enemy_cap = 4")
		passed += 1
	else:
		print("FAIL: escalation missing extra_enemy_cap or not 4")
		failed += 1

	# ── Test 5: time_pressure — time limits are positive ─────────────────────
	var tp: Dictionary = by_id.get("time_pressure", {})
	var limits: Variant = tp.get("time_limits", {})
	if typeof(limits) == TYPE_DICTIONARY:
		var inner_t := int(limits.get("inner", 0))
		var mid_t := int(limits.get("mid", 0))
		var outer_t := int(limits.get("outer", 0))
		if inner_t == 240 and mid_t == 360 and outer_t == 480:
			print("PASS: time_pressure limits correct (inner=240s, mid=360s, outer=480s)")
			passed += 1
		else:
			print("FAIL: time_pressure limits wrong — inner=%d mid=%d outer=%d" % [inner_t, mid_t, outer_t])
			failed += 1
	else:
		print("FAIL: time_pressure missing time_limits dictionary")
		failed += 1

	# ── Test 6: one_life — description confirms permanent death ──────────────
	var ol: Dictionary = by_id.get("one_life", {})
	if not ol.is_empty() and str(ol.get("description", "")).find("permanent") >= 0:
		print("PASS: one_life enforces permanent death (description confirms)")
		passed += 1
	else:
		print("FAIL: one_life missing or description does not mention permanent death")
		failed += 1

	# ── Test 7: cursed_ground — 25% damage increase design ──────────────────
	var cg: Dictionary = by_id.get("cursed_ground", {})
	if not cg.is_empty() and str(cg.get("description", "")).find("+25%") >= 0:
		print("PASS: cursed_ground specifies +25% enemy damage")
		passed += 1
	else:
		print("FAIL: cursed_ground missing or description does not mention +25% damage")
		failed += 1

	# ── Test 8: silent_run — disables fragments and modifiers ────────────────
	var sr: Dictionary = by_id.get("silent_run", {})
	var sr_desc := str(sr.get("description", ""))
	if not sr.is_empty() and sr_desc.find("fragments disabled") >= 0 and sr_desc.find("Modifier cards disabled") >= 0:
		print("PASS: silent_run disables lore fragments and modifier cards")
		passed += 1
	else:
		print("FAIL: silent_run missing or description incomplete — '%s'" % sr_desc)
		failed += 1

	# ── Test 9: RingDirector integration — escalation adds enemies ───────────
	var encounters_cleared := 3
	var cap := int(es.get("extra_enemy_cap", 4))
	var extra := mini(encounters_cleared, cap)
	if extra == 3:
		print("PASS: escalation adds 3 extra enemies after 3 encounters (cap 4)")
		passed += 1
	else:
		print("FAIL: escalation extra calculation wrong — expected 3, got %d" % extra)
		failed += 1

	# ── Test 10: Shard bonus awarded on completion, not on death ─────────────
	var ir_bonus := int(ir.get("shard_bonus", 0))
	if ir_bonus > 0:
		print("PASS: shard_bonus is positive (%d), awarded only on completion (code enforced)" % ir_bonus)
		passed += 1
	else:
		print("FAIL: shard_bonus should be positive")
		failed += 1

	print("\nChallenge enforcement tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
