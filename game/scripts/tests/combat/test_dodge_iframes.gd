extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")

func _initialize() -> void:
	var harness := Node.new()
	get_root().add_child(harness)

	var player := PlayerController.new()
	harness.add_child(player)

	# TC1: take_damage during i-frame window — HP unchanged, attack_evaded emitted
	player.is_invulnerable = true
	var evaded_fired := false
	player.attack_evaded.connect(func() -> void:
		evaded_fired = true
	)
	var hp_before := player.current_health
	player.take_damage(20)
	var hp_after := player.current_health
	if hp_after != hp_before:
		_fail("TC1: HP should be unchanged during i-frame, was %d before and %d after" % [hp_before, hp_after])
		return
	if not evaded_fired:
		_fail("TC1: attack_evaded should fire when take_damage called during i-frame")
		return

	# TC2: take_damage outside i-frame window — HP reduced normally
	player.is_invulnerable = false
	player.current_health = player.max_health
	hp_before = player.current_health
	player.take_damage(15)
	hp_after = player.current_health
	if hp_after != hp_before - 15:
		_fail("TC2: HP should decrease by 15 outside i-frame, got %d before, %d after" % [hp_before, hp_after])
		return

	# TC3: dodge cooldown blocks a second immediate try_dodge call
	# Reset state: ensure stamina is full, not staggered, no cooldown
	player.stamina = float(player.max_stamina)
	player.is_staggered = false
	player.dodge_cooldown_timer = 0.0

	var first_dodge := player.try_dodge()
	if not first_dodge:
		_fail("TC3: first try_dodge() should succeed when cooldown is clear")
		return
	# dodge_cooldown_timer is now set to dodge_cooldown_duration by _start_iframe_window
	if player.dodge_cooldown_timer <= 0.0:
		_fail("TC3: dodge_cooldown_timer should be set after a successful dodge")
		return
	var second_dodge := player.try_dodge()
	if second_dodge:
		_fail("TC3: second try_dodge() should be blocked while cooldown is active")
		return

	print("PASS: dodge_iframes — i-frame blocks damage, normal damage outside, cooldown blocks spam")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
