## M14 Test: Verify sprite assets exist on disk (M14 T1, T2)
## Uses ProjectSettings.globalize_path to check physical files since
## Godot headless doesn't import assets before testing.
extends SceneTree

func _check_file(res_path: String) -> bool:
	var abs_path := ProjectSettings.globalize_path(res_path)
	return FileAccess.file_exists(abs_path)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# T1: Player sprite file exists
	if _check_file("res://assets/sprites/player.png"):
		print("PASS: player sprite exists")
		checks_passed += 1
	else:
		printerr("FAIL: player sprite missing at res://assets/sprites/player.png")
		checks_failed += 1

	# T1: Player idle frame 2 exists
	if _check_file("res://assets/sprites/player_idle2.png"):
		print("PASS: player idle frame 2 exists")
		checks_passed += 1
	else:
		printerr("FAIL: player idle frame 2 missing")
		checks_failed += 1

	# T1: Enemy grunt sprite
	if _check_file("res://assets/sprites/enemy_grunt.png"):
		print("PASS: enemy_grunt.png exists")
		checks_passed += 1
	else:
		printerr("FAIL: enemy_grunt.png missing")
		checks_failed += 1

	# T1: Enemy ranged sprite
	if _check_file("res://assets/sprites/enemy_ranged.png"):
		print("PASS: enemy_ranged.png exists")
		checks_passed += 1
	else:
		printerr("FAIL: enemy_ranged.png missing")
		checks_failed += 1

	# T1: Enemy defender sprite
	if _check_file("res://assets/sprites/enemy_defender.png"):
		print("PASS: enemy_defender.png exists")
		checks_passed += 1
	else:
		printerr("FAIL: enemy_defender.png missing")
		checks_failed += 1

	# T1: Enemy warden sprite (boss)
	if _check_file("res://assets/sprites/enemy_warden.png"):
		print("PASS: enemy_warden.png exists")
		checks_passed += 1
	else:
		printerr("FAIL: enemy_warden.png missing")
		checks_failed += 1

	# T2: Arena background exists
	if _check_file("res://assets/backgrounds/arena_bg.png"):
		print("PASS: arena background exists")
		checks_passed += 1
	else:
		printerr("FAIL: arena background missing at res://assets/backgrounds/arena_bg.png")
		checks_failed += 1

	if checks_failed == 0:
		print("PASS: M14 sprite assets test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M14 sprite assets test (%d failed)" % checks_failed)
		quit(1)
