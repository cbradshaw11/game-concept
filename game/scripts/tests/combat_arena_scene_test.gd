extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	if packed == null:
		_fail("combat arena scene failed to load")
		return

	var arena := packed.instantiate()
	if arena == null:
		_fail("combat arena scene failed to instantiate")
		return

	var player := arena.get_node_or_null("Player")
	if player == null:
		_fail("combat arena must include Player node")
		return

	if not (arena.has_method("set_context") and arena.has_method("set_arena_active")):
		_fail("combat arena should expose run context and activation hooks")
		return

	print("PASS: combat arena scene contract test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
