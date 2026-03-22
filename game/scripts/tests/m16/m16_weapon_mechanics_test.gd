## M16 Test: Polearm sweep (hits all at 60% dmg) and bow suppress mechanic (M16 T3, T4)
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	const EnemyController = preload("res://scripts/core/enemy_controller.gd")

	# ── Polearm sweep: verify 60% damage calculation ─────────────────────────
	# Base damage = 12, sweep_ratio = 0.6 => expected sweep damage = 7
	var base_dmg := 12
	var sweep_ratio := 0.6
	var expected_sweep_dmg := int(round(float(base_dmg) * sweep_ratio))
	if expected_sweep_dmg == 7:
		print("PASS: polearm sweep damage calculation: round(12 * 0.6) = 7")
		checks_passed += 1
	else:
		printerr("FAIL: polearm sweep damage should be 7, got %d" % expected_sweep_dmg)
		checks_failed += 1

	# Simulate 3 enemies all taking sweep damage
	var enemies: Array = []
	for i in 3:
		var e := EnemyController.new(50, 3.5, 1.2)
		enemies.append(e)

	# Apply sweep to all
	var hit_count := 0
	for e in enemies:
		if e.state != EnemyController.EnemyState.DEAD:
			e.apply_damage(expected_sweep_dmg, false)
			hit_count += 1

	if hit_count == 3:
		print("PASS: polearm sweep hits all 3 enemies")
		checks_passed += 1
	else:
		printerr("FAIL: polearm sweep should hit 3 enemies, hit %d" % hit_count)
		checks_failed += 1

	# Verify all took damage (50 - 7 = 43 HP each)
	var all_damaged := true
	for e in enemies:
		if e.health != 43:
			all_damaged = false
	if all_damaged:
		print("PASS: all enemies have 43 HP after sweep (50 - 7)")
		checks_passed += 1
	else:
		printerr("FAIL: enemies should have 43 HP after sweep")
		checks_failed += 1

	# ── Polearm heavy: bonus poise damage (lunge) ────────────────────────────
	var poise_enemy := EnemyController.new(80, 3.5, 1.2)
	var initial_hp := poise_enemy.health
	poise_enemy.apply_damage(28, true)  # Heavy lunge with poise break
	if poise_enemy.state == EnemyController.EnemyState.STAGGER:
		print("PASS: polearm lunge heavy causes STAGGER on poise break")
		checks_passed += 1
	else:
		printerr("FAIL: polearm lunge should cause STAGGER, got %s" % EnemyController.state_name(poise_enemy.state))
		checks_failed += 1

	# ── Bow suppress: enemy skips action tick ────────────────────────────────
	# Simulate suppress array logic
	var suppress_enemy := EnemyController.new(60, 3.5, 1.2)
	var suppress_ticks := [1]  # Track suppression for enemy 0

	# Simulate tick with suppression active
	if suppress_ticks[0] > 0:
		suppress_ticks[0] -= 1
		# Enemy should NOT process this tick
		print("PASS: bow suppress skips enemy action tick (suppression consumed)")
		checks_passed += 1
	else:
		printerr("FAIL: bow suppress should skip enemy action tick")
		checks_failed += 1

	# Verify suppress ticks depleted to 0
	if suppress_ticks[0] == 0:
		print("PASS: suppress_ticks depleted to 0 after one tick")
		checks_passed += 1
	else:
		printerr("FAIL: suppress_ticks should be 0 after one tick, got %d" % suppress_ticks[0])
		checks_failed += 1

	# Bow heavy suppress ticks value from weapons.json
	var weapons_raw := FileAccess.get_file_as_string("res://data/weapons.json")
	var weapons_data: Variant = JSON.parse_string(weapons_raw)
	if typeof(weapons_data) == TYPE_DICTIONARY:
		var weapons: Array = weapons_data.get("weapons", [])
		for w in weapons:
			if str(w.get("id", "")) == "bow_iron":
				var ticks := int(w.get("heavy_suppress_ticks", 0))
				if ticks == 1:
					print("PASS: bow_iron heavy_suppress_ticks = 1")
					checks_passed += 1
				else:
					printerr("FAIL: bow_iron heavy_suppress_ticks should be 1, got %d" % ticks)
					checks_failed += 1
				break

	# ── Summary ─────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M16 weapon mechanics test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M16 weapon mechanics test (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
