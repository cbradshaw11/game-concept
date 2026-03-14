extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- abandon_run() tests ---

	# Record run_history size before start_run to verify it is unchanged after abandon_run
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var history_size_before: int = GameState.run_history.size()

	GameState.start_run(99, "inner")
	GameState.unbanked_xp = 50
	GameState.unbanked_loot = 20
	GameState.abandon_run()

	# Test 1: abandon_run does NOT append to run_history
	if GameState.run_history.size() != history_size_before:
		failures.append("Test 1: abandon_run should not append to run_history; expected size %d, got %d" % [history_size_before, GameState.run_history.size()])

	# Test 2: abandon_run resets current_ring to "sanctuary"
	if GameState.current_ring != "sanctuary":
		failures.append("Test 2: abandon_run should set current_ring='sanctuary', got '%s'" % GameState.current_ring)

	# Test 3: abandon_run zeroes unbanked_xp
	if GameState.unbanked_xp != 0:
		failures.append("Test 3: abandon_run should zero unbanked_xp, got %d" % GameState.unbanked_xp)

	# Test 4: abandon_run zeroes unbanked_loot
	if GameState.unbanked_loot != 0:
		failures.append("Test 4: abandon_run should zero unbanked_loot, got %d" % GameState.unbanked_loot)

	# --- die_in_run() comparison test ---

	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var history_size_before_die: int = GameState.run_history.size()

	GameState.start_run(99, "inner")
	GameState.unbanked_xp = 50
	GameState.unbanked_loot = 20
	GameState.die_in_run()

	# Test 5: die_in_run DOES append to run_history (grows by 1)
	if GameState.run_history.size() != history_size_before_die + 1:
		failures.append("Test 5: die_in_run should append 1 record to run_history; expected size %d, got %d" % [history_size_before_die + 1, GameState.run_history.size()])

	if failures.is_empty():
		print("PASS: test_abandon_run")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
