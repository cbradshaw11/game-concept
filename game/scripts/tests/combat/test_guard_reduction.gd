extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var harness := Node.new()
	get_root().add_child(harness)

	var player := PlayerController.new()
	harness.add_child(player)

	# TC1: guarding=true reduces damage (guard efficiency applied)
	player.guarding = true
	player.guard_efficiency = 0.7
	var hp_before := player.current_health
	player.take_damage(10)
	var hp_after := player.current_health
	var damage_taken := hp_before - hp_after
	if damage_taken >= 10:
		_fail("TC1: guarding should reduce damage below 10, got %d damage taken" % damage_taken)
		return

	# TC2: guarding=false applies full damage
	player.current_health = player.max_health
	player.guarding = false
	hp_before = player.current_health
	player.take_damage(10)
	hp_after = player.current_health
	damage_taken = hp_before - hp_after
	if damage_taken != 10:
		_fail("TC2: no guard should take exactly 10 damage, got %d" % damage_taken)
		return

	# TC3: guarding=true with damage > GUARD_BREAK_THRESHOLD fires guard_broken and drops guard
	player.current_health = player.max_health
	player.guarding = true
	player.guard_efficiency = 0.7
	var guard_broken_fired := false
	player.guard_broken.connect(func() -> void:
		guard_broken_fired = true
	)
	player.take_damage(35)
	if not guard_broken_fired:
		_fail("TC3: guard_broken signal should fire when hit exceeds GUARD_BREAK_THRESHOLD (30)")
		return
	if player.guarding:
		_fail("TC3: guarding should be false after guard break")
		return
	# Remainder damage after break = 35 - 30 = 5 applied at full value
	var expected_hp := player.max_health - (35 - PlayerController.GUARD_BREAK_THRESHOLD)
	if player.current_health != expected_hp:
		_fail("TC3: after guard break, HP should be %d (remainder damage at full), got %d" % [expected_hp, player.current_health])
		return

	print("PASS: guard_reduction — guarded damage, unguarded damage, guard break")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
