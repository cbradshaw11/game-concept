## M30 Test: Resonance Wraith phase cycling — damage immunity while invulnerable,
## takes damage while vulnerable, phase timer advances, cycle repeats
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── Profile applies correct ranges ─────────────────────────────────
	var w := EnemyController.new(95, 6.0, 1.8, 18)
	w.apply_profile(Profiles.PHASE_PHANTOM)
	if w.chase_range == 7.0 and w.attack_range == 1.8 and w.attack_cooldown == 1.2:
		print("PASS: phase_phantom sets correct chase/attack ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: phase_phantom ranges — chase=%s attack=%s cooldown=%s" % [w.chase_range, w.attack_range, w.attack_cooldown])
		failed += 1

	# ─── Starts invulnerable ────────────────────────────────────────────
	if not w.is_vulnerable:
		print("PASS: phase_phantom starts invulnerable")
		passed += 1
	else:
		printerr("FAIL: phase_phantom should start invulnerable, got is_vulnerable=%s" % w.is_vulnerable)
		failed += 1

	# ─── Damage absorbed while invulnerable ─────────────────────────────
	var pre_hp := w.health
	w.apply_damage(40, true)
	if w.health == pre_hp:
		print("PASS: damage absorbed while invulnerable (health unchanged at %d)" % w.health)
		passed += 1
	else:
		printerr("FAIL: health changed while invulnerable — was %d, now %d" % [pre_hp, w.health])
		failed += 1

	# ─── Phase timer advances and transitions to vulnerable ─────────────
	w.set_phase_durations(2.5, 1.8)
	# Simulate enough ticks to exhaust invulnerable phase (2.5s)
	var total_ticked := 0.0
	var tick_delta := 0.1
	while total_ticked < 2.6:
		w.tick(3.0, tick_delta)
		total_ticked += tick_delta
	if w.is_vulnerable:
		print("PASS: phase transitions to vulnerable after phase_duration expires")
		passed += 1
	else:
		printerr("FAIL: should be vulnerable after 2.6s of ticking, is_vulnerable=%s phase_timer=%s" % [w.is_vulnerable, w.phase_timer])
		failed += 1

	# ─── Takes damage while vulnerable ──────────────────────────────────
	pre_hp = w.health
	w.apply_damage(30, false)
	if w.health == pre_hp - 30:
		print("PASS: takes damage while vulnerable (health %d → %d)" % [pre_hp, w.health])
		passed += 1
	else:
		printerr("FAIL: damage not applied while vulnerable — expected %d, got %d" % [pre_hp - 30, w.health])
		failed += 1

	# ─── Phase cycles back to invulnerable ──────────────────────────────
	total_ticked = 0.0
	while total_ticked < 1.9:
		w.tick(3.0, tick_delta)
		total_ticked += tick_delta
	if not w.is_vulnerable:
		print("PASS: phase cycles back to invulnerable after vulnerable_duration")
		passed += 1
	else:
		printerr("FAIL: should be invulnerable after vulnerable phase expires, is_vulnerable=%s" % w.is_vulnerable)
		failed += 1

	# ─── Damage absorbed again after cycling back ───────────────────────
	pre_hp = w.health
	w.apply_damage(20, false)
	if w.health == pre_hp:
		print("PASS: damage absorbed again after cycling back to invulnerable")
		passed += 1
	else:
		printerr("FAIL: health changed in second invulnerable phase — was %d, now %d" % [pre_hp, w.health])
		failed += 1

	# ─── Wraith can die during vulnerable window ────────────────────────
	var w2 := EnemyController.new(30, 6.0, 1.8, 18)
	w2.apply_profile(Profiles.PHASE_PHANTOM)
	w2.is_vulnerable = true
	w2.apply_damage(30, false)
	if w2.state == EnemyController.EnemyState.DEAD:
		print("PASS: wraith can be killed during vulnerable window")
		passed += 1
	else:
		printerr("FAIL: wraith should be dead after lethal hit while vulnerable, state=%s" % EnemyController.state_name(w2.state))
		failed += 1

	# ─── Wraith still attacks while invulnerable ────────────────────────
	var w3 := EnemyController.new(95, 6.0, 1.8, 18)
	w3.apply_profile(Profiles.PHASE_PHANTOM)
	# Ensure not vulnerable
	w3.is_vulnerable = false
	w3.phase_timer = 10.0  # won't transition during test
	# Tick with player in attack range, cooldown should fire
	var did_attack := false
	for i in 20:
		if w3.tick(1.0, 0.2):
			did_attack = true
			break
	if did_attack:
		print("PASS: wraith attacks while invulnerable")
		passed += 1
	else:
		printerr("FAIL: wraith did not attack while invulnerable")
		failed += 1

	# ─── Summary ────────────────────────────────────────────────────────
	print("")
	print("wraith_phase_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
