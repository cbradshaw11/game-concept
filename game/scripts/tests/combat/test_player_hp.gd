extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var harness := Node.new()
	get_root().add_child(harness)

	var player := PlayerController.new()
	harness.add_child(player)

	# Verify health initialized from weapons.json global_combat (max_health = 100)
	if player.max_health != 100:
		_fail("max_health should be 100 from weapons.json global_combat")
		return
	if player.current_health != 100:
		_fail("current_health should equal max_health on init")
		return

	# take_damage reduces HP
	player.take_damage(30)
	if player.current_health != 70:
		_fail("take_damage(30) should reduce health from 100 to 70, got %d" % player.current_health)
		return

	# health_changed signal fires with correct values
	var health_current_received := -1
	var health_max_received := -1
	player.health_changed.connect(func(current: int, maximum: int) -> void:
		health_current_received = current
		health_max_received = maximum
	)
	player.take_damage(10)
	if health_current_received != 60 or health_max_received != 100:
		_fail("health_changed should emit (60, 100), got (%d, %d)" % [health_current_received, health_max_received])
		return

	# player_died fires when HP reaches 0
	var died_fired := false
	player.player_died.connect(func() -> void:
		died_fired = true
	)
	player.take_damage(200)
	if not died_fired:
		_fail("player_died should fire when damage exceeds remaining health")
		return
	if player.current_health != 0:
		_fail("current_health should clamp to 0, got %d" % player.current_health)
		return

	# GameState.die_in_run() clears unbanked rewards
	GameState.unbanked_xp = 500
	GameState.unbanked_loot = 10
	GameState.current_ring = "inner"
	GameState.die_in_run()
	if GameState.unbanked_xp != 250:
		_fail("die_in_run should halve unbanked_xp (500 -> 250), got %d" % GameState.unbanked_xp)
		return
	if GameState.unbanked_loot != 0:
		_fail("die_in_run should clear unbanked_loot, got %d" % GameState.unbanked_loot)
		return

	print("PASS: player HP and death state test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
