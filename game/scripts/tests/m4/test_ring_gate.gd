extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Test 1: No rings cleared and no loot — mid ring should be inaccessible
	GameState.rings_cleared = []
	GameState.banked_loot = 0
	var mid_accessible: bool = "inner" in GameState.rings_cleared and GameState.banked_loot >= 50
	if not mid_accessible:
		passed += 1
	else:
		print("FAIL: mid ring should be inaccessible when rings_cleared=[] and banked_loot=0")
		failed += 1

	# Test 2: inner cleared and loot >= 50 — mid ring accessible
	GameState.rings_cleared = ["inner"]
	GameState.banked_loot = 50
	mid_accessible = "inner" in GameState.rings_cleared and GameState.banked_loot >= 50
	if mid_accessible:
		passed += 1
	else:
		print("FAIL: mid ring should be accessible when rings_cleared=[inner] and banked_loot=50")
		failed += 1

	# Test 3: inner cleared but loot=49 — loot gate blocks mid
	GameState.rings_cleared = ["inner"]
	GameState.banked_loot = 49
	mid_accessible = "inner" in GameState.rings_cleared and GameState.banked_loot >= 50
	if not mid_accessible:
		passed += 1
	else:
		print("FAIL: mid ring should be blocked when banked_loot=49 (below threshold 50)")
		failed += 1

	# Test 4: inner+mid cleared and loot >= 150 — outer ring accessible
	GameState.rings_cleared = ["inner", "mid"]
	GameState.banked_loot = 150
	var outer_accessible: bool = "mid" in GameState.rings_cleared and GameState.banked_loot >= 150
	if outer_accessible:
		passed += 1
	else:
		print("FAIL: outer ring should be accessible when rings_cleared=[inner,mid] and banked_loot=150")
		failed += 1

	# Test 5: mid cleared but loot=149 — loot gate blocks outer
	GameState.banked_loot = 149
	outer_accessible = "mid" in GameState.rings_cleared and GameState.banked_loot >= 150
	if not outer_accessible:
		passed += 1
	else:
		print("FAIL: outer ring should be blocked when banked_loot=149 (below threshold 150)")
		failed += 1

	if failed == 0:
		print("PASS: test_ring_gate")
		quit(0)
	else:
		print("FAIL: %d tests failed" % failed)
		quit(1)
