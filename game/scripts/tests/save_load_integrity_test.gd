extends SceneTree

const SaveSystem = preload("res://scripts/systems/save_system.gd")

func _initialize() -> void:
	var defaults := GameState.default_save_state()
	_reset_save_file()

	# Persist a known state.
	var expected := {
		"banked_xp": 250,
		"banked_loot": 99,
		"unbanked_xp": 40,
		"unbanked_loot": 7,
		"current_ring": "inner",
	}
	if not SaveSystem.save_state(expected):
		_fail("Failed to write save state")
		return

	var loaded := SaveSystem.load_state(defaults)
	if int(loaded.get("banked_xp", -1)) != 250 or int(loaded.get("banked_loot", -1)) != 99:
		_fail("Failed to load persisted banked values")
		return
	if int(loaded.get("unbanked_xp", -1)) != 40 or int(loaded.get("unbanked_loot", -1)) != 7:
		_fail("Failed to load persisted unbanked values")
		return
	if str(loaded.get("current_ring", "")) != "inner":
		_fail("Failed to load persisted ring state")
		return

	# Missing fields should safely fall back to defaults.
	if not SaveSystem.save_state({"banked_xp": 10}):
		_fail("Failed to write sparse save state")
		return
	loaded = SaveSystem.load_state(defaults)
	if int(loaded.get("banked_xp", -1)) != 10:
		_fail("Sparse save should retain explicit fields")
		return
	if int(loaded.get("banked_loot", -1)) != int(defaults.get("banked_loot", -2)):
		_fail("Sparse save should fall back missing fields to defaults")
		return

	# Corrupt the save and ensure defaults are used safely.
	var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_fail("Failed to open save path for corruption test")
		return
	file.store_string("{this is invalid json")

	var recovered := SaveSystem.load_state(defaults)
	if int(recovered.get("banked_xp", -1)) != int(defaults.get("banked_xp", -2)):
		_fail("Corrupt save did not fall back to defaults")
		return

	print("PASS: save/load integrity test")
	quit(0)

func _reset_save_file() -> void:
	if FileAccess.file_exists(SaveSystem.SAVE_PATH):
		DirAccess.remove_absolute(SaveSystem.SAVE_PATH)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
