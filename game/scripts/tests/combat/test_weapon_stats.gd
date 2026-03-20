extends SceneTree

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

func _initialize() -> void:
	var weapons_data := _load_json("res://data/weapons.json")
	var weapons: Array = weapons_data.get("weapons", [])

	if weapons.is_empty():
		_fail("weapons.json must contain a weapons array")
		return

	var expected := {
		"blade_iron": 14,
		"polearm_iron": 12,
		"bow_iron": 11,
	}

	for weapon_id in expected.keys():
		var expected_damage: int = expected[weapon_id]
		var weapon_record := _find_weapon(weapons, weapon_id)
		if weapon_record.is_empty():
			_fail("weapon not found in weapons.json: %s" % weapon_id)
			return

		var light_damage: int = int(weapon_record.get("light_damage", -1))
		if light_damage != expected_damage:
			_fail("%s light_damage expected %d, got %d" % [weapon_id, expected_damage, light_damage])
			return

		GameState.selected_weapon_id = weapon_id
		if GameState.selected_weapon_id != weapon_id:
			_fail("GameState.selected_weapon_id did not persist value: %s" % weapon_id)
			return

		var enemy := EnemyController.new(100, 3.5, 1.2)
		var hp_before: int = enemy.health
		enemy.apply_damage(light_damage, true)
		var hp_after: int = enemy.health
		if hp_before - hp_after != expected_damage:
			_fail("%s: apply_damage(%d) produced wrong HP delta (before=%d after=%d)" % [weapon_id, light_damage, hp_before, hp_after])
			return

	print("PASS: weapon stats test")
	quit(0)

func _find_weapon(weapons: Array, weapon_id: String) -> Dictionary:
	for w in weapons:
		if w.get("id") == weapon_id:
			return w
	return {}

func _load_json(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
