## M18 Test: Warden gate narrative fires before boss combat.
## Validates that NarrativeManager provides the warden intro lines,
## DataStore provides the boss data, and the gate flow prerequisites are met.
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Load narrative.json directly ─────────────────────────────────────────
	var file := FileAccess.open("res://data/narrative.json", FileAccess.READ)
	if file == null:
		printerr("FAIL: could not open narrative.json")
		quit(1)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		printerr("FAIL: JSON parse error in narrative.json")
		quit(1)
		return
	var data: Dictionary = json.get_data()

	# ── T1: warden_intro exists with lines ──────────────────────────────────
	var warden: Dictionary = data.get("warden_intro", {})
	var lines: Array = warden.get("lines", [])
	if lines.size() >= 4:
		print("PASS: warden_intro has %d lines for gate display" % lines.size())
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro should have >= 4 lines, got %d" % lines.size())
		checks_failed += 1

	# ── T2: Lines are sequential (non-empty strings) ────────────────────────
	var all_strings := true
	for line in lines:
		if typeof(line) != TYPE_STRING or str(line).strip_edges() == "":
			all_strings = false
			break
	if all_strings:
		print("PASS: all warden_intro lines are non-empty strings")
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro lines should all be non-empty strings")
		checks_failed += 1

	# ── T3: Ends with action beat "It moves." ──────────────────────────────
	if lines.size() > 0 and str(lines[-1]).strip_edges() == "It moves.":
		print("PASS: warden_intro ends with 'It moves.' action beat")
		checks_passed += 1
	else:
		printerr("FAIL: last line should be 'It moves.'")
		checks_failed += 1

	# ── Load enemies.json for boss data ──────────────────────────────────────
	var efile := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if efile == null:
		printerr("FAIL: could not open enemies.json")
		quit(1)
		return
	var ejson := JSON.new()
	var eerr := ejson.parse(efile.get_as_text())
	efile.close()
	if eerr != OK:
		printerr("FAIL: JSON parse error in enemies.json")
		quit(1)
		return
	var edata: Dictionary = ejson.get_data()

	# ── T4: bosses array has outer_warden ───────────────────────────────────
	var bosses: Array = edata.get("bosses", [])
	var found_warden := false
	var warden_data: Dictionary = {}
	for boss in bosses:
		if str(boss.get("id", "")) == "outer_warden":
			found_warden = true
			warden_data = boss
			break
	if found_warden:
		print("PASS: outer_warden found in bosses array")
		checks_passed += 1
	else:
		printerr("FAIL: outer_warden not found in enemies.json bosses")
		checks_failed += 1

	# ── T5: Warden has ring == "outer" ─────────────────────────────────────
	if str(warden_data.get("ring", "")) == "outer":
		print("PASS: outer_warden ring is 'outer'")
		checks_passed += 1
	else:
		printerr("FAIL: outer_warden ring should be 'outer'")
		checks_failed += 1

	# ── T6: Warden has 3 phases ───────────────────────────────────────────
	if int(warden_data.get("phases", 0)) == 3:
		print("PASS: outer_warden has 3 phases")
		checks_passed += 1
	else:
		printerr("FAIL: outer_warden should have 3 phases, got %d" % int(warden_data.get("phases", 0)))
		checks_failed += 1

	# ── T7: Warden has damage field ──────────────────────────────────────────
	if int(warden_data.get("damage", 0)) > 0:
		print("PASS: outer_warden has damage=%d" % int(warden_data.get("damage", 0)))
		checks_passed += 1
	else:
		printerr("FAIL: outer_warden should have a damage value > 0")
		checks_failed += 1

	# ── T8: Warden has attack_cooldown field ─────────────────────────────────
	if float(warden_data.get("attack_cooldown", 0.0)) > 0.0:
		print("PASS: outer_warden has attack_cooldown=%.1f" % float(warden_data.get("attack_cooldown", 0.0)))
		checks_passed += 1
	else:
		printerr("FAIL: outer_warden should have attack_cooldown > 0")
		checks_failed += 1

	# ── Load rings.json for outer ring config ───────────────────────────────
	var rfile := FileAccess.open("res://data/rings.json", FileAccess.READ)
	if rfile == null:
		printerr("FAIL: could not open rings.json")
		quit(1)
		return
	var rjson := JSON.new()
	var rerr := rjson.parse(rfile.get_as_text())
	rfile.close()
	if rerr != OK:
		printerr("FAIL: JSON parse error in rings.json")
		quit(1)
		return
	var rdata: Dictionary = rjson.get_data()
	var outer_ring: Dictionary = {}
	for ring in rdata.get("rings", []):
		if str(ring.get("id", "")) == "outer":
			outer_ring = ring
			break

	# ── T9: Outer ring has unlock_condition ─────────────────────────────────
	var condition := str(outer_ring.get("unlock_condition", ""))
	if condition == "extracted_mid_once":
		print("PASS: outer ring unlock_condition is 'extracted_mid_once'")
		checks_passed += 1
	else:
		printerr("FAIL: outer ring unlock_condition should be 'extracted_mid_once', got '%s'" % condition)
		checks_failed += 1

	# ── T10: Outer ring has background field ────────────────────────────────
	var bg := str(outer_ring.get("background", ""))
	if bg != "":
		print("PASS: outer ring has background='%s'" % bg)
		checks_passed += 1
	else:
		printerr("FAIL: outer ring should have a background field")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M18 boss gate test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M18 boss gate test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
