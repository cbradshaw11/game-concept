## M15 Test: Verify audio files exist on disk (M15 T1, T2)
extends SceneTree

func _check_file(res_path: String) -> bool:
	var abs_path := ProjectSettings.globalize_path(res_path)
	return FileAccess.file_exists(abs_path)

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# SFX files
	var sfx_files := [
		"res://assets/audio/sfx_attack.wav",
		"res://assets/audio/sfx_hit.wav",
		"res://assets/audio/sfx_dodge.wav",
		"res://assets/audio/sfx_guard.wav",
		"res://assets/audio/sfx_death.wav",
		"res://assets/audio/sfx_victory.wav",
		"res://assets/audio/sfx_ui_click.wav",
	]
	for path in sfx_files:
		var fname: String = path.get_file()
		if _check_file(path):
			print("PASS: %s exists" % fname)
			checks_passed += 1
		else:
			printerr("FAIL: %s missing" % fname)
			checks_failed += 1

	# Music files
	var music_files := [
		"res://assets/audio/music_combat.wav",
		"res://assets/audio/music_sanctuary.wav",
	]
	for path in music_files:
		var fname: String = path.get_file()
		if _check_file(path):
			print("PASS: %s exists" % fname)
			checks_passed += 1
		else:
			printerr("FAIL: %s missing" % fname)
			checks_failed += 1

	# Ring 2 background
	if _check_file("res://assets/backgrounds/arena_bg_mid.png"):
		print("PASS: arena_bg_mid.png exists")
		checks_passed += 1
	else:
		printerr("FAIL: arena_bg_mid.png missing")
		checks_failed += 1

	# Music files should be > 100KB (60s ambient)
	for path in music_files:
		var abs_path := ProjectSettings.globalize_path(path)
		var mname: String = path.get_file()
		if FileAccess.file_exists(abs_path):
			var f := FileAccess.open(abs_path, FileAccess.READ)
			if f and f.get_length() > 100000:
				print("PASS: %s is substantial (%d bytes)" % [mname, f.get_length()])
				checks_passed += 1
			else:
				printerr("FAIL: %s too small or unreadable" % mname)
				checks_failed += 1

	if checks_failed == 0:
		print("PASS: M15 audio files test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M15 audio files test (%d failed)" % checks_failed)
		quit(1)
