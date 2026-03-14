extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- Test 1: Template composition honored ---
	# Load data files, instantiate RingDirector, verify generate_encounter returns
	# a populated enemies array whose size matches the returned enemy_count.
	var f_enemies := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if not f_enemies:
		failures.append("Test 1: enemies.json not found")
	else:
		var f_templates := FileAccess.open("res://data/encounter_templates.json", FileAccess.READ)
		if not f_templates:
			failures.append("Test 1: encounter_templates.json not found")
		else:
			var enemies_data = JSON.parse_string(f_enemies.get_as_text())
			var templates_data = JSON.parse_string(f_templates.get_as_text())
			GameState.apply_save_state(GameState.default_save_state())
			var rd = load("res://scripts/systems/ring_director.gd").new()
			var result: Dictionary = rd.generate_encounter(12345, "inner", enemies_data, templates_data)
			if not result.has("enemies"):
				failures.append("Test 1: generate_encounter result missing 'enemies' key")
			elif (result["enemies"] as Array).is_empty():
				failures.append("Test 1: generate_encounter returned empty enemies array")
			elif not result.has("enemy_count"):
				failures.append("Test 1: generate_encounter result missing 'enemy_count' key")
			elif (result["enemies"] as Array).size() != int(result["enemy_count"]):
				failures.append("Test 1: enemies array size %d does not match enemy_count %d" % [
					(result["enemies"] as Array).size(), int(result["enemy_count"])
				])

	# --- Test 2: Upgrade uniqueness ---
	# Each upgrade must have a unique (stat, modifier_type, value) tuple.
	var f_upgrades := FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if not f_upgrades:
		failures.append("Test 2: upgrades.json not found")
	else:
		var upgrades_data = JSON.parse_string(f_upgrades.get_as_text())
		if not (upgrades_data is Dictionary):
			failures.append("Test 2: upgrades.json did not parse as Dictionary")
		else:
			var upgrades_list: Array = upgrades_data.get("upgrades", [])
			if upgrades_list.size() < 16:
				failures.append("Test 2: expected >= 16 upgrades, got %d" % upgrades_list.size())
			var seen_tuples: Dictionary = {}
			var duplicates: Array[String] = []
			for entry in upgrades_list:
				var key: String = "%s|%s|%s" % [
					str(entry.get("stat", "")),
					str(entry.get("modifier_type", "")),
					str(entry.get("value", "")),
				]
				if seen_tuples.has(key):
					duplicates.append("id='%s' duplicates key '%s'" % [str(entry.get("id", "?")), key])
				seen_tuples[key] = true
			if not duplicates.is_empty():
				for d in duplicates:
					failures.append("Test 2: duplicate upgrade tuple: " + d)

	# --- Test 3: Modifier pool size ---
	var f_modifiers := FileAccess.open("res://data/modifiers.json", FileAccess.READ)
	if not f_modifiers:
		failures.append("Test 3: modifiers.json not found")
	else:
		var modifiers_data = JSON.parse_string(f_modifiers.get_as_text())
		if not (modifiers_data is Dictionary):
			failures.append("Test 3: modifiers.json did not parse as Dictionary")
		else:
			var mods: Array = modifiers_data.get("modifiers", [])
			if mods.size() < 9:
				failures.append("Test 3: expected >= 9 modifiers, got %d" % mods.size())

	# --- Test 4: Warden phase_changed signal ---
	# Verify phase transitions fire at correct HP thresholds and do not double-emit.
	var ec = load("res://scripts/core/enemy_controller.gd").new()
	ec.is_boss = true
	ec.health = 1200
	ec.initial_health = 1200
	ec.damage_multiplier = 1.0
	var phase_seen: Array = []
	ec.phase_changed.connect(func(p: int): phase_seen.append(p))

	# Trigger phase 2: hp_ratio = 840/1200 = 0.70 (boundary)
	ec.health = 840
	ec._update_boss_phase()
	if phase_seen.size() != 1:
		failures.append("Test 4: expected 1 phase signal after hp=840, got %d" % phase_seen.size())
	elif phase_seen[0] != 2:
		failures.append("Test 4: expected phase 2, got %d" % phase_seen[0])

	# Trigger phase 3: hp_ratio = 420/1200 = 0.35 (boundary)
	ec.health = 420
	ec._update_boss_phase()
	if phase_seen.size() != 2:
		failures.append("Test 4: expected 2 phase signals after hp=420, got %d" % phase_seen.size())
	elif phase_seen[1] != 3:
		failures.append("Test 4: expected phase 3 for second signal, got %d" % phase_seen[1])

	# Guard: calling again at same HP must not re-emit (phases only advance)
	ec._update_boss_phase()
	if phase_seen.size() != 2:
		failures.append("Test 4: double-emit guard failed, expected 2 signals, got %d" % phase_seen.size())

	# --- Test 5: Lifetime stats aggregation ---
	# Push 3 synthetic run records into GameState.run_history and verify
	# _compute_lifetime_stats() aggregates them correctly.
	GameState.apply_save_state(GameState.default_save_state())
	GameState.run_history = [
		{
			"ring_reached": "inner",
			"outcome": "died",
			"loot_banked": 50,
			"xp_banked": 30,
			"encounters_cleared": 1,
		},
		{
			"ring_reached": "outer",
			"outcome": "extracted",
			"loot_banked": 120,
			"xp_banked": 80,
			"encounters_cleared": 3,
		},
		{
			"ring_reached": "mid",
			"outcome": "warden_defeated",
			"loot_banked": 200,
			"xp_banked": 150,
			"encounters_cleared": 2,
		},
	]
	var rh_script = load("res://scripts/ui/run_history.gd")
	var rh = rh_script.new()
	var stats: Dictionary = rh._compute_lifetime_stats()
	if stats.get("total_runs", 0) != 3:
		failures.append("Test 5: expected total_runs=3, got %d" % stats.get("total_runs", 0))
	if stats.get("warden_defeats", 0) != 1:
		failures.append("Test 5: expected warden_defeats=1, got %d" % stats.get("warden_defeats", 0))
	if stats.get("deepest_ring", "") != "outer":
		failures.append("Test 5: expected deepest_ring='outer', got '%s'" % str(stats.get("deepest_ring", "")))
	if stats.get("total_loot", 0) != 370:
		failures.append("Test 5: expected total_loot=370, got %d" % stats.get("total_loot", 0))
	if stats.get("total_xp", 0) != 260:
		failures.append("Test 5: expected total_xp=260, got %d" % stats.get("total_xp", 0))
	if stats.get("total_encounters", 0) != 6:
		failures.append("Test 5: expected total_encounters=6, got %d" % stats.get("total_encounters", 0))
	rh.queue_free()

	# --- Test 6: XP sink items ---
	# shop_items.json must have >= 5 items with cost_xp and include the 3 key permanent_xp items.
	var f_shop := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if not f_shop:
		failures.append("Test 6: shop_items.json not found")
	else:
		var shop_data = JSON.parse_string(f_shop.get_as_text())
		if not (shop_data is Dictionary):
			failures.append("Test 6: shop_items.json did not parse as Dictionary")
		else:
			var items: Array = shop_data.get("items", [])
			var xp_items: Array = items.filter(func(i): return i.has("cost_xp"))
			if xp_items.size() < 5:
				failures.append("Test 6: expected >= 5 XP-costed items, got %d" % xp_items.size())
			var xp_item_ids: Array = xp_items.map(func(i): return str(i.get("id", "")))
			for expected_id in ["veteran_spirit", "deep_pockets", "warden_insight"]:
				if expected_id not in xp_item_ids:
					failures.append("Test 6: missing XP item '%s'" % expected_id)

	# --- Test 7: die_in_run resets loot_per_encounter_modifier ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.start_run(1, "inner")
	GameState.loot_per_encounter_modifier = 8
	GameState.die_in_run()
	if GameState.loot_per_encounter_modifier != 0:
		failures.append("Test 7: expected loot_per_encounter_modifier=0 after die_in_run, got %d" % GameState.loot_per_encounter_modifier)

	# --- Test 8: dodge_cost resets per run ---
	GameState.apply_save_state(GameState.default_save_state())
	var pc8 := PlayerController.new()
	pc8.dodge_cost = 10
	pc8.reset_for_run()
	if pc8.dodge_cost != 22:
		failures.append("Test 8: expected dodge_cost=22 after reset_for_run, got %d" % pc8.dodge_cost)
	pc8.queue_free()

	# --- Test 9: stamina_regen_per_sec resets per run ---
	GameState.apply_save_state(GameState.default_save_state())
	var pc9 := PlayerController.new()
	pc9.stamina_regen_per_sec = 30.0
	pc9.reset_for_run()
	if abs(pc9.stamina_regen_per_sec - 18.0) > 0.001:
		failures.append("Test 9: expected stamina_regen_per_sec=18.0 after reset_for_run, got %.4f" % pc9.stamina_regen_per_sec)
	pc9.queue_free()

	if failures.is_empty():
		print("PASS: test_m10")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
