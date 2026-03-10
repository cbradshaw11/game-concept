extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var harness := Node.new()
	get_root().add_child(harness)

	var player := PlayerController.new()
	harness.add_child(player)

	var attack_count := 0
	var dodge_count := 0
	var guard_values: Array[bool] = []

	player.attack_triggered.connect(func() -> void:
		attack_count += 1
	)
	player.dodge_triggered.connect(func() -> void:
		dodge_count += 1
	)
	player.guard_changed.connect(func(value: bool) -> void:
		guard_values.append(value)
	)

	player.stamina = 40
	if not player.try_attack():
		_fail("attack should succeed with enough stamina")
		return
	if attack_count != 1:
		_fail("attack hook should fire exactly once")
		return
	if int(player.stamina) != 28:
		_fail("attack should consume attack_cost stamina")
		return

	if not player.try_dodge():
		_fail("dodge should succeed with enough stamina")
		return
	if dodge_count != 1:
		_fail("dodge hook should fire exactly once")
		return
	if int(player.stamina) != 6:
		_fail("dodge should consume dodge_cost stamina")
		return

	if player.try_attack():
		_fail("attack should fail with insufficient stamina")
		return
	if attack_count != 1:
		_fail("failed attack should not emit hook")
		return

	player.set_guarding(true)
	player.set_guarding(false)
	if guard_values.size() != 2 or guard_values[0] != true or guard_values[1] != false:
		_fail("guard hook should track true/false transitions")
		return

	player.regenerate_stamina(10.0)
	if player.stamina != float(player.max_stamina):
		_fail("stamina regen should clamp at max")
		return

	print("PASS: combat hooks and stamina behavior test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
