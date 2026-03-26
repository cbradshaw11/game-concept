## M30 Test: Resonance Wraith signals — damage_absorbed, phase_vulnerable, phase_invulnerable
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── damage_absorbed emitted when hit while invulnerable ────────────
	var w := EnemyController.new(95, 6.0, 1.8, 18)
	w.apply_profile(Profiles.PHASE_PHANTOM)
	var absorbed_tracker := [0]
	w.damage_absorbed.connect(func(): absorbed_tracker[0] += 1)
	w.apply_damage(40, true)
	if absorbed_tracker[0] == 1:
		print("PASS: damage_absorbed emitted once when hit while invulnerable")
		passed += 1
	else:
		printerr("FAIL: damage_absorbed count=%d, expected 1" % absorbed_tracker[0])
		failed += 1

	# Second hit also emits
	w.apply_damage(20, false)
	if absorbed_tracker[0] == 2:
		print("PASS: damage_absorbed emitted again on second hit while invulnerable")
		passed += 1
	else:
		printerr("FAIL: damage_absorbed count=%d after second hit, expected 2" % absorbed_tracker[0])
		failed += 1

	# ─── damage_absorbed NOT emitted when hit while vulnerable ──────────
	var w2 := EnemyController.new(95, 6.0, 1.8, 18)
	w2.apply_profile(Profiles.PHASE_PHANTOM)
	w2.is_vulnerable = true
	var absorbed_tracker2 := [0]
	w2.damage_absorbed.connect(func(): absorbed_tracker2[0] += 1)
	w2.apply_damage(20, false)
	if absorbed_tracker2[0] == 0:
		print("PASS: damage_absorbed NOT emitted when hit while vulnerable")
		passed += 1
	else:
		printerr("FAIL: damage_absorbed fired while vulnerable, count=%d" % absorbed_tracker2[0])
		failed += 1

	# ─── phase_vulnerable emitted on transition ─────────────────────────
	var w3 := EnemyController.new(95, 6.0, 1.8, 18)
	w3.apply_profile(Profiles.PHASE_PHANTOM)
	w3.set_phase_durations(0.5, 0.3)  # short durations for test
	var vuln_tracker := [0]
	var invuln_tracker := [0]
	w3.phase_vulnerable.connect(func(): vuln_tracker[0] += 1)
	w3.phase_invulnerable.connect(func(): invuln_tracker[0] += 1)
	# Tick past invulnerable phase (0.5s)
	var total := 0.0
	while total < 0.6:
		w3.tick(3.0, 0.05)
		total += 0.05
	if vuln_tracker[0] == 1:
		print("PASS: phase_vulnerable emitted on transition to vulnerable")
		passed += 1
	else:
		printerr("FAIL: phase_vulnerable count=%d, expected 1" % vuln_tracker[0])
		failed += 1

	# ─── phase_invulnerable emitted on transition back ──────────────────
	total = 0.0
	while total < 0.4:
		w3.tick(3.0, 0.05)
		total += 0.05
	if invuln_tracker[0] == 1:
		print("PASS: phase_invulnerable emitted on transition back to invulnerable")
		passed += 1
	else:
		printerr("FAIL: phase_invulnerable count=%d, expected 1" % invuln_tracker[0])
		failed += 1

	# ─── Full cycle: both signals fire once each ────────────────────────
	if vuln_tracker[0] >= 1 and invuln_tracker[0] >= 1:
		print("PASS: full phase cycle fires both signals")
		passed += 1
	else:
		printerr("FAIL: full cycle — vuln=%d invuln=%d" % [vuln_tracker[0], invuln_tracker[0]])
		failed += 1

	# ─── Non-phase_phantom does NOT emit phase signals ──────────────────
	var grunt := EnemyController.new(52, 5.0, 1.5, 8)
	grunt.apply_profile(Profiles.FRONTLINE_BASIC)
	var grunt_absorbed := [0]
	grunt.damage_absorbed.connect(func(): grunt_absorbed[0] += 1)
	grunt.apply_damage(20, false)
	if grunt_absorbed[0] == 0:
		print("PASS: non-phase_phantom does not emit damage_absorbed")
		passed += 1
	else:
		printerr("FAIL: frontline_basic emitted damage_absorbed — count=%d" % grunt_absorbed[0])
		failed += 1

	# ─── Summary ────────────────────────────────────────────────────────
	print("")
	print("wraith_signal_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
