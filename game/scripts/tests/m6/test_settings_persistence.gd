extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: settings_manager.gd exists as a file
	if not FileAccess.file_exists("res://autoload/settings_manager.gd"):
		failures.append("settings_manager.gd not found at res://autoload/settings_manager.gd")

	# Test 2: default_save_state() does not include volume settings
	# (volume stored in separate settings.json, not in the savegame)
	var defaults := GameState.default_save_state()
	var volume_keys := ["master", "sfx", "music", "fullscreen", "volume"]
	for key in volume_keys:
		if defaults.has(key):
			failures.append("default_save_state() should not include volume/settings key '%s'" % key)

	# Test 3: save_version is 6 in default_save_state() (M11 bump)
	var save_version = defaults.get("save_version", -1)
	if save_version != 6:
		failures.append("Expected save_version == 4 in default_save_state(), got %s" % str(save_version))

	# Test 4: M4 save (no save_version) migrates cleanly -- permanent_upgrades defaults to []
	var m4_save := {
		"banked_xp": 100,
		"banked_loot": 200,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "inner",
		"rings_cleared": ["inner"],
		"warden_defeated": false,
		"game_completed": false,
		# intentionally missing save_version
	}
	GameState.apply_save_state(m4_save)
	if GameState.permanent_upgrades.size() != 0:
		failures.append("M4 save: permanent_upgrades should default to [], got size %d" % GameState.permanent_upgrades.size())

	# Test 5: M5 save (save_version=1) migrates cleanly
	# permanent_upgrades and prologue_seen default correctly
	var m5_save := {
		"banked_xp": 0,
		"banked_loot": 50,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
		"warden_phase_reached": 1,
		"save_version": 1,
		# no permanent_upgrades, no prologue_seen
	}
	GameState.apply_save_state(m5_save)
	if GameState.permanent_upgrades.size() != 0:
		failures.append("M5 save: permanent_upgrades should default to [], got size %d" % GameState.permanent_upgrades.size())
	if GameState.prologue_seen != false:
		failures.append("M5 save: prologue_seen should default to false, got %s" % str(GameState.prologue_seen))

	if failures.is_empty():
		print("PASS: test_settings_persistence")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
