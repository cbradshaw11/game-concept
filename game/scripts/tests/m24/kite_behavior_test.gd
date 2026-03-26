## M24 Test: Kite behavior — retreat when player close, melee fallback when cornered
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── Kiter retreats when player is within retreat_distance ─────────────
	var kiter := EnemyController.new(58, 6.0, 1.8, 10)
	kiter.apply_profile(Profiles.KITE_VOLLEY)

	# Player at distance 2.0 (< retreat_distance 3.0) — should retreat
	var did_attack := kiter.tick(2.0, 0.016)
	if kiter.state == EnemyController.EnemyState.RETREAT and not did_attack:
		print("PASS: kiter retreats when player distance (2.0) < retreat_distance (3.0)")
		passed += 1
	else:
		printerr("FAIL: kiter did not retreat — state=%s attack=%s" % [EnemyController.state_name(kiter.state), did_attack])
		failed += 1

	# Player at distance 4.5 (between retreat and attack range) — should attack
	kiter.state = EnemyController.EnemyState.IDLE
	kiter._attack_timer = 0.0
	var did_attack_mid := kiter.tick(4.5, 0.016)
	if kiter.state == EnemyController.EnemyState.ATTACK and did_attack_mid:
		print("PASS: kiter attacks when player at distance 4.5 (within attack_range 5.0)")
		passed += 1
	else:
		printerr("FAIL: kiter at 4.5 — state=%s attack=%s" % [EnemyController.state_name(kiter.state), did_attack_mid])
		failed += 1

	# Player at distance 6.0 (within chase range but outside attack range) — should chase
	kiter.state = EnemyController.EnemyState.IDLE
	kiter.tick(6.0, 0.016)
	if kiter.state == EnemyController.EnemyState.CHASE:
		print("PASS: kiter chases when player at distance 6.0 (within chase_range 8.0)")
		passed += 1
	else:
		printerr("FAIL: kiter at 6.0 — state=%s" % EnemyController.state_name(kiter.state))
		failed += 1

	# ─── Melee fallback switches to close-range stats ─────────────────────
	var kiter2 := EnemyController.new(58, 6.0, 1.8, 10)
	kiter2.apply_profile(Profiles.KITE_VOLLEY)
	kiter2.enter_melee_fallback()

	if kiter2.attack_range == 1.5 and kiter2.attack_cooldown == 1.0:
		print("PASS: melee fallback sets attack_range=1.5 and cooldown=1.0")
		passed += 1
	else:
		printerr("FAIL: melee fallback — attack_range=%s cooldown=%s" % [kiter2.attack_range, kiter2.attack_cooldown])
		failed += 1

	# During melee fallback, should NOT retreat even if player is close
	kiter2._attack_timer = 0.0
	var did_attack_fallback := kiter2.tick(1.0, 0.016)
	if kiter2.state != EnemyController.EnemyState.RETREAT:
		print("PASS: kiter in melee fallback does NOT retreat when player is close")
		passed += 1
	else:
		printerr("FAIL: kiter retreated during melee fallback")
		failed += 1

	# ─── Melee fallback expires after 2 seconds ──────────────────────────
	var kiter3 := EnemyController.new(58, 6.0, 1.8, 10)
	kiter3.apply_profile(Profiles.KITE_VOLLEY)
	kiter3.enter_melee_fallback()

	# Simulate 2.1 seconds passing
	kiter3.tick(4.0, 2.1)
	if kiter3.attack_range == 5.0 and kiter3.attack_cooldown == 2.5:
		print("PASS: melee fallback expires after 2s — kite stats restored")
		passed += 1
	else:
		printerr("FAIL: melee fallback did not expire — attack_range=%s cooldown=%s" % [kiter3.attack_range, kiter3.attack_cooldown])
		failed += 1

	# After fallback expires, should retreat again when player close
	kiter3._attack_timer = 0.0
	kiter3.tick(2.0, 0.016)
	if kiter3.state == EnemyController.EnemyState.RETREAT:
		print("PASS: kiter resumes retreat behavior after fallback expires")
		passed += 1
	else:
		printerr("FAIL: kiter did not retreat after fallback expired — state=%s" % EnemyController.state_name(kiter3.state))
		failed += 1

	# ─── enter_melee_fallback is no-op for non-kiters ────────────────────
	var grunt := EnemyController.new(52, 5.0, 1.5, 8)
	grunt.apply_profile(Profiles.FRONTLINE_BASIC)
	grunt.enter_melee_fallback()
	if grunt.attack_range == 1.5 and grunt.attack_cooldown == 1.5:
		print("PASS: enter_melee_fallback is no-op for non-kite profiles")
		passed += 1
	else:
		printerr("FAIL: enter_melee_fallback changed non-kiter stats")
		failed += 1

	# ─── Summary ──────────────────────────────────────────────────────────
	print("")
	print("kite_behavior_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
