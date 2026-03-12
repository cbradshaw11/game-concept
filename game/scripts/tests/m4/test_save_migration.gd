extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Simulate an M3-era save dict that lacks the new M4 fields:
	# rings_cleared, warden_defeated, game_completed
	var old_save := {
		"unbanked_xp": 100,
		"unbanked_loot": 50,
		"current_ring": "inner",
		"banked_xp": 200,
		"banked_loot": 75,
	}

	# Pre-corrupt state to ensure apply_save_state actually sets defaults
	GameState.rings_cleared = ["inner", "mid"]
	GameState.warden_defeated = true
	GameState.game_completed = true

	GameState.apply_save_state(old_save)

	# Test 1: rings_cleared defaults to [] when missing from save
	if GameState.rings_cleared == []:
		passed += 1
	else:
		print("FAIL: rings_cleared should default to [] for M3 save, got %s" % str(GameState.rings_cleared))
		failed += 1

	# Test 2: warden_defeated defaults to false when missing from save
	if GameState.warden_defeated == false:
		passed += 1
	else:
		print("FAIL: warden_defeated should default to false for M3 save")
		failed += 1

	# Test 3: game_completed defaults to false when missing from save
	if GameState.game_completed == false:
		passed += 1
	else:
		print("FAIL: game_completed should default to false for M3 save")
		failed += 1

	# Test 4: Existing M3 fields are still applied correctly
	if GameState.banked_xp == 200 and GameState.banked_loot == 75:
		passed += 1
	else:
		print("FAIL: M3 fields should still load correctly, got banked_xp=%d banked_loot=%d" % [GameState.banked_xp, GameState.banked_loot])
		failed += 1

	if failed == 0:
		print("PASS: test_save_migration")
		quit(0)
	else:
		print("FAIL: %d tests failed" % failed)
		quit(1)
