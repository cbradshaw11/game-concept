extends RefCounted
class_name SaveSystem

const SAVE_PATH := "user://savegame.json"

static func save_state(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for write")
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

static func load_state(default_state: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_state.duplicate(true)

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_state.duplicate(true)

	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_state.duplicate(true)

	return _merge_with_defaults(parsed, default_state)

static func _merge_with_defaults(candidate: Dictionary, defaults: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in defaults.keys():
		if candidate.has(key):
			merged[key] = candidate[key]
	return merged
