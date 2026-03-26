## M24 Test: Behavior profiles — verify each profile applies correct ranges/cooldowns,
## glass_cannon death_explosion, poise_gate_tank stagger threshold, elite_pressure poise immunity
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── frontline_basic profile ranges ─────────────────────────────────────
	var fb := EnemyController.new(52, 6.0, 1.8, 8)
	fb.apply_profile(Profiles.FRONTLINE_BASIC)
	if fb.chase_range == 5.0 and fb.attack_range == 1.5 and fb.attack_cooldown == 1.5:
		print("PASS: frontline_basic sets correct chase/attack ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: frontline_basic ranges — chase=%s attack=%s cooldown=%s" % [fb.chase_range, fb.attack_range, fb.attack_cooldown])
		failed += 1

	# ─── guard_counter profile ranges ───────────────────────────────────────
	var gc := EnemyController.new(75, 6.0, 1.8, 7)
	gc.apply_profile(Profiles.GUARD_COUNTER)
	if gc.chase_range == 4.0 and gc.attack_range == 1.8 and gc.attack_cooldown == 2.0:
		print("PASS: guard_counter sets correct chase/attack ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: guard_counter ranges — chase=%s attack=%s cooldown=%s" % [gc.chase_range, gc.attack_range, gc.attack_cooldown])
		failed += 1

	# ─── flank_aggressive profile ───────────────────────────────────────────
	var fa := EnemyController.new(72, 6.0, 1.8, 12)
	fa.apply_profile(Profiles.FLANK_AGGRESSIVE)
	if fa.chase_range == 7.0 and fa.attack_range == 1.6 and fa.attack_cooldown == 1.2 and fa.prefers_flank:
		print("PASS: flank_aggressive sets correct ranges and enables flanking")
		passed += 1
	else:
		printerr("FAIL: flank_aggressive — chase=%s attack=%s cooldown=%s flank=%s" % [fa.chase_range, fa.attack_range, fa.attack_cooldown, fa.prefers_flank])
		failed += 1

	# ─── kite_volley profile ────────────────────────────────────────────────
	var kv := EnemyController.new(58, 6.0, 1.8, 10)
	kv.apply_profile(Profiles.KITE_VOLLEY)
	if kv.chase_range == 8.0 and kv.attack_range == 5.0 and kv.attack_cooldown == 2.5 and kv.retreat_distance == 3.0:
		print("PASS: kite_volley sets correct ranges and retreat distance")
		passed += 1
	else:
		printerr("FAIL: kite_volley — chase=%s attack=%s cooldown=%s retreat=%s" % [kv.chase_range, kv.attack_range, kv.attack_cooldown, kv.retreat_distance])
		failed += 1

	# ─── zone_control profile ──────────────────────────────────────────────
	var zc := EnemyController.new(65, 6.0, 1.8, 14)
	zc.apply_profile(Profiles.ZONE_CONTROL)
	if zc.chase_range == 6.0 and zc.attack_range == 4.0 and zc.attack_cooldown == 3.5:
		print("PASS: zone_control sets correct ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: zone_control — chase=%s attack=%s cooldown=%s" % [zc.chase_range, zc.attack_range, zc.attack_cooldown])
		failed += 1

	# ─── glass_cannon_aggro profile + death explosion ──────────────────────
	var gca := EnemyController.new(45, 6.0, 1.8, 22)
	gca.apply_profile(Profiles.GLASS_CANNON_AGGRO)
	if gca.chase_range == 9.0 and gca.attack_range == 1.4 and gca.attack_cooldown == 0.8:
		print("PASS: glass_cannon_aggro sets correct ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: glass_cannon_aggro — chase=%s attack=%s cooldown=%s" % [gca.chase_range, gca.attack_range, gca.attack_cooldown])
		failed += 1

	var explosion_tracker := [false]
	gca.death_explosion.connect(func(): explosion_tracker[0] = true)
	gca.apply_damage(45, false)
	if explosion_tracker[0] and gca.state == EnemyController.EnemyState.DEAD:
		print("PASS: glass_cannon_aggro emits death_explosion on kill")
		passed += 1
	else:
		printerr("FAIL: death_explosion not emitted — fired=%s state=%s" % [explosion_tracker[0], EnemyController.state_name(gca.state)])
		failed += 1

	# Verify non-glass-cannon does NOT emit death_explosion
	var grunt := EnemyController.new(10, 5.0, 1.5, 8)
	grunt.apply_profile(Profiles.FRONTLINE_BASIC)
	var grunt_tracker := [false]
	grunt.death_explosion.connect(func(): grunt_tracker[0] = true)
	grunt.apply_damage(10, false)
	if not grunt_tracker[0]:
		print("PASS: frontline_basic does NOT emit death_explosion on kill")
		passed += 1
	else:
		printerr("FAIL: frontline_basic emitted death_explosion unexpectedly — %s" % grunt_tracker[0])
		failed += 1

	# ─── poise_gate_tank profile + stagger threshold ──────────────────────
	var pgt := EnemyController.new(80, 6.0, 1.8, 8)
	pgt.apply_profile(Profiles.POISE_GATE_TANK)
	if pgt.chase_range == 3.5 and pgt.attack_range == 1.6 and pgt.poise_threshold == 60:
		print("PASS: poise_gate_tank sets correct ranges and poise threshold 60")
		passed += 1
	else:
		printerr("FAIL: poise_gate_tank — chase=%s attack=%s poise_threshold=%d" % [pgt.chase_range, pgt.attack_range, pgt.poise_threshold])
		failed += 1

	# poise_gate_tank should NOT stagger from a single 40-damage hit (threshold 60)
	pgt.state = EnemyController.EnemyState.CHASE
	pgt.apply_damage(40, true)
	if pgt.state != EnemyController.EnemyState.STAGGER:
		print("PASS: poise_gate_tank does NOT stagger from 40 poise damage (threshold 60)")
		passed += 1
	else:
		printerr("FAIL: poise_gate_tank staggered from 40 poise damage, should require 60")
		failed += 1

	# Second hit (40 more = 80 total > 60) should trigger stagger
	pgt.apply_damage(25, true)
	if pgt.state == EnemyController.EnemyState.STAGGER:
		print("PASS: poise_gate_tank staggers after 65 accumulated poise damage (>= 60)")
		passed += 1
	else:
		printerr("FAIL: poise_gate_tank did NOT stagger after 65 accumulated poise damage")
		failed += 1

	# ─── elite_pressure profile + poise immunity ──────────────────────────
	var ep := EnemyController.new(130, 6.0, 1.8, 16)
	ep.apply_profile(Profiles.ELITE_PRESSURE)
	if ep.chase_range == 8.0 and ep.attack_range == 2.0 and ep.attack_cooldown == 1.0:
		print("PASS: elite_pressure sets correct ranges and cooldown")
		passed += 1
	else:
		printerr("FAIL: elite_pressure — chase=%s attack=%s cooldown=%s" % [ep.chase_range, ep.attack_range, ep.attack_cooldown])
		failed += 1

	# elite_pressure should NEVER stagger (poise immune)
	ep.state = EnemyController.EnemyState.CHASE
	ep.apply_damage(40, true)
	if ep.state != EnemyController.EnemyState.STAGGER:
		print("PASS: elite_pressure is immune to poise break (never staggers)")
		passed += 1
	else:
		printerr("FAIL: elite_pressure staggered — should be poise immune")
		failed += 1

	# elite_pressure damage scaling: +20% when player below 50% HP
	ep.set_player_hp_percent(0.4)
	ep._update_elite_pressure_damage()
	var scaled_dmg := ep.damage
	ep.set_player_hp_percent(0.8)
	ep._update_elite_pressure_damage()
	var normal_dmg := ep.damage
	if scaled_dmg == int(round(16.0 * 1.2)) and normal_dmg == 16:
		print("PASS: elite_pressure deals +20%% damage when player below 50%% HP (%d vs %d)" % [scaled_dmg, normal_dmg])
		passed += 1
	else:
		printerr("FAIL: elite_pressure damage scaling — low_hp=%d (expected %d) normal=%d (expected 16)" % [scaled_dmg, int(round(16.0 * 1.2)), normal_dmg])
		failed += 1

	# ─── behavior_profile field set correctly ──────────────────────────────
	var test_profiles := [
		[Profiles.FRONTLINE_BASIC, "frontline_basic"],
		[Profiles.GUARD_COUNTER, "guard_counter"],
		[Profiles.ELITE_PRESSURE, "elite_pressure"],
	]
	var profile_match := true
	for pair in test_profiles:
		var ec := EnemyController.new(50, 5.0, 1.5, 8)
		ec.apply_profile(pair[0])
		if ec.behavior_profile != pair[1]:
			profile_match = false
			break
	if profile_match:
		print("PASS: behavior_profile field stores profile string correctly")
		passed += 1
	else:
		printerr("FAIL: behavior_profile field mismatch")
		failed += 1

	# ─── Summary ───────────────────────────────────────────────────────────
	print("")
	print("behavior_profile_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
