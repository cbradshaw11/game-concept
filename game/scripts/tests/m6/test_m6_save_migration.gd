extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: M3 save (no save_version) migrates cleanly
	# warden_phase_reached=-1, permanent_upgrades=[], prologue_seen=false
	var m3_save := {
		"banked_xp": 50,
		"banked_loot": 100,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		# no save_version, no warden_phase_reached, no permanent_upgrades, no prologue_seen
	}
	GameState.apply_save_state(m3_save)
	if GameState.warden_phase_reached != -1:
		failures.append("M3 save: warden_phase_reached should be -1, got %d" % GameState.warden_phase_reached)
	if GameState.permanent_upgrades.size() != 0:
		failures.append("M3 save: permanent_upgrades should be [], got size %d" % GameState.permanent_upgrades.size())
	if GameState.prologue_seen != false:
		failures.append("M3 save: prologue_seen should be false, got %s" % str(GameState.prologue_seen))

	# Test 2: M5 save (save_version=1) migrates cleanly
	# permanent_upgrades=[], prologue_seen=false, first_run_complete=false
	var m5_save := {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		"warden_phase_reached": 2,
		"save_version": 1,
		# no permanent_upgrades, no prologue_seen, no first_run_complete
	}
	GameState.apply_save_state(m5_save)
	if GameState.permanent_upgrades.size() != 0:
		failures.append("M5 save: permanent_upgrades should be [], got size %d" % GameState.permanent_upgrades.size())
	if GameState.prologue_seen != false:
		failures.append("M5 save: prologue_seen should be false, got %s" % str(GameState.prologue_seen))
	if GameState.first_run_complete != false:
		failures.append("M5 save: first_run_complete should be false, got %s" % str(GameState.first_run_complete))

	# Test 3: M6 save (save_version=3) restores permanent_upgrades correctly from array
	var test_upgrades := [{"id": "ancestral_shard", "type": "permanent"}, {"id": "warden_map", "type": "permanent"}]
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
		"permanent_upgrades": test_upgrades,
		"save_version": 3,
	}
	GameState.apply_save_state(m6_save)
	if GameState.permanent_upgrades.size() != 2:
		failures.append("M6 save: expected 2 permanent_upgrades, got %d" % GameState.permanent_upgrades.size())

	# Test 4: apply_save_state with save_version=3 does NOT reset permanent_upgrades to []
	# (ensure the v>=3 branch runs, not the else branch that would reset it)
	if GameState.permanent_upgrades.size() == 0:
		failures.append("apply_save_state with save_version=3 reset permanent_upgrades to [] instead of restoring")

	# Test 5: save_version in to_save_state() output == 3
	var save_out := GameState.to_save_state()
	if save_out.get("save_version", -1) != 3:
		failures.append("Expected save_version == 3 in to_save_state(), got %s" % str(save_out.get("save_version", -1)))

	if failures.is_empty():
		print("PASS: test_m6_save_migration")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
