extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	if packed == null:
		_fail("combat arena scene failed to load")
		return

	var arena := packed.instantiate()
	get_root().add_child(arena)

	# Wait one frame so @onready vars and _ready() are populated
	await process_frame

	# Use Array as reference container — GDScript lambda capture is by value for primitives
	var counts := { "attack": 0, "dodge": 0 }
	var guard_values: Array[bool] = []

	arena.attack_hook_triggered.connect(func() -> void:
		counts["attack"] += 1
	)
	arena.dodge_hook_triggered.connect(func() -> void:
		counts["dodge"] += 1
	)
	arena.guard_hook_changed.connect(func(value: bool) -> void:
		guard_values.append(value)
	)

	arena.set_context("inner", 999)
	arena.set_arena_active(true)

	# Snapshot counts after setup (enemies/init may trigger hooks during set_context)
	var offset_attack: int = counts["attack"]
	var offset_dodge: int = counts["dodge"]
	var offset_guard: int = guard_values.size()

	if not arena.player.try_attack():
		_fail("attack should succeed in smoke flow")
		return

	if not arena.player.try_dodge():
		_fail("dodge should succeed in smoke flow")
		return

	arena.player.set_guarding(true)
	arena.player.set_guarding(false)

	var net_attacks: int = counts["attack"] - offset_attack
	var net_dodges: int = counts["dodge"] - offset_dodge

	if net_attacks != 1 or net_dodges != 1:
		_fail("combat hooks should emit exactly once for attack/dodge (got attack=%d dodge=%d)" % [net_attacks, net_dodges])
		return

	var guard_slice := guard_values.slice(offset_guard)
	if guard_slice.size() != 2 or guard_slice[0] != true or guard_slice[1] != false:
		_fail("guard hook should emit true/false transitions (got %s)" % str(guard_slice))
		return

	print("PASS: combat smoke test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
