extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: warden_defeated outcome appended to run_history by record_warden_defeated()
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(5001, "outer")
	GameState.record_warden_defeated()
	if GameState.run_history.size() != 1:
		failures.append("Test 1: expected 1 record after record_warden_defeated, got %d" % GameState.run_history.size())
	else:
		var rec: Dictionary = GameState.run_history[0]
		if rec.get("outcome", "") != "warden_defeated":
			failures.append("Test 1: expected outcome 'warden_defeated', got '%s'" % rec.get("outcome", ""))

	# Test 2: game_completed persists (set it, call to_save_state(), verify it's in output)
	GameState.apply_save_state(GameState.default_save_state())
	GameState.game_completed = true
	var save_out: Dictionary = GameState.to_save_state()
	if not save_out.get("game_completed", false):
		failures.append("Test 2: game_completed should be true in to_save_state() output")

	# Test 3: reset_for_new_game() resets run state but run_history IS reset per spec
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(5002, "inner")
	GameState.die_in_run()
	GameState.encounters_cleared = 5
	GameState.current_ring = "mid"
	GameState.reset_for_new_game()
	if GameState.encounters_cleared != 0:
		failures.append("Test 3: reset_for_new_game() should reset encounters_cleared to 0, got %d" % GameState.encounters_cleared)
	if GameState.current_ring != "sanctuary":
		failures.append("Test 3: reset_for_new_game() should reset current_ring to 'sanctuary', got '%s'" % GameState.current_ring)
	# run_history IS reset on new game per spec
	if GameState.run_history.size() != 0:
		failures.append("Test 3: reset_for_new_game() should reset run_history to [], got size %d" % GameState.run_history.size())

	# Test 4: reset_for_new_game() resets warden_defeated to false
	GameState.apply_save_state(GameState.default_save_state())
	GameState.warden_defeated = true
	GameState.reset_for_new_game()
	if GameState.warden_defeated != false:
		failures.append("Test 4: reset_for_new_game() should reset warden_defeated to false, got %s" % str(GameState.warden_defeated))

	# Test 5: reset_for_new_game() resets weapons_unlocked to ["blade_iron"]
	GameState.apply_save_state(GameState.default_save_state())
	GameState.unlock_weapon("polearm_iron")
	GameState.reset_for_new_game()
	if GameState.weapons_unlocked.size() != 1:
		failures.append("Test 5: reset_for_new_game() should reset weapons_unlocked to 1 entry, got %d" % GameState.weapons_unlocked.size())
	elif GameState.weapons_unlocked[0] != "blade_iron":
		failures.append("Test 5: reset_for_new_game() should reset weapons_unlocked to ['blade_iron'], got '%s'" % GameState.weapons_unlocked[0])

	if failures.is_empty():
		print("PASS: test_victory_state")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
