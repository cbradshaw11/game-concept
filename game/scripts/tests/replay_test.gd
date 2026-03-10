extends SceneTree

const RingDirector = preload("res://scripts/systems/ring_director.gd")

func _initialize() -> void:
	var enemies := _load_json("res://data/enemies.json")
	var templates := _load_json("res://data/encounter_templates.json")
	if enemies.is_empty() or templates.is_empty():
		printerr("FAIL: enemies.json parse")
		quit(1)
		return

	var director := RingDirector.new()
	var seed := 424242
	var a := director.generate_encounter(seed, "inner", enemies, templates)
	var b := director.generate_encounter(seed, "inner", enemies, templates)
	if JSON.stringify(a) != JSON.stringify(b):
		printerr("FAIL: encounter generation is not deterministic")
		quit(1)
		return

	if str(a.get("template_id", "")) == "":
		printerr("FAIL: encounter template id missing")
		quit(1)
		return

	print("PASS: deterministic replay seed test")
	quit(0)

func _load_json(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
