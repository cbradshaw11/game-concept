extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: Boss at 70% HP triggers phase 2 (attack_cooldown = 0.6)
	# _init(max_health) sets health=1200, initial_health=1200
	var enemy = EnemyController.new(1200, 6.0, 1.8, 10)
	enemy.is_boss = true
	# Set phase 1 cooldown baseline
	enemy.attack_cooldown = 0.8
	# Simulate damage to 840/1200 = 70% — exactly at boundary, hp_ratio > 0.70 is false
	# Use 841 for strictly above 70% (still phase 1), use 840 for exactly 70% (phase 2)
	enemy.health = 840
	enemy._update_boss_phase()
	if enemy.attack_cooldown != 0.6:
		failures.append("Phase 2 not triggered at 70%% HP: expected attack_cooldown=0.6, got %.2f" % enemy.attack_cooldown)

	# Test 2: Boss at 35% HP triggers phase 3 (attack_cooldown = 0.4)
	enemy.health = 420
	enemy._update_boss_phase()
	if enemy.attack_cooldown != 0.4:
		failures.append("Phase 3 not triggered at 35%% HP: expected attack_cooldown=0.4, got %.2f" % enemy.attack_cooldown)

	# Test 3: Non-boss enemy — phase logic does not fire
	var regular = EnemyController.new(100, 6.0, 1.8, 10)
	regular.is_boss = false
	regular.attack_cooldown = 1.5
	regular.health = 10
	regular._update_boss_phase()
	if regular.attack_cooldown != 1.5:
		failures.append("Regular enemy attack_cooldown changed — phase logic must check is_boss")

	if failures.is_empty():
		print("PASS: test_warden_phases")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
