extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: RunRecord appended on die_in_run() -- outcome=="died", ring_reached set
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(1001, "inner")
	GameState.die_in_run()
	if GameState.run_history.size() != 1:
		failures.append("Test 1: expected 1 record after die_in_run, got %d" % GameState.run_history.size())
	else:
		var rec: Dictionary = GameState.run_history[0]
		if rec.get("outcome", "") != "died":
			failures.append("Test 1: expected outcome=='died', got '%s'" % rec.get("outcome", ""))
		if rec.get("ring_reached", "") != "inner":
			failures.append("Test 1: expected ring_reached=='inner', got '%s'" % rec.get("ring_reached", ""))

	# Test 2: RunRecord appended on extract() -- outcome=="extracted"
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(1002, "mid")
	GameState.extract()
	if GameState.run_history.size() != 1:
		failures.append("Test 2: expected 1 record after extract, got %d" % GameState.run_history.size())
	else:
		var rec: Dictionary = GameState.run_history[0]
		if rec.get("outcome", "") != "extracted":
			failures.append("Test 2: expected outcome=='extracted', got '%s'" % rec.get("outcome", ""))

	# Test 3: record_warden_defeated() appends outcome=="warden_defeated"
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(1003, "outer")
	GameState.record_warden_defeated()
	if GameState.run_history.size() != 1:
		failures.append("Test 3: expected 1 record after record_warden_defeated, got %d" % GameState.run_history.size())
	else:
		var rec: Dictionary = GameState.run_history[0]
		if rec.get("outcome", "") != "warden_defeated":
			failures.append("Test 3: expected outcome=='warden_defeated', got '%s'" % rec.get("outcome", ""))

	# Test 4: record_warden_defeated() followed by extract() produces ONLY 1 record
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.start_run(1004, "outer")
	GameState.record_warden_defeated()
	GameState.extract()
	if GameState.run_history.size() != 1:
		failures.append("Test 4: expected 1 record (duplicate guard), got %d" % GameState.run_history.size())

	# Test 5: run_history capped at 20 (simulate 25 runs via die_in_run, check size == 20)
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	for i in range(25):
		GameState._run_outcome_recorded = false
		GameState.start_run(2000 + i, "inner")
		GameState.die_in_run()
	if GameState.run_history.size() != 20:
		failures.append("Test 5: expected run_history capped at 20, got %d" % GameState.run_history.size())

	# Test 6: M6 (v3) save migrates to v4 with run_history=[], weapons_unlocked=["blade_iron"]
	var v3_save := {
		"banked_xp": 300,
		"banked_loot": 150,
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
	}
	GameState.apply_save_state(v3_save)
	if GameState.run_history.size() != 0:
		failures.append("Test 6: v3 save should migrate run_history=[], got size %d" % GameState.run_history.size())
	if GameState.weapons_unlocked.size() != 1 or GameState.weapons_unlocked[0] != "blade_iron":
		failures.append("Test 6: v3 save should migrate weapons_unlocked=['blade_iron'], got %s" % str(GameState.weapons_unlocked))

	if failures.is_empty():
		print("PASS: test_run_history")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
