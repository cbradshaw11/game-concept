extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- last_rites: survives first lethal hit at 1 HP ---
	GameState.apply_save_state(GameState.default_save_state())
	GameState.active_upgrades = []
	GameState.active_modifiers = []
	var player := PlayerController.new()
	player.max_health = 100
	player.current_health = 50
	player.apply_modifier({"id": "last_rites"})
	if not player._last_rites_available:
		failures.append("Test 1: _last_rites_available should be true after apply_modifier")

	# Deal fatal damage (more than current HP)
	var death_fired: bool = false
	player.player_died.connect(func(): death_fired = true)
	player.take_damage(200)  # Way over current HP

	# Should survive at 1 HP
	if player.current_health != 1:
		failures.append("Test 2 (survive lethal): expected current_health=1, got %d" % player.current_health)
	if death_fired:
		failures.append("Test 3 (no death on first lethal): player_died should NOT fire on first lethal hit")
	if player._last_rites_available:
		failures.append("Test 4 (consumed): _last_rites_available should be false after use")

	# --- Second lethal hit kills ---
	player.take_damage(200)
	if player.current_health != 0:
		failures.append("Test 5 (second lethal): expected current_health=0 after second lethal, got %d" % player.current_health)
	if not death_fired:
		failures.append("Test 6 (death on second lethal): player_died should fire on second lethal hit")

	player.queue_free()

	if failures.is_empty():
		print("PASS: test_last_rites_survival")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
