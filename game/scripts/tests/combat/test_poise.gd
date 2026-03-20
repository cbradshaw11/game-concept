extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var harness := Node.new()
	get_root().add_child(harness)

	var player := PlayerController.new()
	harness.add_child(player)

	# Verify poise initialized to max_poise (100 from weapons.json global_combat)
	if player.max_poise != 100:
		_fail("max_poise should be 100 from weapons.json global_combat, got %d" % player.max_poise)
		return
	if player.current_poise != player.max_poise:
		_fail("current_poise should equal max_poise on init, got %d" % player.current_poise)
		return

	# poise_changed signal fires when take_poise_damage is called
	var poise_current_received := -1
	var poise_max_received := -1
	player.poise_changed.connect(func(current: int, maximum: int) -> void:
		poise_current_received = current
		poise_max_received = maximum
	)
	player.take_poise_damage(30)
	if poise_current_received != 70 or poise_max_received != 100:
		_fail("poise_changed should emit (70, 100) after 30 poise damage, got (%d, %d)" % [poise_current_received, poise_max_received])
		return

	# player_staggered fires when poise reaches 0
	var staggered_fired := false
	player.player_staggered.connect(func() -> void:
		staggered_fired = true
	)
	# Drain remaining poise (70 left) to trigger stagger
	player.take_poise_damage(70)
	if not staggered_fired:
		_fail("player_staggered should fire when poise reaches 0")
		return
	if not player.is_staggered:
		_fail("is_staggered should be true immediately after stagger triggers")
		return

	# Actions are blocked during stagger
	var attack_result := player.try_attack()
	if attack_result:
		_fail("try_attack() should return false while staggered")
		return
	var dodge_result := player.try_dodge()
	if dodge_result:
		_fail("try_dodge() should return false while staggered")
		return

	# Additional poise damage is ignored while staggered
	var extra_signal_fired := false
	player.poise_changed.connect(func(_c: int, _m: int) -> void:
		extra_signal_fired = true
	)
	player.take_poise_damage(50)
	if extra_signal_fired:
		_fail("take_poise_damage should be ignored while is_staggered is true")
		return

	# Wait for stagger to resolve (stagger_duration 0.5s + 0.2s buffer)
	await create_timer(0.7).timeout

	if player.is_staggered:
		_fail("is_staggered should be false after stagger_duration elapses")
		return
	if player.current_poise != player.max_poise:
		_fail("current_poise should reset to max_poise after stagger, got %d" % player.current_poise)
		return

	print("PASS: poise damage, stagger, and recovery test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
