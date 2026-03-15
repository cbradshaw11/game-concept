extends Node

var rings: Dictionary = {}
var enemies: Dictionary = {}
var weapons: Dictionary = {}
var encounter_templates: Dictionary = {}
var shop_items: Dictionary = {}
var upgrades: Dictionary = {}
var modifiers: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	rings = _load_json("res://data/rings.json")
	enemies = _load_json("res://data/enemies.json")
	weapons = _load_json("res://data/weapons.json")
	encounter_templates = _load_json("res://data/encounter_templates.json")
	shop_items = _load_json("res://data/shop_items.json")
	upgrades = _load_json("res://data/upgrades.json")
	modifiers = _load_json("res://data/modifiers.json")

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
