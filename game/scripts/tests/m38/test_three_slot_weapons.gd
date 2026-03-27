extends SceneTree

## M38 — Three-slot weapon system tests
## Validates: category field, slot defaults, save version, input actions, migration

const GameStateScript = preload("res://autoload/game_state.gd")
const SaveSystemScript = preload("res://scripts/systems/save_system.gd")

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	# ── Load weapon data from JSON directly ──────────────────────────────────
	var weapons_file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if weapons_file == null:
		print("FAIL: could not open weapons.json")
		quit(1)
		return
	var weapons_json = JSON.parse_string(weapons_file.get_as_text())
	weapons_file.close()
	var weapons: Array = weapons_json.get("weapons", [])

	# ── Test 1: Category field present on all 10 weapons ─────────────────────
	var all_have_category := true
	var missing_list: Array = []
	for w in weapons:
		var cat := str(w.get("category", ""))
		if cat == "":
			all_have_category = false
			missing_list.append(str(w.get("id", "unknown")))
	if all_have_category and weapons.size() >= 10:
		print("PASS: All %d weapons have category field" % weapons.size())
		pass_count += 1
	else:
		print("FAIL: Weapons missing category: %s (total: %d)" % [str(missing_list), weapons.size()])
		fail_count += 1

	# ── Test 2: Category values are valid ────────────────────────────────────
	var valid_cats := ["melee", "ranged", "magic"]
	var all_valid := true
	for w in weapons:
		var cat := str(w.get("category", ""))
		if not valid_cats.has(cat):
			all_valid = false
	if all_valid:
		print("PASS: All weapon categories are valid (melee/ranged/magic)")
		pass_count += 1
	else:
		print("FAIL: Some weapons have invalid category values")
		fail_count += 1

	# ── Test 3: Category distribution matches spec (5 melee, 2 ranged, 3 magic)
	var counts := {"melee": 0, "ranged": 0, "magic": 0}
	for w in weapons:
		var cat := str(w.get("category", ""))
		if counts.has(cat):
			counts[cat] = counts[cat] + 1
	if counts["melee"] == 5 and counts["ranged"] == 2 and counts["magic"] == 3:
		print("PASS: Category distribution correct (5 melee, 2 ranged, 3 magic)")
		pass_count += 1
	else:
		print("FAIL: Category distribution wrong — melee=%d ranged=%d magic=%d" % [counts["melee"], counts["ranged"], counts["magic"]])
		fail_count += 1

	# ── Test 4: Starter weapons exist (blade_iron, bow_iron, resonance_staff)
	var starter_ids := ["blade_iron", "bow_iron", "resonance_staff"]
	var starters_found := 0
	for sid in starter_ids:
		for w in weapons:
			if str(w.get("id", "")) == sid:
				starters_found += 1
				break
	if starters_found == 3:
		print("PASS: All 3 starter weapons found (blade_iron, bow_iron, resonance_staff)")
		pass_count += 1
	else:
		print("FAIL: Missing starter weapons (%d/3 found)" % starters_found)
		fail_count += 1

	# ── Test 5: Starter weapons have correct categories ──────────────────────
	var expected_cats := {"blade_iron": "melee", "bow_iron": "ranged", "resonance_staff": "magic"}
	var cats_ok := true
	for w in weapons:
		var wid := str(w.get("id", ""))
		if expected_cats.has(wid):
			if str(w.get("category", "")) != expected_cats[wid]:
				cats_ok = false
	if cats_ok:
		print("PASS: Starter weapons have correct categories")
		pass_count += 1
	else:
		print("FAIL: Starter weapon categories incorrect")
		fail_count += 1

	# ── Test 6: GameState default_save_state has equipped slots ──────────────
	var gs := GameStateScript.new()
	var defaults: Dictionary = gs.default_save_state()
	var melee_ok := str(defaults.get("equipped_melee", "")) == "blade_iron"
	var ranged_ok := str(defaults.get("equipped_ranged", "")) == "bow_iron"
	var magic_ok := str(defaults.get("equipped_magic", "")) == "resonance_staff"
	if melee_ok and ranged_ok and magic_ok:
		print("PASS: default_save_state has correct equipped defaults (blade_iron, bow_iron, resonance_staff)")
		pass_count += 1
	else:
		print("FAIL: default_save_state equipped defaults incorrect — melee=%s ranged=%s magic=%s" % [
			defaults.get("equipped_melee", "MISSING"),
			defaults.get("equipped_ranged", "MISSING"),
			defaults.get("equipped_magic", "MISSING"),
		])
		fail_count += 1

	# ── Test 7: to_save_state includes equipped slots ────────────────────────
	var state: Dictionary = gs.to_save_state()
	if state.has("equipped_melee") and state.has("equipped_ranged") and state.has("equipped_magic"):
		print("PASS: to_save_state includes equipped_melee, equipped_ranged, equipped_magic")
		pass_count += 1
	else:
		print("FAIL: to_save_state missing equipped slot keys")
		fail_count += 1

	# ── Test 8: InputMap has attack_melee, attack_ranged, attack_magic ───────
	var has_melee := InputMap.has_action("attack_melee")
	var has_ranged := InputMap.has_action("attack_ranged")
	var has_magic := InputMap.has_action("attack_magic")
	if has_melee and has_ranged and has_magic:
		print("PASS: InputMap has attack_melee, attack_ranged, attack_magic actions")
		pass_count += 1
	else:
		print("FAIL: InputMap missing actions — melee=%s ranged=%s magic=%s" % [has_melee, has_ranged, has_magic])
		fail_count += 1

	# ── Test 9: SaveSystem version is 11 ─────────────────────────────────────
	var sv := SaveSystemScript.get_save_version()
	if sv == 11:
		print("PASS: SaveSystem.SAVE_VERSION is 11")
		pass_count += 1
	else:
		print("FAIL: SaveSystem.SAVE_VERSION is %d, expected 11" % sv)
		fail_count += 1

	# ── Test 10: apply_save_state migration fills defaults from old save ─────
	var old_save := {"banked_xp": 50}  # No equipped fields — simulates pre-M38 save
	gs.apply_save_state(gs.default_save_state())  # Reset first
	gs.apply_save_state(old_save)
	if gs.equipped_melee == "blade_iron" and gs.equipped_ranged == "bow_iron" and gs.equipped_magic == "resonance_staff":
		print("PASS: apply_save_state migration fills default equipped slots from old save")
		pass_count += 1
	else:
		print("FAIL: apply_save_state migration did not fill defaults — melee=%s ranged=%s magic=%s" % [gs.equipped_melee, gs.equipped_ranged, gs.equipped_magic])
		fail_count += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	print("")
	print("M38 Three-Slot Weapons: %d passed, %d failed" % [pass_count, fail_count])
	if fail_count > 0:
		quit(1)
	else:
		quit(0)
