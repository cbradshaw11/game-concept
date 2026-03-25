extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var enemy := EnemyController.new(100, 6.0, 1.8)

	enemy.tick(10.0, 0.016)
	if enemy.state != EnemyController.EnemyState.IDLE:
		_fail("Expected IDLE at far distance")
		return

	enemy.tick(4.0, 0.016)
	if enemy.state != EnemyController.EnemyState.CHASE:
		_fail("Expected CHASE in chase range")
		return

	enemy.tick(1.0, 0.016)
	if enemy.state != EnemyController.EnemyState.ATTACK:
		_fail("Expected ATTACK in attack range")
		return

	enemy.apply_damage(5, true)
	if enemy.state != EnemyController.EnemyState.STAGGER:
		_fail("Expected STAGGER on poise break")
		return

	enemy.tick(3.0, 0.7)
	if enemy.state != EnemyController.EnemyState.CHASE:
		_fail("Expected CHASE after stagger expires")
		return

	enemy.apply_damage(999)
	if enemy.state != EnemyController.EnemyState.DEAD:
		_fail("Expected DEAD on lethal damage")
		return

	print("PASS: enemy state transition test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
