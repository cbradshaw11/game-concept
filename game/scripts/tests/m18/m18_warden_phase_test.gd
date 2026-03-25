## M18 Test: Warden boss phase transitions — verify 70%/35% HP thresholds
## and correct damage/cooldown scaling per phase.
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Setup: create a Warden-like boss ─────────────────────────────────────
	# 1200 HP, 3 phases, 2.5s base cooldown, 18 base damage
	var boss := EnemyController.new(1200, 4.0, 1.5, 18)
	boss.setup_boss(3, 2.5)

	# ── T1: Initial state is phase 1 ────────────────────────────────────────
	if boss.get_boss_phase() == 1:
		print("PASS: boss starts in phase 1")
		checks_passed += 1
	else:
		printerr("FAIL: boss should start in phase 1, got %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T2: is_boss flag set ─────────────────────────────────────────────────
	if boss.is_boss:
		print("PASS: is_boss flag is true")
		checks_passed += 1
	else:
		printerr("FAIL: is_boss should be true")
		checks_failed += 1

	# ── T3: Phase 1 damage is base (18) ────────────────────────────────────
	if boss.damage == 18:
		print("PASS: phase 1 damage is 18 (base)")
		checks_passed += 1
	else:
		printerr("FAIL: phase 1 damage should be 18, got %d" % boss.damage)
		checks_failed += 1

	# ── T4: Phase 1 cooldown is 2.5 ────────────────────────────────────────
	if absf(boss.attack_cooldown - 2.5) < 0.01:
		print("PASS: phase 1 attack_cooldown is 2.5")
		checks_passed += 1
	else:
		printerr("FAIL: phase 1 cooldown should be 2.5, got %.2f" % boss.attack_cooldown)
		checks_failed += 1

	# ── T5: Damage to 70% HP triggers phase 2 ──────────────────────────────
	# 70% of 1200 = 840. Need to drop to 840 or below.
	# Deal 360 damage (1200 - 360 = 840 exactly at boundary)
	boss.apply_damage(360)
	if boss.get_boss_phase() == 2:
		print("PASS: phase 2 triggered at 70%% HP (840/1200)")
		checks_passed += 1
	else:
		printerr("FAIL: should be phase 2 at 840 HP, got phase %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T6: Phase 2 damage = base * 1.25 = 22 (rounded) ───────────────────
	var expected_p2_dmg := int(round(18.0 * 1.25))
	if boss.damage == expected_p2_dmg:
		print("PASS: phase 2 damage is %d (+25%%)" % expected_p2_dmg)
		checks_passed += 1
	else:
		printerr("FAIL: phase 2 damage should be %d, got %d" % [expected_p2_dmg, boss.damage])
		checks_failed += 1

	# ── T7: Phase 2 cooldown = 2.5 * 0.8 = 2.0 ───────────────────────────
	var expected_p2_cd := 2.5 * 0.8
	if absf(boss.attack_cooldown - expected_p2_cd) < 0.01:
		print("PASS: phase 2 cooldown is %.1f" % expected_p2_cd)
		checks_passed += 1
	else:
		printerr("FAIL: phase 2 cooldown should be %.1f, got %.2f" % [expected_p2_cd, boss.attack_cooldown])
		checks_failed += 1

	# ── T8: Damage to 35% HP triggers phase 3 ──────────────────────────────
	# 35% of 1200 = 420. Current HP is 840. Need to deal 420+ more.
	boss.apply_damage(420)
	if boss.get_boss_phase() == 3:
		print("PASS: phase 3 triggered at 35%% HP (420/1200)")
		checks_passed += 1
	else:
		printerr("FAIL: should be phase 3 at 420 HP, got phase %d (hp=%d)" % [boss.get_boss_phase(), boss.health])
		checks_failed += 1

	# ── T9: Phase 3 damage = base * 1.5 = 27 ──────────────────────────────
	var expected_p3_dmg := int(round(18.0 * 1.50))
	if boss.damage == expected_p3_dmg:
		print("PASS: phase 3 damage is %d (+50%%)" % expected_p3_dmg)
		checks_passed += 1
	else:
		printerr("FAIL: phase 3 damage should be %d, got %d" % [expected_p3_dmg, boss.damage])
		checks_failed += 1

	# ── T10: Phase 3 cooldown = 2.5 * 0.6 = 1.5 ──────────────────────────
	var expected_p3_cd := 2.5 * 0.6
	if absf(boss.attack_cooldown - expected_p3_cd) < 0.01:
		print("PASS: phase 3 cooldown is %.1f" % expected_p3_cd)
		checks_passed += 1
	else:
		printerr("FAIL: phase 3 cooldown should be %.1f, got %.2f" % [expected_p3_cd, boss.attack_cooldown])
		checks_failed += 1

	# ── T11: Killing the boss results in DEAD state ────────────────────────
	boss.apply_damage(9999)
	if boss.state == EnemyController.EnemyState.DEAD:
		print("PASS: boss is DEAD after lethal damage")
		checks_passed += 1
	else:
		printerr("FAIL: boss should be DEAD, got %s" % EnemyController.state_name(boss.state))
		checks_failed += 1

	# ── T12: Non-boss enemy has no phase transitions ──────────────────────
	var grunt := EnemyController.new(52, 3.5, 1.2, 8)
	grunt.apply_damage(40)
	if grunt.get_boss_phase() == 1 and not grunt.is_boss:
		print("PASS: non-boss enemy stays phase 1, is_boss=false")
		checks_passed += 1
	else:
		printerr("FAIL: non-boss should have phase 1 and is_boss=false")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M18 warden phase test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M18 warden phase test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
