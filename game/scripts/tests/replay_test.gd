extends SceneTree

const RingDirector = preload("res://scripts/systems/ring_director.gd")

func _initialize() -> void:
	var data_text := FileAccess.get_file_as_string("res://data/enemies.json")
	var parsed: Variant = JSON.parse_string(data_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("FAIL: enemies.json parse")
		quit(1)
		return

	var director := RingDirector.new()
	var seed := 424242
	var a := director.generate_encounter(seed, "inner", parsed)
	var b := director.generate_encounter(seed, "inner", parsed)
	if JSON.stringify(a) != JSON.stringify(b):
		printerr("FAIL: encounter generation is not deterministic")
		quit(1)
		return

	print("PASS: deterministic replay seed test")
	quit(0)
