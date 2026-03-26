## M29 Test: Audio settings — bus volume changes, master/sfx/music independence
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Ensure SFX and Music buses exist (create them if missing, like AudioManager does)
	_ensure_bus("SFX")
	_ensure_bus("Music")

	# Test 1: Setting Master bus volume updates AudioServer
	var master_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, -12.0)
	var master_vol := AudioServer.get_bus_volume_db(master_idx)
	if abs(master_vol - (-12.0)) < 0.01:
		print("PASS: Master bus volume set to -12 dB")
		passed += 1
	else:
		print("FAIL: Master bus volume expected -12 dB, got %s" % str(master_vol))
		failed += 1

	# Test 2: Setting SFX bus volume updates AudioServer
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, -20.0)
		var sfx_vol := AudioServer.get_bus_volume_db(sfx_idx)
		if abs(sfx_vol - (-20.0)) < 0.01:
			print("PASS: SFX bus volume set to -20 dB")
			passed += 1
		else:
			print("FAIL: SFX bus volume expected -20 dB, got %s" % str(sfx_vol))
			failed += 1
	else:
		print("FAIL: SFX bus not found")
		failed += 1

	# Test 3: Setting Music bus volume updates AudioServer
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, -6.0)
		var music_vol := AudioServer.get_bus_volume_db(music_idx)
		if abs(music_vol - (-6.0)) < 0.01:
			print("PASS: Music bus volume set to -6 dB")
			passed += 1
		else:
			print("FAIL: Music bus volume expected -6 dB, got %s" % str(music_vol))
			failed += 1
	else:
		print("FAIL: Music bus not found")
		failed += 1

	# Test 4: Changing SFX does not affect Music bus
	AudioServer.set_bus_volume_db(sfx_idx, -30.0)
	var music_after := AudioServer.get_bus_volume_db(music_idx)
	if abs(music_after - (-6.0)) < 0.01:
		print("PASS: changing SFX volume does not affect Music bus")
		passed += 1
	else:
		print("FAIL: changing SFX volume affected Music bus (got %s)" % str(music_after))
		failed += 1

	# Test 5: Changing Music does not affect SFX bus
	AudioServer.set_bus_volume_db(music_idx, -15.0)
	var sfx_after := AudioServer.get_bus_volume_db(sfx_idx)
	if abs(sfx_after - (-30.0)) < 0.01:
		print("PASS: changing Music volume does not affect SFX bus")
		passed += 1
	else:
		print("FAIL: changing Music volume affected SFX bus (got %s)" % str(sfx_after))
		failed += 1

	# Test 6: Volume range boundaries — -40 dB minimum
	AudioServer.set_bus_volume_db(sfx_idx, -40.0)
	var min_vol := AudioServer.get_bus_volume_db(sfx_idx)
	if abs(min_vol - (-40.0)) < 0.01:
		print("PASS: -40 dB minimum accepted by AudioServer")
		passed += 1
	else:
		print("FAIL: -40 dB not correctly set, got %s" % str(min_vol))
		failed += 1

	# Test 7: Volume range boundaries — 0 dB maximum
	AudioServer.set_bus_volume_db(sfx_idx, 0.0)
	var max_vol := AudioServer.get_bus_volume_db(sfx_idx)
	if abs(max_vol - 0.0) < 0.01:
		print("PASS: 0 dB maximum accepted by AudioServer")
		passed += 1
	else:
		print("FAIL: 0 dB not correctly set, got %s" % str(max_vol))
		failed += 1

	print("\nAudio Settings: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
