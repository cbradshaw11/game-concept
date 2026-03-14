extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: weapons_unlocked defaults to ["blade_iron"]
	GameState.apply_save_state(GameState.default_save_state())
	if GameState.weapons_unlocked.size() != 1:
		failures.append("Test 1: expected 1 weapon unlocked by default, got %d" % GameState.weapons_unlocked.size())
	elif GameState.weapons_unlocked[0] != "blade_iron":
		failures.append("Test 1: expected default weapon 'blade_iron', got '%s'" % GameState.weapons_unlocked[0])

	# Test 2: unlock_weapon("polearm_iron") adds to weapons_unlocked, returns true
	GameState.apply_save_state(GameState.default_save_state())
	var result: bool = GameState.unlock_weapon("polearm_iron")
	if not result:
		failures.append("Test 2: unlock_weapon should return true for new weapon, got false")
	if "polearm_iron" not in GameState.weapons_unlocked:
		failures.append("Test 2: 'polearm_iron' not found in weapons_unlocked after unlock")
	if GameState.weapons_unlocked.size() != 2:
		failures.append("Test 2: expected 2 weapons after unlock, got %d" % GameState.weapons_unlocked.size())

	# Test 3: unlock_weapon("polearm_iron") called again returns false (already owned)
	var result2: bool = GameState.unlock_weapon("polearm_iron")
	if result2:
		failures.append("Test 3: unlock_weapon should return false for already-owned weapon, got true")
	if GameState.weapons_unlocked.size() != 2:
		failures.append("Test 3: weapons_unlocked size should still be 2 after duplicate unlock, got %d" % GameState.weapons_unlocked.size())

	# Test 4: spend_xp(150) deducts from banked_xp; spend_xp(9999) floors at 0 (no negative)
	GameState.apply_save_state(GameState.default_save_state())
	GameState.banked_xp = 200
	GameState.spend_xp(150)
	if GameState.banked_xp != 50:
		failures.append("Test 4: expected banked_xp==50 after spend_xp(150), got %d" % GameState.banked_xp)
	GameState.spend_xp(9999)
	if GameState.banked_xp != 0:
		failures.append("Test 4: expected banked_xp==0 after over-spend, got %d" % GameState.banked_xp)
	if GameState.banked_xp < 0:
		failures.append("Test 4: banked_xp went negative: %d" % GameState.banked_xp)

	# Test 5: can_afford_weapon_unlock(cost) returns correct true/false
	GameState.apply_save_state(GameState.default_save_state())
	GameState.banked_xp = 100
	if not GameState.can_afford_weapon_unlock(100):
		failures.append("Test 5: can_afford_weapon_unlock(100) should be true when banked_xp==100")
	if not GameState.can_afford_weapon_unlock(50):
		failures.append("Test 5: can_afford_weapon_unlock(50) should be true when banked_xp==100")
	if GameState.can_afford_weapon_unlock(101):
		failures.append("Test 5: can_afford_weapon_unlock(101) should be false when banked_xp==100")

	if failures.is_empty():
		print("PASS: test_weapon_unlock")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
