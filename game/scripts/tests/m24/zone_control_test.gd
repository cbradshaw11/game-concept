## M24 Test: Zone control — zone_active flag after attack, proximity damage, zone expiry
extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── Zone activates after attack ─────────────────────────────────────
	var zc := EnemyController.new(65, 6.0, 4.0, 14)
	zc.apply_profile(Profiles.ZONE_CONTROL)

	# Verify zone starts inactive
	if not zc.zone_active:
		print("PASS: zone_active starts false")
		passed += 1
	else:
		printerr("FAIL: zone_active should start false")
		failed += 1

	# Trigger an attack (distance within attack_range, cooldown ready)
	zc._attack_timer = 0.0
	var did_attack := zc.tick(3.5, 0.016)
	if did_attack and zc.zone_active:
		print("PASS: zone_active becomes true after attack")
		passed += 1
	else:
		printerr("FAIL: zone not activated — did_attack=%s zone_active=%s" % [did_attack, zc.zone_active])
		failed += 1

	# ─── Zone proximity damage applies when player in radius ─────────────
	var zone_dmg := zc.get_zone_damage(2.0, 1.0)  # distance 2.0 < radius 2.5, 1 second
	if zone_dmg == 4.0:
		print("PASS: zone proximity damage = 4.0 per second at distance 2.0")
		passed += 1
	else:
		printerr("FAIL: zone_damage expected 4.0, got %s" % zone_dmg)
		failed += 1

	# ─── Zone proximity damage zero when player outside radius ───────────
	var zone_dmg_far := zc.get_zone_damage(3.0, 1.0)  # distance 3.0 > radius 2.5
	if zone_dmg_far == 0.0:
		print("PASS: zone proximity damage = 0 when player at distance 3.0 (outside radius 2.5)")
		passed += 1
	else:
		printerr("FAIL: expected 0 zone damage at distance 3.0, got %s" % zone_dmg_far)
		failed += 1

	# ─── Zone damage scales with delta ───────────────────────────────────
	var zone_dmg_half := zc.get_zone_damage(2.0, 0.5)
	if zone_dmg_half == 2.0:
		print("PASS: zone damage scales with delta (2.0 at 0.5s)")
		passed += 1
	else:
		printerr("FAIL: zone damage scaling — expected 2.0 got %s" % zone_dmg_half)
		failed += 1

	# ─── Zone expires after 2.5 seconds ──────────────────────────────────
	# Reset zone timer by triggering another attack
	zc._attack_timer = 0.0
	zc.tick(3.5, 0.016)  # attack again, resets zone timer to 2.5

	# Simulate 2.6 seconds of ticks (zone should expire)
	zc.tick(5.0, 2.6)
	if not zc.zone_active:
		print("PASS: zone_active becomes false after 2.5s")
		passed += 1
	else:
		printerr("FAIL: zone_active should be false after 2.6s")
		failed += 1

	# ─── No zone damage when zone is inactive ───────────────────────────
	var dmg_inactive := zc.get_zone_damage(1.0, 1.0)
	if dmg_inactive == 0.0:
		print("PASS: no zone damage when zone is inactive")
		passed += 1
	else:
		printerr("FAIL: expected 0 zone damage when inactive, got %s" % dmg_inactive)
		failed += 1

	# ─── Non-zone-control profile returns zero zone damage ───────────────
	var grunt := EnemyController.new(52, 5.0, 1.5, 8)
	grunt.apply_profile(Profiles.FRONTLINE_BASIC)
	var grunt_zone := grunt.get_zone_damage(1.0, 1.0)
	if grunt_zone == 0.0:
		print("PASS: non-zone_control profile returns 0 zone damage")
		passed += 1
	else:
		printerr("FAIL: non-zone_control returned %s zone damage" % grunt_zone)
		failed += 1

	# ─── Zone at boundary (exactly at radius) ───────────────────────────
	zc._attack_timer = 0.0
	zc.tick(3.5, 0.016)  # reactivate zone
	var dmg_boundary := zc.get_zone_damage(2.5, 1.0)  # exactly at radius
	if dmg_boundary == 4.0:
		print("PASS: zone damage applies at exact boundary distance (2.5)")
		passed += 1
	else:
		printerr("FAIL: boundary zone damage — expected 4.0 got %s" % dmg_boundary)
		failed += 1

	# ─── Summary ─────────────────────────────────────────────────────────
	print("")
	print("zone_control_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()
