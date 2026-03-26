extends Node
# class_name omitted — autoload singleton accessed via "SettingsManager" globally

## SettingsManager — persists audio, display, and future settings to user://settings.json.

const SAVE_PATH := "user://settings.json"

# ── Defaults ────────────────────────────────────────────────────────────────

const DEFAULTS := {
	"master_volume_db": 0.0,
	"sfx_volume_db": 0.0,
	"music_volume_db": -6.0,
	"fullscreen": false,
}

# ── Current State ───────────────────────────────────────────────────────────

var master_volume_db: float = DEFAULTS["master_volume_db"]
var sfx_volume_db: float = DEFAULTS["sfx_volume_db"]
var music_volume_db: float = DEFAULTS["music_volume_db"]
var fullscreen: bool = DEFAULTS["fullscreen"]

func _ready() -> void:
	load_settings()
	apply_all()

# ── Persistence ─────────────────────────────────────────────────────────────

func save_settings() -> void:
	var data := {
		"master_volume_db": master_volume_db,
		"sfx_volume_db": sfx_volume_db,
		"music_volume_db": music_volume_db,
		"fullscreen": fullscreen,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("SettingsManager: failed to parse settings.json")
		return
	var data: Variant = json.data
	if data is not Dictionary:
		return
	master_volume_db = float(data.get("master_volume_db", DEFAULTS["master_volume_db"]))
	sfx_volume_db = float(data.get("sfx_volume_db", DEFAULTS["sfx_volume_db"]))
	music_volume_db = float(data.get("music_volume_db", DEFAULTS["music_volume_db"]))
	fullscreen = bool(data.get("fullscreen", DEFAULTS["fullscreen"]))

# ── Apply ───────────────────────────────────────────────────────────────────

func apply_all() -> void:
	apply_audio()
	apply_display()

func apply_audio() -> void:
	_set_bus_volume("Master", master_volume_db)
	if AudioManager:
		AudioManager.set_sfx_volume(sfx_volume_db)
		AudioManager.set_music_volume(music_volume_db)

func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func reset_to_defaults() -> void:
	master_volume_db = DEFAULTS["master_volume_db"]
	sfx_volume_db = DEFAULTS["sfx_volume_db"]
	music_volume_db = DEFAULTS["music_volume_db"]
	fullscreen = DEFAULTS["fullscreen"]
	apply_all()
	save_settings()

# ── Internal ────────────────────────────────────────────────────────────────

func _set_bus_volume(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)
