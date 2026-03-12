extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Test 1: flank_aggressive profile — within attack_range, enemy reaches ATTACK state
	# _init(max_health, chase_distance, attack_distance, p_damage)
	var enemy := EnemyController.new(100, 5.0, 2.0, 10)
	enemy.attack_cooldown = 0.1
	var result_state: EnemyController.EnemyState = EnemyController.EnemyState.IDLE
	for i in range(20):
		result_state = enemy.tick(1.5, 0.1)
	if result_state == EnemyController.EnemyState.ATTACK:
		passed += 1
	else:
		print("FAIL: enemy should reach ATTACK state at distance 1.5 within attack_range 2.0, got %s" % EnemyController.state_name(result_state))
		failed += 1

	# Test 2: enemy in CHASE state when beyond attack_range but within chase_range
	var chaser := EnemyController.new(100, 8.0, 1.5, 10)
	var chase_state: EnemyController.EnemyState = EnemyController.EnemyState.IDLE
	for i in range(5):
		chase_state = chaser.tick(4.0, 0.1)
	if chase_state == EnemyController.EnemyState.CHASE:
		passed += 1
	else:
		print("FAIL: enemy should be in CHASE state at distance 4.0 (beyond attack_range 1.5, within chase_range 8.0), got %s" % EnemyController.state_name(chase_state))
		failed += 1

	# Test 3: kite_volley profile — preferred_min_range blocks attack when too close
	# attack only fires when distance >= preferred_min_range
	var kite := EnemyController.new(100, 10.0, 5.0, 8)
	kite.preferred_min_range = 1.5
	kite.attack_cooldown = 0.1
	var kite_close_state: EnemyController.EnemyState = EnemyController.EnemyState.IDLE
	for i in range(20):
		kite_close_state = kite.tick(0.5, 0.1)
	if kite_close_state != EnemyController.EnemyState.ATTACK:
		passed += 1
	else:
		print("FAIL: kite enemy should NOT attack at distance 0.5 (below preferred_min_range 1.5)")
		failed += 1

	# Test 4: kite_volley profile — attacks at distance within range bounds
	var kite2 := EnemyController.new(100, 10.0, 5.0, 8)
	kite2.preferred_min_range = 1.5
	kite2.attack_cooldown = 0.1
	var kite_far_state: EnemyController.EnemyState = EnemyController.EnemyState.IDLE
	for i in range(20):
		kite_far_state = kite2.tick(3.0, 0.1)
	if kite_far_state == EnemyController.EnemyState.ATTACK:
		passed += 1
	else:
		print("FAIL: kite enemy should ATTACK at distance 3.0 (between min_range 1.5 and attack_range 5.0), got %s" % EnemyController.state_name(kite_far_state))
		failed += 1

	# Test 5: Dead enemy stays DEAD regardless of tick calls
	var dead_enemy := EnemyController.new(100, 5.0, 2.0, 10)
	dead_enemy.apply_damage(100)
	var dead_state: EnemyController.EnemyState = dead_enemy.tick(0.5, 0.1)
	if dead_state == EnemyController.EnemyState.DEAD:
		passed += 1
	else:
		print("FAIL: dead enemy should remain in DEAD state, got %s" % EnemyController.state_name(dead_state))
		failed += 1

	if failed == 0:
		print("PASS: test_behavior_profiles")
		quit(0)
	else:
		print("FAIL: %d tests failed" % failed)
		quit(1)
