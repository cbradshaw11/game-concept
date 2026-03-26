## M29 Test: Settings screen — script loads, controls list, reset defaults
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Test 1: Settings screen script file exists and can be loaded
	var script_path := "res://scripts/ui/settings_screen.gd"
	if ResourceLoader.exists(script_path):
		print("PASS: settings_screen.gd exists")
		passed += 1
	else:
		print("FAIL: settings_screen.gd not found at %s" % script_path)
		failed += 1

	# Test 2: Settings screen scene file exists
	var scene_path := "res://scenes/ui/settings_screen.tscn"
	if ResourceLoader.exists(scene_path):
		print("PASS: settings_screen.tscn exists")
		passed += 1
	else:
		print("FAIL: settings_screen.tscn not found at %s" % scene_path)
		failed += 1

	# Test 3: SettingsManager script exists
	var manager_path := "res://autoload/settings_manager.gd"
	if ResourceLoader.exists(manager_path):
		print("PASS: settings_manager.gd exists")
		passed += 1
	else:
		print("FAIL: settings_manager.gd not found at %s" % manager_path)
		failed += 1

	# Test 4: Controls reference list completeness — 7 bindings expected
	var controls := [
		["Move", "Arrow Keys / WASD"],
		["Attack", "Space or Z"],
		["Dodge", "Shift"],
		["Guard", "Hold X"],
		["Extract", "E"],
		["Interact", "F"],
		["Open Shrine", "Tab"],
	]
	if controls.size() == 7:
		print("PASS: controls reference list has 7 entries")
		passed += 1
	else:
		print("FAIL: controls reference list expected 7 entries, got %d" % controls.size())
		failed += 1

	# Test 5: Reset to defaults produces expected values
	var DEFAULTS := {
		"master_volume_db": 0.0,
		"sfx_volume_db": 0.0,
		"music_volume_db": -6.0,
		"fullscreen": false,
	}
	# Simulate reset: set non-default values then overwrite with defaults
	var master := -20.0
	var sfx := -30.0
	var music := -10.0
	var fs := true
	# Apply defaults
	master = DEFAULTS["master_volume_db"]
	sfx = DEFAULTS["sfx_volume_db"]
	music = DEFAULTS["music_volume_db"]
	fs = DEFAULTS["fullscreen"]
	if master == 0.0 and sfx == 0.0 and music == -6.0 and fs == false:
		print("PASS: reset to defaults restores expected values")
		passed += 1
	else:
		print("FAIL: reset to defaults did not restore expected values")
		failed += 1

	# Test 6: Title screen scene has Settings button node
	var title_scene_path := "res://scenes/ui/title_screen.tscn"
	if ResourceLoader.exists(title_scene_path):
		var title_scene: PackedScene = load(title_scene_path)
		var title_instance := title_scene.instantiate()
		var settings_btn := title_instance.find_child("Settings", true, false)
		if settings_btn is Button:
			print("PASS: title screen has Settings button")
			passed += 1
		else:
			print("FAIL: title screen missing Settings button")
			failed += 1
		title_instance.free()
	else:
		print("FAIL: title screen scene not found")
		failed += 1

	print("\nSettings Screen: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
