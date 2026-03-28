extends RefCounted

const SPRITE_BASE := "res://assets/sprites/"
const SPRITE_MAP := {
	"scavenger_grunt": "enemy_grunt.png",
	"shieldbearer":    "enemy_defender.png",
	"ash_flanker":     "enemy_grunt.png",
	"ridge_archer":    "enemy_ranged.png",
	"rift_caster":     "enemy_ranged.png",
	"warden_hunter":   "enemy_warden.png",
	"berserker":       "enemy_grunt.png",
	"shield_wall":     "enemy_defender.png",
	"resonance_wraith":"enemy_warden.png",
}
const SPEED_MAP := {
	"scavenger_grunt": 75, "shieldbearer": 60, "ash_flanker": 110,
	"ridge_archer": 85, "rift_caster": 70, "warden_hunter": 95,
	"berserker": 130, "shield_wall": 50, "resonance_wraith": 90
}

func get_enemy_for_zone(zone: String) -> Dictionary:
	var all_enemies: Array = DataStore.enemies.get("enemies", [])
	var candidates: Array = []
	for e in all_enemies:
		if zone in e.get("rings", []):
			candidates.append(e)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

func spawn_enemy(zone: String, spawn_position: Vector2, parent: Node) -> Node2D:
	var data := get_enemy_for_zone(zone)
	if data.is_empty():
		return null

	var enemy_id: String = data.get("id", "scavenger_grunt")
	var max_hp: int = int(data.get("health", 50))
	var dmg: int = int(data.get("damage", 10))
	var spd: int = SPEED_MAP.get(enemy_id, 80)

	var node := Node2D.new()
	node.position = spawn_position
	node.set_meta("enemy_id", enemy_id)
	node.set_meta("zone", zone)
	node.set_meta("hp", max_hp)
	node.set_meta("max_hp", max_hp)
	node.set_meta("damage", dmg)
	node.set_meta("speed", spd)
	node.set_meta("alive", true)

	# Real sprite
	var sprite := Sprite2D.new()
	var sprite_file: String = SPRITE_MAP.get(enemy_id, "enemy_grunt.png")
	var tex_path := SPRITE_BASE + sprite_file
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.scale = Vector2(1.5, 1.5)
	sprite.name = "Sprite"
	node.add_child(sprite)

	# Name label above sprite
	var name_lbl := Label.new()
	name_lbl.text = enemy_id.replace("_", " ").capitalize()
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	name_lbl.position = Vector2(-40, -52)
	name_lbl.name = "NameLabel"
	node.add_child(name_lbl)

	# HP bar background
	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(48, 5)
	hp_bg.position = Vector2(-24, -44)
	hp_bg.color = Color(0.3, 0.0, 0.0)
	hp_bg.name = "HPBarBG"
	node.add_child(hp_bg)

	# HP bar fill
	var hp_bar := ColorRect.new()
	hp_bar.size = Vector2(48, 5)
	hp_bar.position = Vector2(-24, -44)
	hp_bar.color = Color(0.2, 0.85, 0.2)
	hp_bar.name = "HPBar"
	node.add_child(hp_bar)

	parent.add_child(node)
	return node
