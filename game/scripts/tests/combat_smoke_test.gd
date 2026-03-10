extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	if packed == null:
		_fail("combat arena scene failed to load")
		return

	var arena := packed.instantiate()
	get_root().add_child(arena)

	var attack_count := 0
	var dodge_count := 0
	var guard_values: Array[bool] = []

	arena.attack_hook_triggered.connect(func() -> void:
		attack_count += 1
	)
	arena.dodge_hook_triggered.connect(func() -> void:
		dodge_count += 1
	)
	arena.guard_hook_changed.connect(func(value: bool) -> void:
		guard_values.append(value)
	)

	arena.set_context("inner", 999)
	arena.set_arena_active(true)

	if not arena.player.try_attack():
		_fail("attack should succeed in smoke flow")
		return
	if not arena.player.try_dodge():
		_fail("dodge should succeed in smoke flow")
		return

	arena.player.set_guarding(true)
	arena.player.set_guarding(false)

	if attack_count != 1 or dodge_count != 1:
		_fail("combat hooks should emit exactly once for attack/dodge")
		return

	if guard_values.size() != 2 or guard_values[0] != true or guard_values[1] != false:
		_fail("guard hook should emit true/false transitions")
		return

	print("PASS: combat smoke test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
