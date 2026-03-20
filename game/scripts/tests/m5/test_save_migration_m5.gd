extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# M4-era save dict: no save_version, no warden_phase_reached
	var m4_save := {
		"unbanked_xp": 100,
		"unbanked_loot": 50,
		"banked_loot": 200,
		"current_ring": "inner",
		"rings_cleared": ["inner"],
		"warden_defeated": false,
		"game_completed": false,
		# intentionally missing save_version and warden_phase_reached
	}

	GameState.apply_save_state(m4_save)

	# Test 1: warden_phase_reached defaults to -1 when save_version is absent
	if GameState.warden_phase_reached != -1:
		failures.append("Expected warden_phase_reached == -1 for M4 save, got %d" % GameState.warden_phase_reached)

	# Test 2: rings_cleared preserved from M4 save
	if not GameState.rings_cleared.has("inner"):
		failures.append("rings_cleared not preserved from M4 save")

	if failures.is_empty():
		print("PASS: test_save_migration_m5")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
