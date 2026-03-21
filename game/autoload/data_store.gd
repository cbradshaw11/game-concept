extends Node
# class_name omitted — autoload singleton accessed via "DataStore" globally

var rings: Dictionary = {}
var enemies: Dictionary = {}
var weapons: Dictionary = {}
var encounter_templates: Dictionary = {}
var vendor_upgrades: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	rings = _load_json("res://data/rings.json")
	enemies = _load_json("res://data/enemies.json")
	weapons = _load_json("res://data/weapons.json")
	encounter_templates = _load_json("res://data/encounter_templates.json")
	vendor_upgrades = _load_json("res://data/vendor_upgrades.json")

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
