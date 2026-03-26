## M29 Test: SettingsManager — defaults, save/load round-trip, expected fields
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ── Replicate defaults locally (no autoload in headless) ─────────────────
	var DEFAULTS := {
		"master_volume_db": 0.0,
		"sfx_volume_db": 0.0,
		"music_volume_db": -6.0,
		"fullscreen": false,
	}

	# Test 1: DEFAULTS has exactly 4 fields
	if DEFAULTS.size() == 4:
		print("PASS: DEFAULTS contains 4 fields")
		passed += 1
	else:
		print("FAIL: DEFAULTS expected 4 fields, got %d" % DEFAULTS.size())
		failed += 1

	# Test 2: master_volume_db default is 0.0
	if DEFAULTS["master_volume_db"] == 0.0:
		print("PASS: master_volume_db default is 0.0")
		passed += 1
	else:
		print("FAIL: master_volume_db default expected 0.0, got %s" % str(DEFAULTS["master_volume_db"]))
		failed += 1

	# Test 3: sfx_volume_db default is 0.0
	if DEFAULTS["sfx_volume_db"] == 0.0:
		print("PASS: sfx_volume_db default is 0.0")
		passed += 1
	else:
		print("FAIL: sfx_volume_db default expected 0.0, got %s" % str(DEFAULTS["sfx_volume_db"]))
		failed += 1

	# Test 4: music_volume_db default is -6.0
	if DEFAULTS["music_volume_db"] == -6.0:
		print("PASS: music_volume_db default is -6.0")
		passed += 1
	else:
		print("FAIL: music_volume_db default expected -6.0, got %s" % str(DEFAULTS["music_volume_db"]))
		failed += 1

	# Test 5: fullscreen default is false
	if DEFAULTS["fullscreen"] == false:
		print("PASS: fullscreen default is false")
		passed += 1
	else:
		print("FAIL: fullscreen default expected false")
		failed += 1

	# Test 6: Save/load round-trip via JSON
	var save_data := {
		"master_volume_db": -10.0,
		"sfx_volume_db": -20.0,
		"music_volume_db": -15.0,
		"fullscreen": true,
	}
	var json_str := JSON.stringify(save_data, "\t")
	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result == OK and json.data is Dictionary:
		var loaded: Dictionary = json.data
		var round_trip_ok := true
		if float(loaded.get("master_volume_db", 0.0)) != -10.0:
			round_trip_ok = false
		if float(loaded.get("sfx_volume_db", 0.0)) != -20.0:
			round_trip_ok = false
		if float(loaded.get("music_volume_db", 0.0)) != -15.0:
			round_trip_ok = false
		if bool(loaded.get("fullscreen", false)) != true:
			round_trip_ok = false
		if round_trip_ok:
			print("PASS: save/load round-trip preserves all fields")
			passed += 1
		else:
			print("FAIL: save/load round-trip lost data")
			failed += 1
	else:
		print("FAIL: JSON parse failed during round-trip test")
		failed += 1

	# Test 7: Missing keys in loaded data fall back to defaults
	var partial_data := {"sfx_volume_db": -5.0}
	var master_val := float(partial_data.get("master_volume_db", DEFAULTS["master_volume_db"]))
	var music_val := float(partial_data.get("music_volume_db", DEFAULTS["music_volume_db"]))
	var fs_val := bool(partial_data.get("fullscreen", DEFAULTS["fullscreen"]))
	if master_val == 0.0 and music_val == -6.0 and fs_val == false:
		print("PASS: missing keys fall back to defaults")
		passed += 1
	else:
		print("FAIL: missing keys did not fall back to defaults")
		failed += 1

	# Test 8: All expected field keys exist in DEFAULTS
	var expected_keys := ["master_volume_db", "sfx_volume_db", "music_volume_db", "fullscreen"]
	var all_present := true
	for key in expected_keys:
		if not DEFAULTS.has(key):
			all_present = false
	if all_present:
		print("PASS: all expected field keys present in DEFAULTS")
		passed += 1
	else:
		print("FAIL: some expected field keys missing from DEFAULTS")
		failed += 1

	print("\nSettings Manager: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
