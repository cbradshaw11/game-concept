extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	var harness := Node.new()
	get_root().add_child(harness)

	# _ready() calls DataStore and initializes from weapons.json
	# Default selected_weapon_id is "blade_iron" (heavy_stamina_cost=26, heavy_damage=24)
	GameState.selected_weapon_id = "blade_iron"
	var player := PlayerController.new()
	harness.add_child(player)

	# Test 1: heavy_attack() succeeds with sufficient stamina
	player.stamina = 100.0
	player.is_staggered = false
	var result := player.heavy_attack()
	if result == true:
		passed += 1
	else:
		print("FAIL: heavy_attack() should return true with stamina=100")
		failed += 1

	# Test 2: Stamina is reduced by heavy_stamina_cost after successful heavy_attack
	# blade_iron heavy_stamina_cost = 26
	var expected_stamina := 100.0 - player.heavy_stamina_cost
	if absf(player.stamina - expected_stamina) < 0.001:
		passed += 1
	else:
		print("FAIL: stamina should be %.1f after heavy_attack, got %.1f" % [expected_stamina, player.stamina])
		failed += 1

	# Test 3: heavy_attack() fails with insufficient stamina
	player.stamina = 5.0
	var stamina_before := player.stamina
	var fail_result := player.heavy_attack()
	if fail_result == false:
		passed += 1
	else:
		print("FAIL: heavy_attack() should return false when stamina=5 < heavy_stamina_cost")
		failed += 1

	# Test 4: Stamina unchanged after failed heavy_attack
	if absf(player.stamina - stamina_before) < 0.001:
		passed += 1
	else:
		print("FAIL: stamina should be unchanged after failed heavy_attack, got %.1f" % player.stamina)
		failed += 1

	# Test 5: reload_weapon_stats() loads correct heavy_damage for polearm_iron (28)
	GameState.selected_weapon_id = "polearm_iron"
	player.reload_weapon_stats()
	if player.heavy_damage == 28:
		passed += 1
	else:
		print("FAIL: polearm_iron heavy_damage should be 28, got %d" % player.heavy_damage)
		failed += 1

	# Test 6: reload_weapon_stats() loads correct heavy_damage for blade_iron (24)
	GameState.selected_weapon_id = "blade_iron"
	player.reload_weapon_stats()
	if player.heavy_damage == 24:
		passed += 1
	else:
		print("FAIL: blade_iron heavy_damage should be 24, got %d" % player.heavy_damage)
		failed += 1

	# Test 7: heavy_attack_triggered signal emits with correct damage value
	GameState.selected_weapon_id = "blade_iron"
	player.reload_weapon_stats()
	player.stamina = 100.0
	var signal_damage := -1
	player.heavy_attack_triggered.connect(func(dmg: int) -> void:
		signal_damage = dmg
	)
	player.heavy_attack()
	if signal_damage == 24:
		passed += 1
	else:
		print("FAIL: heavy_attack_triggered should emit damage=24 for blade_iron, got %d" % signal_damage)
		failed += 1

	if failed == 0:
		print("PASS: test_heavy_attack")
		quit(0)
	else:
		print("FAIL: %d tests failed" % failed)
		quit(1)
