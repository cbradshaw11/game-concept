## M19 Test: Warden phase transition signals fire at correct HP thresholds.
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Setup: Warden boss — 1200 HP, 3 phases, 18 base damage ─────────────
	var boss := EnemyController.new(1200, 4.0, 1.5, 18)
	boss.setup_boss(3, 2.5)

	# ── T1: Phase 1 at full HP ──────────────────────────────────────────────
	if boss.get_boss_phase() == 1:
		print("PASS: Warden starts at phase 1")
		checks_passed += 1
	else:
		printerr("FAIL: expected phase 1, got %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T2: No phase change above 70% ──────────────────────────────────────
	# Deal 359 damage → 841 HP (70.08% — still above threshold)
	boss.apply_damage(359)
	if boss.get_boss_phase() == 1:
		print("PASS: still phase 1 at 841 HP (>70%%)")
		checks_passed += 1
	else:
		printerr("FAIL: expected phase 1 at 841 HP, got %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T3: Phase 2 at exactly 70% ─────────────────────────────────────────
	boss.apply_damage(1)  # 840 HP = exactly 70%
	if boss.get_boss_phase() == 2:
		print("PASS: phase 2 triggered at 840 HP (70%%)")
		checks_passed += 1
	else:
		printerr("FAIL: expected phase 2 at 840 HP, got %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T4: No phase change above 35% ──────────────────────────────────────
	# Current: 840 HP. Deal 419 → 421 HP (35.08%)
	boss.apply_damage(419)
	if boss.get_boss_phase() == 2:
		print("PASS: still phase 2 at 421 HP (>35%%)")
		checks_passed += 1
	else:
		printerr("FAIL: expected phase 2 at 421 HP, got %d" % boss.get_boss_phase())
		checks_failed += 1

	# ── T5: Phase 3 at exactly 35% ─────────────────────────────────────────
	boss.apply_damage(1)  # 420 HP = exactly 35%
	if boss.get_boss_phase() == 3:
		print("PASS: phase 3 triggered at 420 HP (35%%)")
		checks_passed += 1
	else:
		printerr("FAIL: expected phase 3 at 420 HP, got %d (hp=%d)" % [boss.get_boss_phase(), boss.health])
		checks_failed += 1

	# ── T6: Phase 3 damage scaling is correct (+50%) ───────────────────────
	var expected_p3_dmg := int(round(18.0 * 1.50))
	if boss.damage == expected_p3_dmg:
		print("PASS: phase 3 damage is %d" % expected_p3_dmg)
		checks_passed += 1
	else:
		printerr("FAIL: phase 3 damage should be %d, got %d" % [expected_p3_dmg, boss.damage])
		checks_failed += 1

	# ── T7: Phase 3 cooldown scaling is correct (×0.6) ─────────────────────
	var expected_p3_cd := 2.5 * 0.6
	if absf(boss.attack_cooldown - expected_p3_cd) < 0.01:
		print("PASS: phase 3 cooldown is %.1f" % expected_p3_cd)
		checks_passed += 1
	else:
		printerr("FAIL: phase 3 cooldown should be %.1f, got %.2f" % [expected_p3_cd, boss.attack_cooldown])
		checks_failed += 1

	# ── T8: Boss death at 0 HP ──────────────────────────────────────────────
	boss.apply_damage(9999)
	if boss.state == EnemyController.EnemyState.DEAD:
		print("PASS: Warden dead after lethal damage")
		checks_passed += 1
	else:
		printerr("FAIL: Warden should be DEAD, got %s" % EnemyController.state_name(boss.state))
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M19 phase transition test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M19 phase transition test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
