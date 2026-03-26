extends Node
# class_name omitted — autoload singleton accessed via "DataStore" globally

var rings: Dictionary = {}
var enemies: Dictionary = {}
var weapons: Dictionary = {}
var encounter_templates: Dictionary = {}
var vendor_upgrades: Dictionary = {}
var modifiers: Dictionary = {}
var permanent_unlocks: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	rings = _load_json("res://data/rings.json")
	enemies = _load_json("res://data/enemies.json")
	weapons = _load_json("res://data/weapons.json")
	encounter_templates = _load_json("res://data/encounter_templates.json")
	vendor_upgrades = _load_json("res://data/vendor_upgrades.json")
	modifiers = _load_json("res://data/modifiers.json")
	permanent_unlocks = _load_json("res://data/permanent_unlocks.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: %s" % path)
		return {}
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid json dictionary for: %s" % path)
		return {}
	return parsed

# ── Typed Lookups ────────────────────────────────────────────────────────────

func get_ring(ring_id: String) -> Dictionary:
	for ring in rings.get("rings", []):
		if str(ring.get("id", "")) == ring_id:
			return ring
	return {}

func get_enemies_for_ring(ring_id: String) -> Array:
	var result: Array = []
	for enemy in enemies.get("enemies", []):
		if ring_id in enemy.get("rings", []):
			result.append(enemy)
	return result

func get_vendor_upgrades() -> Array:
	return vendor_upgrades.get("vendor_upgrades", [])

func get_vendor_upgrade(upgrade_id: String) -> Dictionary:
	for upg in get_vendor_upgrades():
		if str(upg.get("id", "")) == upgrade_id:
			return upg
	return {}

func get_weapon(weapon_id: String) -> Dictionary:
	for weapon in weapons.get("weapons", []):
		if str(weapon.get("id", "")) == weapon_id:
			return weapon
	return {}

func get_all_modifiers() -> Array:
	return modifiers.get("modifiers", [])

func get_modifier(modifier_id: String) -> Dictionary:
	for mod in get_all_modifiers():
		if str(mod.get("id", "")) == modifier_id:
			return mod
	return {}

func get_modifier_choices_per_run() -> int:
	return int(modifiers.get("choices_per_run", 3))

func get_boss(ring_id: String) -> Dictionary:
	for boss in enemies.get("bosses", []):
		if str(boss.get("ring", "")) == ring_id:
			return boss
	return {}

func get_run_modifiers() -> Array:
	return modifiers.get("run_modifiers", [])

func get_run_modifier(modifier_id: String) -> Dictionary:
	for mod in get_run_modifiers():
		if str(mod.get("id", "")) == modifier_id:
			return mod
	return {}

func get_permanent_unlocks() -> Array:
	return permanent_unlocks.get("permanent_unlocks", [])

func get_permanent_unlock(unlock_id: String) -> Dictionary:
	for unlock in get_permanent_unlocks():
		if str(unlock.get("id", "")) == unlock_id:
			return unlock
	return {}

func get_random_modifiers(count: int, rng_seed: int) -> Array:
	var all_mods := get_all_modifiers()
	if all_mods.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var shuffled := all_mods.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	return shuffled.slice(0, min(count, shuffled.size()))
