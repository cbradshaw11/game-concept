extends RefCounted

func get_enemy_for_zone(zone: String) -> Dictionary:
	var all_enemies: Array = DataStore.enemies.get("enemies", [])
	var candidates: Array = []
	for e in all_enemies:
		var rings: Array = e.get("rings", [])
		if zone in rings:
			candidates.append(e)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

func spawn_enemy(zone: String, spawn_position: Vector2, parent: Node) -> Node2D:
	var data := get_enemy_for_zone(zone)
	if data.is_empty():
		return null

	var speed_map := {
		"scavenger_grunt": 75, "shieldbearer": 60, "ash_flanker": 110,
		"ridge_archer": 85, "rift_caster": 70, "warden_hunter": 95,
		"berserker": 130, "shield_wall": 50, "resonance_wraith": 90
	}

	var node := Node2D.new()
	node.position = spawn_position
	node.set_meta("enemy_id", data.get("id", "unknown"))
	node.set_meta("zone", zone)
	node.set_meta("health", int(data.get("health", 50)))
	node.set_meta("max_health", int(data.get("health", 50)))
	node.set_meta("damage", int(data.get("damage", 10)))
	node.set_meta("speed", int(speed_map.get(data.get("id", ""), 80)))
	node.set_meta("alive", true)

	var body := ColorRect.new()
	body.size = Vector2(24, 32)
	body.position = Vector2(-12, -32)
	match zone:
		"inner":
			body.color = Color(0.3, 0.6, 0.3)
		"mid":
			body.color = Color(0.7, 0.5, 0.2)
		"outer":
			body.color = Color(0.7, 0.2, 0.2)
	node.add_child(body)

	var label := Label.new()
	label.text = str(data.get("id", "enemy")).substr(0, 8)
	label.position = Vector2(-20, -48)
	label.add_theme_font_size_override("font_size", 10)
	node.add_child(label)

	var hp_bar := ColorRect.new()
	hp_bar.size = Vector2(24, 3)
	hp_bar.position = Vector2(-12, -35)
	hp_bar.color = Color(0.2, 0.8, 0.2)
	hp_bar.name = "HPBar"
	node.add_child(hp_bar)

	parent.add_child(node)
	return node
