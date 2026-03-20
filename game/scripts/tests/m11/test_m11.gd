extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- Test 1: save_version is 6 in default_save_state and to_save_state ---
	GameState.apply_save_state(GameState.default_save_state())
	var default_state: Dictionary = GameState.default_save_state()
	if default_state.get("save_version") != 6:
		failures.append("Test 1a: default_save_state save_version expected 6, got %s" % str(default_state.get("save_version")))
	var live_state: Dictionary = GameState.to_save_state()
	if live_state.get("save_version") != 6:
		failures.append("Test 1b: to_save_state save_version expected 6, got %s" % str(live_state.get("save_version")))

	# --- Test 2: rings_story_seen in default_save_state ---
	if not default_state.has("rings_story_seen"):
		failures.append("Test 2a: default_save_state missing 'rings_story_seen' key")
	else:
		var rss = default_state.get("rings_story_seen")
		if not (rss is Array) or not (rss as Array).is_empty():
			failures.append("Test 2b: default rings_story_seen expected [], got %s" % str(rss))

	# --- Test 3: total_runs in default_save_state ---
	if not default_state.has("total_runs"):
		failures.append("Test 3a: default_save_state missing 'total_runs' key")
	else:
		if default_state.get("total_runs") != 0:
			failures.append("Test 3b: default total_runs expected 0, got %s" % str(default_state.get("total_runs")))

	# --- Test 4: rings_story_seen migration from v5 save ---
	# v5 saves have no rings_story_seen; total_runs should be inferred from history size
	var v5_save: Dictionary = {
		"save_version": 5,
		"banked_xp": 0,
		"banked_loot": 0,
		"run_history": [
			{"ring_reached": "inner", "outcome": "died", "loot_banked": 10, "xp_banked": 5, "encounters_cleared": 1},
			{"ring_reached": "mid", "outcome": "extracted", "loot_banked": 80, "xp_banked": 40, "encounters_cleared": 2},
		],
		"weapons_unlocked": ["blade_iron"],
		"active_modifiers": [],
		"permanent_purchases": [],
	}
	GameState.apply_save_state(v5_save)
	if GameState.rings_story_seen != []:
		failures.append("Test 4a: after v5 migration rings_story_seen expected [], got %s" % str(GameState.rings_story_seen))
	if GameState.total_runs != 2:
		failures.append("Test 4b: after v5 migration total_runs expected 2 (run_history.size()), got %d" % GameState.total_runs)

	# --- Test 5: rings_story_seen migration from v6 save preserves values ---
	var v6_save: Dictionary = {
		"save_version": 6,
		"banked_xp": 0,
		"banked_loot": 0,
		"run_history": [],
		"weapons_unlocked": ["blade_iron"],
		"active_modifiers": [],
		"permanent_purchases": [],
		"rings_story_seen": ["inner"],
		"total_runs": 0,
	}
	GameState.apply_save_state(v6_save)
	if "inner" not in GameState.rings_story_seen:
		failures.append("Test 5: after v6 save apply rings_story_seen should contain 'inner', got %s" % str(GameState.rings_story_seen))

	# --- Test 6: rings_story_seen elements are typed as String ---
	var v6_typed_save: Dictionary = {
		"save_version": 6,
		"banked_xp": 0,
		"banked_loot": 0,
		"run_history": [],
		"weapons_unlocked": ["blade_iron"],
		"active_modifiers": [],
		"permanent_purchases": [],
		"rings_story_seen": ["inner", "mid"],
		"total_runs": 0,
	}
	GameState.apply_save_state(v6_typed_save)
	for element in GameState.rings_story_seen:
		if typeof(element) != TYPE_STRING:
			failures.append("Test 6: rings_story_seen element not TYPE_STRING, got typeof=%d value=%s" % [typeof(element), str(element)])

	# --- Test 7: rings have non-empty first_extraction_log ---
	var rings_list: Array = DataStore.rings.get("rings", [])
	if rings_list.is_empty():
		failures.append("Test 7: rings.json failed to load or has no 'rings' array")
	else:
		for ring_id in ["inner", "mid", "outer"]:
			var found := false
			for ring in rings_list:
				if str(ring.get("id", "")) == ring_id:
					found = true
					var log_val = ring.get("first_extraction_log", "")
					if not (log_val is String) or (log_val as String).is_empty():
						failures.append("Test 7: ring '%s' first_extraction_log is empty or missing" % ring_id)
					break
			if not found:
				failures.append("Test 7: ring '%s' not found in rings.json" % ring_id)

	# --- Test 8: warden enemy damage <= 18 ---
	var enemies_list: Array = DataStore.enemies.get("enemies", [])
	if enemies_list.is_empty():
		failures.append("Test 8: enemies.json failed to load or has no 'enemies' array")
	else:
		for enemy in enemies_list:
			var eid: String = str(enemy.get("id", ""))
			if "warden" in eid and "herald" not in eid:
				var dmg: int = int(enemy.get("damage", 0))
				if dmg > 18:
					failures.append("Test 8: warden enemy '%s' damage %d > 18" % [eid, dmg])

	# --- Test 9: warden_herald exists, is mini_boss, damage <= 18 ---
	var herald_found := false
	for enemy in enemies_list:
		if str(enemy.get("id", "")) == "warden_herald":
			herald_found = true
			if str(enemy.get("role", "")) != "mini_boss":
				failures.append("Test 9a: warden_herald role expected 'mini_boss', got '%s'" % str(enemy.get("role", "")))
			var herald_dmg: int = int(enemy.get("damage", 0))
			if herald_dmg > 18:
				failures.append("Test 9b: warden_herald damage %d > 18" % herald_dmg)
			break
	if not herald_found:
		failures.append("Test 9: warden_herald not found in enemies.json")

	# --- Test 10: player max_health is 115 ---
	var max_health = DataStore.weapons.get("global_combat", {}).get("max_health")
	if max_health != 115:
		failures.append("Test 10: global_combat max_health expected 115, got %s" % str(max_health))

	# --- Test 11: reckless_momentum upgrade value is 6 ---
	var upgrades_list: Array = DataStore.upgrades.get("upgrades", [])
	if upgrades_list.is_empty():
		failures.append("Test 11: upgrades.json failed to load or has no 'upgrades' array")
	else:
		var rm_found := false
		for upgrade in upgrades_list:
			if str(upgrade.get("id", "")) == "reckless_momentum":
				rm_found = true
				var rm_value = upgrade.get("value")
				if int(rm_value) != 6:
					failures.append("Test 11: reckless_momentum value expected 6, got %s" % str(rm_value))
				break
		if not rm_found:
			failures.append("Test 11: reckless_momentum upgrade not found in upgrades.json")

	# --- Test 12: outer ring template count >= 10 ---
	var templates_list: Array = DataStore.encounter_templates.get("templates", [])
	if templates_list.is_empty():
		failures.append("Test 12: encounter_templates.json failed to load or has no 'templates' array")
	else:
		var outer_count := 0
		for template in templates_list:
			if str(template.get("ring", "")) == "outer":
				outer_count += 1
		if outer_count < 10:
			failures.append("Test 12: outer ring template count expected >= 10, got %d" % outer_count)

	# --- Test 13: warden_herald never appears in random encounter pool ---
	# Pass {} as templates_data to force the random fallback path.
	# The random fallback explicitly filters out role == "mini_boss".
	GameState.apply_save_state(GameState.default_save_state())
	var rd13 = load("res://scripts/systems/ring_director.gd").new()
	var enemies_data_13: Dictionary = DataStore.enemies
	var herald_appeared := false
	for i in range(20):
		var result13: Dictionary = rd13.generate_encounter(i * 7 + 1, "outer", enemies_data_13, {})
		for e in result13.get("enemies", []):
			if str(e.get("id", "")) == "warden_herald":
				herald_appeared = true
	if herald_appeared:
		failures.append("Test 13: warden_herald appeared in random encounter pool (should be excluded as mini_boss)")

	# --- Test 14: seed fallback path returns non-empty encounters with different encounters_cleared ---
	GameState.apply_save_state(GameState.default_save_state())
	var rd14 = load("res://scripts/systems/ring_director.gd").new()
	var enemies_data_14: Dictionary = DataStore.enemies

	GameState.encounters_cleared = 0
	var result14a: Dictionary = rd14.generate_encounter(42, "outer", enemies_data_14, {})
	if result14a.get("enemies", []) is Array and (result14a.get("enemies", []) as Array).is_empty():
		failures.append("Test 14a: generate_encounter with encounters_cleared=0 returned empty enemies")

	GameState.encounters_cleared = 1
	var result14b: Dictionary = rd14.generate_encounter(42, "outer", enemies_data_14, {})
	if result14b.get("enemies", []) is Array and (result14b.get("enemies", []) as Array).is_empty():
		failures.append("Test 14b: generate_encounter with encounters_cleared=1 returned empty enemies")

	# --- Test 15: vendor button structural check ---
	# FlowUI must define _on_visit_vendor_pressed with an is_instance_valid guard.
	var flow_ui_src := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if flow_ui_src.is_empty():
		failures.append("Test 15a: could not read flow_ui.gd")
	else:
		if "_on_visit_vendor_pressed" not in flow_ui_src:
			failures.append("Test 15b: flow_ui.gd missing '_on_visit_vendor_pressed' method")
		# Check that the method body contains is_instance_valid (guard pattern)
		var method_start: int = flow_ui_src.find("func _on_visit_vendor_pressed")
		if method_start == -1:
			failures.append("Test 15c: flow_ui.gd missing 'func _on_visit_vendor_pressed'")
		else:
			# Grab a reasonable window after the method declaration to check for guard
			var method_region: String = flow_ui_src.substr(method_start, 300)
			if "is_instance_valid" not in method_region:
				failures.append("Test 15d: _on_visit_vendor_pressed body missing is_instance_valid guard")

	# --- Test 16: tutorial paged structure ---
	var arena_src := FileAccess.get_file_as_string("res://scenes/combat/combat_arena.gd")
	if arena_src.is_empty():
		failures.append("Test 16a: could not read combat_arena.gd")
	else:
		if "_TUTORIAL_CARDS" not in arena_src:
			failures.append("Test 16b: combat_arena.gd missing '_TUTORIAL_CARDS' constant")
		if "tutorial_page" not in arena_src:
			failures.append("Test 16c: combat_arena.gd missing 'tutorial_page' variable")
		# Count the number of dictionary entries in _TUTORIAL_CARDS by counting "title": occurrences
		# Each card is a Dictionary with a "title" key; this is a safe proxy for card count.
		var card_count := 0
		var search_pos := 0
		while true:
			var idx: int = arena_src.find('"title":', search_pos)
			if idx == -1:
				break
			card_count += 1
			search_pos = idx + 1
		if card_count != 3:
			failures.append("Test 16d: _TUTORIAL_CARDS expected 3 entries (by 'title' keys), found %d" % card_count)

	# --- Test 17: _combine_seed always returns non-negative value ---
	var rd17 = load("res://scripts/systems/ring_director.gd").new()
	var test_seeds: Array = [0, 1, 1700000000, -1]
	var test_rings: Array = ["inner", "mid", "outer"]
	for s in test_seeds:
		for r in test_rings:
			var combined: int = rd17._combine_seed(s, r)
			if combined < 0:
				failures.append("Test 17: _combine_seed(%d, '%s') returned negative value %d" % [s, r, combined])

	# --- Finalize ---
	if failures.is_empty():
		print("PASS: test_m11")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
