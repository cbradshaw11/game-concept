extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: pending_modifier is consumed by start_run() and placed in active_modifiers
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.pending_modifier = {"id": "ironclad", "name": "Ironclad"}
	GameState.start_run(12345, "inner")
	if GameState.active_modifiers.size() != 1:
		failures.append("Test 1: expected active_modifiers size 1 after start_run with pending_modifier, got %d" % GameState.active_modifiers.size())
	else:
		var mod: Dictionary = GameState.active_modifiers[0]
		if mod.get("id", "") != "ironclad":
			failures.append("Test 1: expected active_modifiers[0].id=='ironclad', got '%s'" % mod.get("id", ""))
	if not GameState.pending_modifier.is_empty():
		failures.append("Test 1: expected pending_modifier to be empty after start_run, got %s" % str(GameState.pending_modifier))

	# Test 2: abandon_run() clears active_modifiers
	GameState.abandon_run()
	if GameState.active_modifiers.size() != 0:
		failures.append("Test 2: expected active_modifiers empty after abandon_run, got size %d" % GameState.active_modifiers.size())

	# Test 3: v4->v5 migration: apply_save_state with save_version=4 defaults active_modifiers to []
	var v4_save := {
		"save_version": 4,
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		"prologue_seen": false,
		"first_run_complete": false,
		"permanent_upgrades": [],
		"selected_weapon_id": "blade_iron",
		"run_history": [],
		"weapons_unlocked": ["blade_iron"],
		"xp_gain_multiplier": 1.0,
		"warden_map_unlocked": false,
	}
	GameState.apply_save_state(v4_save)
	if GameState.active_modifiers.size() != 0:
		failures.append("Test 3: v4 save should migrate active_modifiers=[], got size %d" % GameState.active_modifiers.size())

	if failures.is_empty():
		print("PASS: test_modifier_draw")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
