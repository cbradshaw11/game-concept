extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Test 1: extract() with current_ring="inner" appends "inner" to rings_cleared
	GameState.rings_cleared = []
	GameState.current_ring = "inner"
	GameState.unbanked_xp = 0
	GameState.unbanked_loot = 0
	GameState.extract()
	if "inner" in GameState.rings_cleared:
		passed += 1
	else:
		print("FAIL: extract() should append current_ring to rings_cleared")
		failed += 1

	# Test 2: die_in_run() does NOT clear rings_cleared
	GameState.rings_cleared = ["inner"]
	GameState.current_ring = "mid"
	GameState.unbanked_xp = 100
	GameState.unbanked_loot = 20
	GameState.die_in_run()
	if "inner" in GameState.rings_cleared:
		passed += 1
	else:
		print("FAIL: die_in_run() should NOT clear rings_cleared")
		failed += 1

	# Test 3: Save round-trip preserves rings_cleared
	GameState.rings_cleared = ["inner", "mid"]
	var saved: Dictionary = GameState.to_save_state()
	GameState.rings_cleared = []
	GameState.apply_save_state(saved)
	if GameState.rings_cleared == ["inner", "mid"]:
		passed += 1
	else:
		print("FAIL: apply_save_state() should restore rings_cleared to [inner, mid], got %s" % str(GameState.rings_cleared))
		failed += 1

	# Test 4: Extracting the same ring twice does not duplicate it
	GameState.rings_cleared = ["inner"]
	GameState.current_ring = "inner"
	GameState.unbanked_xp = 0
	GameState.unbanked_loot = 0
	GameState.extract()
	if GameState.rings_cleared.count("inner") == 1:
		passed += 1
	else:
		print("FAIL: rings_cleared should not duplicate 'inner', got %s" % str(GameState.rings_cleared))
		failed += 1

	if failed == 0:
		print("PASS: test_ring_unlock_progression")
		quit(0)
	else:
		print("FAIL: %d tests failed" % failed)
		quit(1)
