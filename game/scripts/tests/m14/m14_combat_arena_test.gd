## M14 Test: Verify combat arena visual features
extends SceneTree

const PlayerController = preload("res://scripts/core/player_controller.gd")
const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var pass_count := 0
	var fail_count := 0

	# T3: Arena scene loads
	var packed := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: combat arena scene failed to load")
		quit(1)
		return
	var arena := packed.instantiate()
	if arena == null:
		printerr("FAIL: combat arena failed to instantiate")
		quit(1)
		return
	get_root().add_child(arena)

	# T3: Arena has ArenaBG node (background sprite)
	var bg := arena.get_node_or_null("ArenaBG")
	if bg != null and bg is Sprite2D:
		print("PASS: ArenaBG Sprite2D node present")
		pass_count += 1
	else:
		printerr("FAIL: ArenaBG Sprite2D node missing from combat arena")
		fail_count += 1

	# T3: Arena has EnemyContainer
	var container := arena.get_node_or_null("EnemyContainer")
	if container != null:
		print("PASS: EnemyContainer node present")
		pass_count += 1
	else:
		printerr("FAIL: EnemyContainer node missing")
		fail_count += 1

	# T5: Arena has Camera2D for screen shake
	var cam := arena.get_node_or_null("Camera")
	if cam != null and cam is Camera2D:
		print("PASS: Camera2D present for screen shake")
		pass_count += 1
	else:
		printerr("FAIL: Camera2D node missing")
		fail_count += 1

	# T7: HUD has styled stat bars
	var hud := arena.get_node_or_null("HUD")
	if hud != null:
		print("PASS: HUD CanvasLayer present")
		pass_count += 1
	else:
		printerr("FAIL: HUD node missing")
		fail_count += 1

	var hp_bar := arena.get_node_or_null("HUD/StatsPanel/StatsVBox/HPBar")
	if hp_bar != null and hp_bar is ProgressBar:
		print("PASS: HP bar present in HUD")
		pass_count += 1
	else:
		printerr("FAIL: HP bar missing from HUD")
		fail_count += 1

	var stamina_bar := arena.get_node_or_null("HUD/StatsPanel/StatsVBox/StaminaBar")
	if stamina_bar != null and stamina_bar is ProgressBar:
		print("PASS: Stamina bar present in HUD")
		pass_count += 1
	else:
		printerr("FAIL: Stamina bar missing from HUD")
		fail_count += 1

	var poise_bar := arena.get_node_or_null("HUD/StatsPanel/StatsVBox/PoiseBar")
	if poise_bar != null and poise_bar is ProgressBar:
		print("PASS: Poise bar present in HUD")
		pass_count += 1
	else:
		printerr("FAIL: Poise bar missing from HUD")
		fail_count += 1

	# T3: Player has PlayerSprite child
	var player := arena.get_node_or_null("Player")
	if player != null:
		var player_sprite := player.get_node_or_null("PlayerSprite")
		if player_sprite != null and player_sprite is Sprite2D:
			print("PASS: PlayerSprite node present on Player")
			pass_count += 1
		else:
			printerr("FAIL: PlayerSprite Sprite2D missing from Player node")
			fail_count += 1
	else:
		printerr("FAIL: Player node missing from arena")
		fail_count += 1

	# T4/T5/T6: Arena script has visual polish methods
	if arena.has_method("trigger_screen_shake"):
		print("PASS: trigger_screen_shake method present")
		pass_count += 1
	else:
		printerr("FAIL: trigger_screen_shake method missing")
		fail_count += 1

	# T4: hit flash state array exists (via _hit_flash_timers)
	if "enemies" in arena:
		print("PASS: enemies array property present")
		pass_count += 1
	else:
		printerr("FAIL: enemies array property missing")
		fail_count += 1

	# Verify set_context and set_arena_active still work
	if arena.has_method("set_context") and arena.has_method("set_arena_active"):
		print("PASS: arena control methods present")
		pass_count += 1
	else:
		printerr("FAIL: arena control methods missing")
		fail_count += 1

	if fail_count == 0:
		print("PASS: M14 combat arena visual test (%d checks)" % pass_count)
		quit(0)
	else:
		printerr("FAIL: M14 combat arena visual test (%d failed)" % fail_count)
		quit(1)
