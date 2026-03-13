extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1-4: Required audio files exist in res://audio/
	var required_files := ["hit_land.wav", "damage_taken.wav", "dodge_guard_success.wav", "player_death.wav"]
	for filename in required_files:
		var path := "res://audio/" + filename
		if not FileAccess.file_exists(path):
			failures.append("Missing audio file: " + path)

	# Test 5: WIND_UP state exists in enemy_controller.gd source
	var ec_path := "res://scripts/core/enemy_controller.gd"
	if FileAccess.file_exists(ec_path):
		var src := FileAccess.get_file_as_string(ec_path)
		if not ("WIND_UP" in src):
			failures.append("WIND_UP state not found in enemy_controller.gd")
	else:
		failures.append("enemy_controller.gd not found at " + ec_path)

	if failures.is_empty():
		print("PASS: test_audio_events")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
