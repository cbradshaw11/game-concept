extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	# --- ac1: damage field initialized from constructor ---
	var enemy := EnemyController.new(60, 6.0, 1.8, 8)
	if enemy.damage != 8:
		_fail("damage should be 8 from constructor, got %d" % enemy.damage)
		return

	# --- ac4: attack_resolved signal emits correct damage value ---
	var received_damage := -1
	enemy.attack_resolved.connect(func(amount: int) -> void:
		received_damage = amount
	)
	# First tick inside attack range with cooldown at 0 should emit immediately
	enemy.tick(1.0, 0.016)
	if received_damage != 8:
		_fail("attack_resolved should emit 8, got %d" % received_damage)
		return

	# Cooldown prevents second immediate emit on next tick
	var second_emit := false
	enemy.attack_resolved.connect(func(_amount: int) -> void:
		second_emit = true
	)
	enemy.tick(1.0, 0.016)
	if second_emit:
		_fail("attack_resolved should not emit again before cooldown expires")
		return

	# --- Distinct damage values for different enemy types from enemies.json ---
	var e_grunt := EnemyController.new(60, 6.0, 1.8, 8)
	var e_flanker := EnemyController.new(70, 6.0, 1.8, 12)
	var e_archer := EnemyController.new(55, 6.0, 1.8, 10)
	if e_grunt.damage == e_flanker.damage:
		_fail("scavenger_grunt and ash_flanker should have different damage values")
		return
	if e_flanker.damage == e_archer.damage:
		_fail("ash_flanker and ridge_archer should have different damage values")
		return

	print("PASS: enemy damage output test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
