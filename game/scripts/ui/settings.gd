extends Control
class_name SettingsScreen

signal settings_closed

@onready var master_slider: HSlider = $Panel/VBoxContainer/AudioSection/MasterRow/MasterSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/AudioSection/SFXRow/SFXSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/AudioSection/MusicRow/MusicSlider
@onready var fullscreen_toggle: CheckButton = $Panel/VBoxContainer/DisplaySection/FullscreenRow/FullscreenToggle

func _ready() -> void:
	load_settings()

func _on_master_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(value, 0.001)))

func _on_sfx_slider_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.001)))

func _on_music_slider_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.001)))

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_apply_pressed() -> void:
	save_settings()
	settings_closed.emit()

func _on_back_pressed() -> void:
	load_settings()
	settings_closed.emit()

func save_settings() -> void:
	var data := {
		"master": master_slider.value,
		"sfx": sfx_slider.value,
		"music": music_slider.value,
		"fullscreen": fullscreen_toggle.button_pressed,
	}
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_settings() -> void:
	var data := _read_settings()
	master_slider.value = data.get("master", 0.8)
	sfx_slider.value = data.get("sfx", 1.0)
	music_slider.value = data.get("music", 0.7)
	fullscreen_toggle.button_pressed = data.get("fullscreen", false)
	_on_master_slider_changed(master_slider.value)
	_on_sfx_slider_changed(sfx_slider.value)
	_on_music_slider_changed(music_slider.value)
	_on_fullscreen_toggled(fullscreen_toggle.button_pressed)

func _read_settings() -> Dictionary:
	var path := "user://settings.json"
	if not FileAccess.file_exists(path):
		return {"master": 0.8, "sfx": 1.0, "music": 0.7, "fullscreen": false}
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {"master": 0.8, "sfx": 1.0, "music": 0.7, "fullscreen": false}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed
	return {"master": 0.8, "sfx": 1.0, "music": 0.7, "fullscreen": false}
