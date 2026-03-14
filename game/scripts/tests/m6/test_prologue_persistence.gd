extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var defaults := GameState.default_save_state()

	# Test 1: prologue_seen defaults to false in default_save_state()
	if defaults.get("prologue_seen", true) != false:
		failures.append("prologue_seen should default to false in default_save_state()")

	# Test 2: first_run_complete defaults to false in default_save_state()
	if defaults.get("first_run_complete", true) != false:
		failures.append("first_run_complete should default to false in default_save_state()")

	# Test 3: Both are included in to_save_state() output
	GameState.apply_save_state(defaults)
	var save := GameState.to_save_state()
	if not "prologue_seen" in save:
		failures.append("prologue_seen not found in to_save_state() output")
	if not "first_run_complete" in save:
		failures.append("first_run_complete not found in to_save_state() output")

	# Test 4: M5 save dict (save_version=1, no prologue_seen, no first_run_complete) applies cleanly
	var m5_save := {
		"banked_xp": 50,
		"banked_loot": 100,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		"warden_phase_reached": 2,
		"save_version": 1,
		# intentionally missing prologue_seen and first_run_complete
	}
	GameState.apply_save_state(m5_save)
	if GameState.prologue_seen != false:
		failures.append("M5 save: prologue_seen should default to false, got %s" % str(GameState.prologue_seen))
	if GameState.first_run_complete != false:
		failures.append("M5 save: first_run_complete should default to false, got %s" % str(GameState.first_run_complete))

	# Test 5: M6 save dict (save_version=3, prologue_seen=true) restores correctly
	var m6_save := {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		"warden_phase_reached": -1,
		"prologue_seen": true,
		"first_run_complete": true,
		"permanent_upgrades": [],
		"save_version": 3,
	}
	GameState.apply_save_state(m6_save)
	if GameState.prologue_seen != true:
		failures.append("M6 save: prologue_seen should be true, got %s" % str(GameState.prologue_seen))
	if GameState.first_run_complete != true:
		failures.append("M6 save: first_run_complete should be true, got %s" % str(GameState.first_run_complete))

	if failures.is_empty():
		print("PASS: test_prologue_persistence")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
