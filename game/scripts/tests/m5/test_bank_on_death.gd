extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Setup
	GameState.rings_cleared = ["inner"]
	GameState.unbanked_loot = 100
	GameState.banked_loot = 0

	GameState.die_in_run()

	# Test 1: 25% retention — int(100 * 0.25) == 25
	if GameState.banked_loot != 25:
		failures.append("Expected banked_loot == 25 after die_in_run() with unbanked=100, got %d" % GameState.banked_loot)

	# Test 2: rings_cleared is preserved across death
	if not GameState.rings_cleared.has("inner"):
		failures.append("rings_cleared lost 'inner' on die_in_run() — must persist through death")

	if failures.is_empty():
		print("PASS: test_bank_on_death")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
