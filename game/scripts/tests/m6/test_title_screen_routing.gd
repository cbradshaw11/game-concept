extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: title_screen.tscn exists at res://game/scenes/ui/title_screen.tscn
	if not FileAccess.file_exists("res://scenes/ui/title_screen.tscn"):
		failures.append("title_screen.tscn not found at res://scenes/ui/title_screen.tscn")

	# Test 2: title_screen.gd exists and can be loaded
	if not FileAccess.file_exists("res://autoload/title_screen.gd"):
		failures.append("title_screen.gd not found at res://autoload/title_screen.gd")

	# Test 3: GameState.reset_for_new_game() resets relevant fields
	GameState.banked_loot = 999
	GameState.banked_xp = 500
	GameState.prologue_seen = true
	GameState.permanent_upgrades = [{"id": "test_upgrade"}]
	GameState.rings_cleared = ["inner", "outer"]
	GameState.reset_for_new_game()
	if GameState.banked_loot != 0:
		failures.append("reset_for_new_game() did not reset banked_loot to 0, got %d" % GameState.banked_loot)
	if GameState.rings_cleared.size() != 0:
		failures.append("reset_for_new_game() did not reset rings_cleared to [], got size %d" % GameState.rings_cleared.size())
	if GameState.permanent_upgrades.size() != 0:
		failures.append("reset_for_new_game() did not reset permanent_upgrades to [], got size %d" % GameState.permanent_upgrades.size())

	# Test 4: game_completed field is in default_save_state()
	var defaults := GameState.default_save_state()
	if not "game_completed" in defaults:
		failures.append("game_completed not found in default_save_state()")

	# Test 5: prologue.tscn exists at res://scenes/ui/prologue.tscn
	if not FileAccess.file_exists("res://scenes/ui/prologue.tscn"):
		failures.append("prologue.tscn not found at res://scenes/ui/prologue.tscn")

	if failures.is_empty():
		print("PASS: test_title_screen_routing")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
