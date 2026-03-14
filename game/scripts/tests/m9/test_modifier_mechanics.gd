extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- ironclad: guard_efficiency += 0.15 (additive) ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var player := PlayerController.new()
	player.guard_efficiency = 0.70
	player.apply_modifier({"id": "ironclad", "value": 0.15})
	if abs(player.guard_efficiency - 0.85) > 0.001:
		failures.append("Test 1 (ironclad): expected guard_efficiency=0.85, got %.4f" % player.guard_efficiency)

	# ironclad on zero-guard weapon must produce 0.15, not 0.0
	player.guard_efficiency = 0.0
	player.apply_modifier({"id": "ironclad", "value": 0.15})
	if abs(player.guard_efficiency - 0.15) > 0.001:
		failures.append("Test 2 (ironclad zero-base): expected guard_efficiency=0.15, got %.4f" % player.guard_efficiency)
	player.queue_free()

	# --- swift: light_stamina_cost_multiplier *= (1 + (-0.20)) = 0.80 ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var player2 := PlayerController.new()
	player2.apply_modifier({"id": "swift", "value": -0.20})
	if abs(player2.light_stamina_cost_multiplier - 0.80) > 0.001:
		failures.append("Test 3 (swift): expected multiplier=0.80, got %.4f" % player2.light_stamina_cost_multiplier)
	player2.queue_free()

	# --- burden: max_stamina -10, xp_gain_multiplier *= 1.25 ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var player3 := PlayerController.new()
	var base_stamina: int = player3.max_stamina  # 100 from export default
	GameState.start_run(1, "inner")  # resets xp_gain_multiplier to 1.0
	player3.apply_modifier({"id": "burden", "value_a": -10, "value_b": 0.25})
	if player3.max_stamina != base_stamina - 10:
		failures.append("Test 4 (burden stamina): expected max_stamina=%d, got %d" % [base_stamina - 10, player3.max_stamina])
	if abs(GameState.xp_gain_multiplier - 1.25) > 0.001:
		failures.append("Test 5 (burden xp): expected xp_gain_multiplier=1.25, got %.4f" % GameState.xp_gain_multiplier)
	player3.queue_free()

	# --- last_rites: sets _last_rites_available = true ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	var player4 := PlayerController.new()
	player4.apply_modifier({"id": "last_rites"})
	if not player4._last_rites_available:
		failures.append("Test 6 (last_rites): expected _last_rites_available=true after apply_modifier")
	player4.queue_free()

	# --- bloodlust: get_effective_attack_damage boosts below 40% HP ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.active_modifiers = [{"id": "bloodlust", "modifier_type": "conditional_damage_pct", "threshold": 0.4, "value": 0.15}]
	var player5 := PlayerController.new()
	player5.max_health = 100
	player5.heavy_damage = 24
	# Above threshold: no bonus
	player5.current_health = 50
	var dmg_above: int = player5.get_effective_attack_damage()
	if dmg_above != 24:
		failures.append("Test 7 (bloodlust above threshold): expected 24, got %d" % dmg_above)
	# Below threshold: +15%
	player5.current_health = 35
	var dmg_below: int = player5.get_effective_attack_damage()
	var expected_below: int = int(24.0 * 1.15)  # = 27
	if dmg_below != expected_below:
		failures.append("Test 8 (bloodlust below threshold): expected %d, got %d" % [expected_below, dmg_below])
	player5.queue_free()
	GameState.active_modifiers = []

	# --- xp_gain_multiplier resets on start_run (burden stacking fix) ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.xp_gain_multiplier = 1.25  # Simulate leftover from previous run
	GameState.start_run(2, "inner")
	if abs(GameState.xp_gain_multiplier - 1.0) > 0.001:
		failures.append("Test 9 (xp reset): expected xp_gain_multiplier=1.0 at run start, got %.4f" % GameState.xp_gain_multiplier)

	if failures.is_empty():
		print("PASS: test_modifier_mechanics")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
