extends SceneTree

func _initialize() -> void:
	var enemies := _load_json("res://data/enemies.json")
	var templates := _load_json("res://data/encounter_templates.json")
	if enemies.is_empty() or templates.is_empty():
		_fail("Data files failed to parse")
		return

	var by_id: Dictionary = {}
	for enemy in enemies.get("enemies", []):
		by_id[str(enemy.get("id", ""))] = true

	var ring_counts: Dictionary = {}
	for template in templates.get("templates", []):
		var ring_id := str(template.get("ring", ""))
		ring_counts[ring_id] = int(ring_counts.get(ring_id, 0)) + 1
		for enemy_id in template.get("enemy_ids", []):
			if not by_id.has(str(enemy_id)):
				_fail("Template references unknown enemy id: %s" % str(enemy_id))
				return

	if int(ring_counts.get("inner", 0)) == 0:
		_fail("Missing inner ring templates")
		return

	print("PASS: encounter templates test")
	quit(0)

func _load_json(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
