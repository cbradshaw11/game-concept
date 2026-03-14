extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Build a v3 save (no run_history, no weapons_unlocked, no xp_gain_multiplier, no warden_map_unlocked)
	var v3_save := {
		"banked_xp": 200,
		"banked_loot": 80,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": ["inner"],
		"warden_defeated": false,
		"game_completed": false,
		"warden_phase_reached": -1,
		"prologue_seen": true,
		"first_run_complete": true,
		"permanent_upgrades": [],
		"selected_weapon_id": "blade_iron",
		"save_version": 3,
		# intentionally omits: run_history, weapons_unlocked, xp_gain_multiplier, warden_map_unlocked
	}

	# Test 1: v3 save loads with run_history=[]
	GameState.apply_save_state(v3_save)
	if GameState.run_history.size() != 0:
		failures.append("Test 1: v3 save should produce run_history=[], got size %d" % GameState.run_history.size())

	# Test 2: v3 save loads with weapons_unlocked=["blade_iron"]
	if GameState.weapons_unlocked.size() != 1:
		failures.append("Test 2: v3 save should produce weapons_unlocked size 1, got %d" % GameState.weapons_unlocked.size())
	elif GameState.weapons_unlocked[0] != "blade_iron":
		failures.append("Test 2: v3 save should produce weapons_unlocked=['blade_iron'], got '%s'" % GameState.weapons_unlocked[0])

	# Test 3: v3 save loads with xp_gain_multiplier=1.0
	if GameState.xp_gain_multiplier != 1.0:
		failures.append("Test 3: v3 save should load with xp_gain_multiplier=1.0, got %s" % str(GameState.xp_gain_multiplier))

	# Test 4: v3 save loads with warden_map_unlocked=false
	if GameState.warden_map_unlocked != false:
		failures.append("Test 4: v3 save should load with warden_map_unlocked=false, got %s" % str(GameState.warden_map_unlocked))

	# Test 5: v4 save round-trip: set run_history=[{outcome:"died"}], to_save_state(), apply_save_state(), verify preserved
	GameState.apply_save_state(GameState.default_save_state())
	GameState.run_history = [{"outcome": "died", "ring_reached": "inner", "encounters_cleared": 3}]
	var saved: Dictionary = GameState.to_save_state()
	GameState.apply_save_state(saved)
	if GameState.run_history.size() != 1:
		failures.append("Test 5: v4 round-trip should preserve run_history size 1, got %d" % GameState.run_history.size())
	else:
		var rec: Dictionary = GameState.run_history[0]
		if rec.get("outcome", "") != "died":
			failures.append("Test 5: v4 round-trip should preserve outcome='died', got '%s'" % rec.get("outcome", ""))

	# Test 6: v4 save round-trip: set weapons_unlocked=["blade_iron","polearm_iron"], verify after round-trip
	GameState.apply_save_state(GameState.default_save_state())
	GameState.weapons_unlocked = ["blade_iron", "polearm_iron"]
	var saved2: Dictionary = GameState.to_save_state()
	GameState.apply_save_state(saved2)
	if GameState.weapons_unlocked.size() != 2:
		failures.append("Test 6: v4 round-trip should preserve 2 weapons, got %d" % GameState.weapons_unlocked.size())
	elif "polearm_iron" not in GameState.weapons_unlocked:
		failures.append("Test 6: v4 round-trip should preserve 'polearm_iron' in weapons_unlocked")

	if failures.is_empty():
		print("PASS: test_m7_save_migration")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
