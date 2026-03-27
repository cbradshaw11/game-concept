extends RefCounted
class_name SaveSystem

const SAVE_PATH := "user://savegame.json"

# ── Save Version History ────────────────────────────────────────────────────
# v7  — artifact_retrieved flag
# v8  — M21 lifetime stats (total_runs, total_extractions, total_deaths,
#        deepest_ring_reached, artifact_retrievals, fastest_extraction_seconds)
# v9  — M23 collected lore fragments (collected_fragments)
# v10 — M27-M32 batch: resonance shards (resonance_shards, resonance_spent,
#        permanent_unlocks), M32 achievements (unlocked_achievements,
#        lifetime_kills, lifetime_poise_breaks, completed_challenges)
# v11 — M38 three-slot weapon loadout (equipped_melee, equipped_ranged,
#        equipped_magic)
const SAVE_VERSION := 11

static func save_state(data: Dictionary) -> bool:
	data["_save_version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for write")
		return false
	file.store_string(JSON.stringify(data))
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

	# v10 migration guard — merge-with-defaults fills any missing keys from
	# older saves (v7-v9) so resonance, achievement, and challenge fields
	# get safe defaults automatically.
	return _merge_with_defaults(parsed, default_state)

static func _merge_with_defaults(candidate: Dictionary, defaults: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in defaults.keys():
		if candidate.has(key):
			merged[key] = candidate[key]
	return merged

static func get_save_version() -> int:
	return SAVE_VERSION
