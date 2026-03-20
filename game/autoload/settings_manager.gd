extends Node

func _ready() -> void:
	apply_saved_settings()

func apply_saved_settings() -> void:
	var path := "user://settings.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return
	if data.has("master"):
		AudioServer.set_bus_volume_db(0, linear_to_db(float(data["master"])))
	if data.has("sfx") and AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(float(data["sfx"])))
	if data.has("music") and AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(float(data["music"])))
	if data.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
