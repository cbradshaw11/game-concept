extends Node2D

# ── Dev Enemy Test Arena ─────────────────────────────────────────────────────
# Standalone developer tool for spawning and testing enemies.
# Built entirely in code — no .tscn dependencies beyond player sprite.

const SPRITE_BASE := "res://assets/sprites/"
const SPRITE_MAP := {
	"scavenger_grunt": "enemy_grunt.png",
	"cave_spider":     "enemy_grunt.png",
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
	"scavenger_grunt": 75, "cave_spider": 95, "shieldbearer": 60, "ash_flanker": 110,
	"ridge_archer": 85, "rift_caster": 70, "warden_hunter": 95,
	"berserker": 130, "shield_wall": 50, "resonance_wraith": 90
}
const TINT_MAP := {
	"cave_spider": Color(0.55, 0.3, 0.65),
	"shieldbearer": Color(0.75, 0.8, 0.9),
	"shield_wall": Color(0.75, 0.8, 0.9),
	"berserker": Color(0.95, 0.35, 0.2),
	"ash_flanker": Color(0.6, 0.65, 0.5),
	"resonance_wraith": Color(0.5, 0.8, 1.0, 0.8),
}

# Hardcoded enemy data (self-contained — no DataStore dependency)
const ENEMY_DATA := {
	"cave_spider":      { "hp": 40,  "damage": 9,  "zone": "inner", "desc": "Scurries erratically, stops to fire slow web projectiles" },
	"scavenger_grunt":  { "hp": 50,  "damage": 10, "zone": "inner", "desc": "Basic melee, steady charge toward player" },
	"shieldbearer":     { "hp": 80,  "damage": 18, "zone": "mid",   "desc": "Slow advance, wind-up brace, then lunges to strike" },
	"shield_wall":      { "hp": 120, "damage": 22, "zone": "mid",   "desc": "Barely moves, forces you to engage, hits very hard" },
	"ash_flanker":      { "hp": 55,  "damage": 12, "zone": "mid",   "desc": "Wide zigzag strafe, quick strikes" },
	"berserker":        { "hp": 65,  "damage": 16, "zone": "mid",   "desc": "Burst-sprint with hard stops, erratic timing" },
	"ridge_archer":     { "hp": 45,  "damage": 14, "zone": "mid",   "desc": "Keeps distance, fires orange projectiles" },
	"rift_caster":      { "hp": 50,  "damage": 15, "zone": "outer", "desc": "Orbits player, lobs slow purple orbs" },
	"warden_hunter":    { "hp": 90,  "damage": 20, "zone": "outer", "desc": "Normal chase, repositions after each hit" },
	"resonance_wraith": { "hp": 70,  "damage": 17, "zone": "outer", "desc": "Teleports every 2s, ethereal drift between blinks" },
}

# Ordered list for menu display
const ENEMY_ORDER := [
	"cave_spider", "scavenger_grunt",
	"shieldbearer", "shield_wall", "ash_flanker", "berserker", "ridge_archer",
	"rift_caster", "warden_hunter", "resonance_wraith",
]

var player_speed := 200.0
var player_health := 200.0
var player_max_health := 200.0
var enemies: Array[Node2D] = []
var damage_timers: Dictionary = {}
var _enemy_state_timers: Dictionary = {}
var attack_cooldown: float = 0.0
var _last_move_dir: Vector2 = Vector2.RIGHT
var _menu_open: bool = false

# Scene nodes (built in _ready)
var player: Node2D = null
var camera: Camera2D = null
var background: ColorRect = null
var enemy_container: Node2D = null
var hud_layer: CanvasLayer = null
var health_bar: ColorRect = null
var hp_label: Label = null
var enemy_count_label: Label = null
var menu_panel: Panel = null

func _ready() -> void:
	_build_scene()

# ── Scene Construction ───────────────────────────────────────────────────────

func _build_scene() -> void:
	# Background
	background = ColorRect.new()
	background.color = Color(0.12, 0.12, 0.14)
	background.size = Vector2(4000, 4000)
	background.position = Vector2(-2000, -2000)
	add_child(background)

	# Player
	player = Node2D.new()
	player.name = "Player"
	player.position = Vector2.ZERO
	var player_sprite := Sprite2D.new()
	player_sprite.name = "PlayerSprite"
	var tex_path := "res://assets/sprites/player.png"
	if ResourceLoader.exists(tex_path):
		player_sprite.texture = load(tex_path)
	player_sprite.scale = Vector2(1.5, 1.5)
	player.add_child(player_sprite)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	player.add_child(camera)
	add_child(player)

	# Enemy container
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)

	# HUD
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	# Hint label (top center)
	var hint := Label.new()
	hint.text = "TAB \u2014 Enemy Menu  |  ESC \u2014 Back to Title  |  WASD \u2014 Move  |  Z/Click \u2014 Melee  |  Q \u2014 Ranged"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.7))
	hint.position = Vector2(200, 8)
	hint.name = "HintLabel"
	hud_layer.add_child(hint)

	# Health bar BG
	var hb_bg := ColorRect.new()
	hb_bg.size = Vector2(204, 14)
	hb_bg.position = Vector2(10, 32)
	hb_bg.color = Color(0.2, 0.0, 0.0)
	hb_bg.name = "HealthBarBG"
	hud_layer.add_child(hb_bg)

	# Health bar fill
	health_bar = ColorRect.new()
	health_bar.size = Vector2(200, 10)
	health_bar.position = Vector2(12, 34)
	health_bar.color = Color(0.2, 0.8, 0.2)
	health_bar.name = "HealthBar"
	hud_layer.add_child(health_bar)

	# HP label
	hp_label = Label.new()
	hp_label.text = "HP: 200 / 200"
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hp_label.position = Vector2(220, 32)
	hp_label.name = "HPLabel"
	hud_layer.add_child(hp_label)

	# Enemy count label
	enemy_count_label = Label.new()
	enemy_count_label.text = "Enemies: 0"
	enemy_count_label.add_theme_font_size_override("font_size", 11)
	enemy_count_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	enemy_count_label.position = Vector2(10, 52)
	enemy_count_label.name = "EnemyCount"
	hud_layer.add_child(enemy_count_label)

func _process(delta: float) -> void:
	_handle_global_input()
	if not _menu_open:
		_handle_movement(delta)
		_handle_attack(delta)
		_update_enemies(delta)
		_update_archer_attacks(delta)
		_update_caster_attacks(delta)
		_animate_enemies(delta)
		_check_enemy_damage(delta)
	_update_hud()
	_clean_dead_enemies()
	# Keep background centered on player
	background.position = player.position - Vector2(2000, 2000)

func _handle_global_input() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if _menu_open:
			_close_menu()
		else:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	if Input.is_key_pressed(KEY_TAB) and not Input.is_key_pressed(KEY_SHIFT):
		# Only toggle on press, not hold
		pass
	if Input.is_action_just_pressed("ui_focus_next"):
		# TAB — toggle menu
		if _menu_open:
			_close_menu()
		else:
			_open_menu()

func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if dir != Vector2.ZERO:
		var norm_dir: Vector2 = dir.normalized()
		player.position += norm_dir * player_speed * delta
		_last_move_dir = norm_dir

func _handle_attack(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown > 0.0:
		return
	if Input.is_action_just_pressed("attack_melee"):
		_do_melee_attack()
		attack_cooldown = 0.5
	elif Input.is_action_just_pressed("attack_ranged"):
		_do_ranged_attack()
		attack_cooldown = 0.8

# ── Melee Attack ─────────────────────────────────────────────────────────────

func _do_melee_attack() -> void:
	var nearest: Node2D = _get_nearest_enemy(120.0)
	var swing_dir: Vector2 = _last_move_dir
	if nearest != null:
		swing_dir = (nearest.position - player.position).normalized()
	var pivot := Node2D.new()
	pivot.position = swing_dir * 10.0
	pivot.rotation = atan2(swing_dir.y, swing_dir.x) - deg_to_rad(30.0)
	player.add_child(pivot)

	var blade := Line2D.new()
	blade.width = 5.0
	blade.default_color = Color(0.88, 0.94, 1.0)
	blade.add_point(Vector2(8, 0))
	blade.add_point(Vector2(54, 0))
	pivot.add_child(blade)

	var guard := Line2D.new()
	guard.width = 4.0
	guard.default_color = Color(0.75, 0.62, 0.25)
	guard.add_point(Vector2(6, -10))
	guard.add_point(Vector2(6, 10))
	pivot.add_child(guard)

	var swing_tw := create_tween()
	swing_tw.tween_property(pivot, "rotation", pivot.rotation + deg_to_rad(60.0), 0.18).set_ease(Tween.EASE_OUT)
	swing_tw.tween_property(pivot, "modulate:a", 0.0, 0.08)
	swing_tw.tween_callback(pivot.queue_free)

	var trail := Line2D.new()
	trail.width = 18.0
	trail.default_color = Color(1.0, 1.0, 0.85, 0.35)
	var perp := Vector2(-swing_dir.y, swing_dir.x)
	var trail_origin: Vector2 = swing_dir * 30.0
	trail.add_point(trail_origin + perp * 28.0 - swing_dir * 10.0)
	trail.add_point(trail_origin + swing_dir * 36.0)
	trail.add_point(trail_origin - perp * 28.0 - swing_dir * 10.0)
	player.add_child(trail)
	var trail_tw := create_tween()
	trail_tw.tween_property(trail, "modulate:a", 0.0, 0.18)
	trail_tw.tween_callback(trail.queue_free)

	var base_dmg: int = 15
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if player.position.distance_to(enemy.position) <= 80.0:
			_deal_damage_to_enemy(enemy, base_dmg)

# ── Ranged Attack ────────────────────────────────────────────────────────────

func _do_ranged_attack() -> void:
	var nearest: Node2D = _get_nearest_enemy(500.0)
	if nearest == null:
		return
	var proj := ColorRect.new()
	proj.size = Vector2(10, 10)
	proj.color = Color(0.9, 0.95, 1.0)
	proj.position = player.position - Vector2(5, 5)
	add_child(proj)
	var base_dmg: int = 20
	var dmg_val := base_dmg
	var tw := create_tween()
	tw.tween_property(proj, "position", nearest.position - Vector2(5, 5), 0.25)
	tw.tween_callback(func():
		proj.queue_free()
		if is_instance_valid(nearest) and nearest.get_meta("alive", false):
			_deal_damage_to_enemy(nearest, dmg_val)
	)

func _get_nearest_enemy(max_dist: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = max_dist
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		var d: float = player.position.distance_to(enemy.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest

# ── Damage / Kill ────────────────────────────────────────────────────────────

func _deal_damage_to_enemy(enemy: Node2D, dmg: int) -> void:
	var hp: int = enemy.get_meta("hp", 0)
	var max_hp: int = enemy.get_meta("max_hp", 1)
	hp = max(0, hp - dmg)
	enemy.set_meta("hp", hp)

	var hp_bar: Node = enemy.find_child("HPBar", false, false)
	if hp_bar and hp_bar is ColorRect:
		var ratio: float = float(hp) / float(max_hp)
		(hp_bar as ColorRect).size.x = 48.0 * ratio
		(hp_bar as ColorRect).color = Color(0.2, 0.85, 0.2) if ratio > 0.4 else Color(0.85, 0.2, 0.2)

	var sprite: Node = enemy.find_child("Sprite", false, false)
	if sprite and sprite is Sprite2D:
		(sprite as Sprite2D).modulate = Color(1.5, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_interval(0.1)
		tw.tween_callback(func(): if is_instance_valid(sprite): (sprite as Sprite2D).modulate = Color.WHITE)

	var lbl := Label.new()
	lbl.text = "-%d" % dmg
	lbl.position = enemy.position + Vector2(-10, -60)
	lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	lbl.add_theme_font_size_override("font_size", 13)
	add_child(lbl)
	var tw2 := create_tween()
	tw2.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.5)
	tw2.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(lbl.queue_free)

	if hp <= 0:
		_on_enemy_killed(enemy)

func _on_enemy_killed(enemy: Node2D) -> void:
	enemy.set_meta("alive", false)
	var tw := create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 0.3)
	tw.tween_callback(enemy.queue_free)

func _clean_dead_enemies() -> void:
	var i := enemies.size() - 1
	while i >= 0:
		if not is_instance_valid(enemies[i]) or not enemies[i].get_meta("alive", false):
			enemies.remove_at(i)
		i -= 1

# ── Enemy Spawning ───────────────────────────────────────────────────────────

func _spawn_specific_enemy(enemy_id: String) -> void:
	var data: Dictionary = ENEMY_DATA.get(enemy_id, {})
	if data.is_empty():
		return
	var max_hp: int = data["hp"]
	var dmg: int = data["damage"]
	var zone: String = data["zone"]
	var spd: int = SPEED_MAP.get(enemy_id, 80)

	# Random position 200-300px from player
	var angle: float = randf() * TAU
	var dist: float = randf_range(200.0, 300.0)
	var spawn_pos: Vector2 = player.position + Vector2(cos(angle), sin(angle)) * dist

	var node := Node2D.new()
	node.position = spawn_pos
	node.set_meta("enemy_id", enemy_id)
	node.set_meta("zone", zone)
	node.set_meta("hp", max_hp)
	node.set_meta("max_hp", max_hp)
	node.set_meta("damage", dmg)
	node.set_meta("speed", spd)
	node.set_meta("alive", true)

	var sprite := Sprite2D.new()
	var sprite_file: String = SPRITE_MAP.get(enemy_id, "enemy_grunt.png")
	var tex_path := SPRITE_BASE + sprite_file
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.scale = Vector2(1.5, 1.5)
	sprite.name = "Sprite"
	if TINT_MAP.has(enemy_id):
		sprite.modulate = TINT_MAP[enemy_id]
	node.add_child(sprite)

	var name_lbl := Label.new()
	name_lbl.text = enemy_id.replace("_", " ").capitalize()
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	name_lbl.position = Vector2(-40, -52)
	name_lbl.name = "NameLabel"
	node.add_child(name_lbl)

	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(48, 5)
	hp_bg.position = Vector2(-24, -44)
	hp_bg.color = Color(0.3, 0.0, 0.0)
	hp_bg.name = "HPBarBG"
	node.add_child(hp_bg)

	var hp_fill := ColorRect.new()
	hp_fill.size = Vector2(48, 5)
	hp_fill.position = Vector2(-24, -44)
	hp_fill.color = Color(0.2, 0.85, 0.2)
	hp_fill.name = "HPBar"
	node.add_child(hp_fill)

	enemy_container.add_child(node)
	enemies.append(node)

# ── HUD ──────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	if health_bar:
		var ratio: float = player_health / player_max_health
		health_bar.size.x = 200.0 * ratio
		health_bar.color = Color(0.2, 0.8, 0.2) if ratio > 0.35 else Color(0.85, 0.2, 0.2)
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(player_health), int(player_max_health)]
	if enemy_count_label:
		enemy_count_label.text = "Enemies: %d" % enemies.size()

# ── Player Death (reset) ────────────────────────────────────────────────────

func _on_player_death() -> void:
	player_health = player_max_health
	player.position = Vector2.ZERO
	damage_timers.clear()

# ── Enemy Behavior ───────────────────────────────────────────────────────────

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
			continue
		var spd: float = enemy.get_meta("speed", 80.0)
		var enemy_id: String = enemy.get_meta("enemy_id", "scavenger_grunt")
		var to_player: Vector2 = player.position - enemy.position
		var eid: int = enemy.get_instance_id()
		if not _enemy_state_timers.has(eid):
			_enemy_state_timers[eid] = {}

		match enemy_id:
			"shieldbearer":
				if not _enemy_state_timers[eid].has("block_timer"):
					_enemy_state_timers[eid]["block_timer"] = 0.7
				if not _enemy_state_timers[eid].has("lunging"):
					_enemy_state_timers[eid]["lunging"] = false
				var dist_sb: float = to_player.length()
				if dist_sb > 110.0:
					enemy.position += to_player.normalized() * spd * 0.6 * delta
					_enemy_state_timers[eid]["block_timer"] = 0.7
					_enemy_state_timers[eid]["lunging"] = false
				elif _enemy_state_timers[eid]["lunging"]:
					if dist_sb > 1.0:
						enemy.position += to_player.normalized() * spd * 1.4 * delta
				else:
					_enemy_state_timers[eid]["block_timer"] -= delta
					if _enemy_state_timers[eid]["block_timer"] <= 0.0:
						_enemy_state_timers[eid]["lunging"] = true

			"ash_flanker":
				var t: float = Time.get_ticks_msec() / 1000.0
				var dir_norm: Vector2 = to_player.normalized()
				var strafe_phase: float = float(eid % 13) * 0.8
				var strafe := Vector2(-dir_norm.y, dir_norm.x) * sin(t * 2.5 + strafe_phase) * 120.0
				var dist_fl: float = to_player.length()
				var strafe_weight: float = clampf(dist_fl / 150.0, 0.0, 1.0)
				if dist_fl > 1.0:
					enemy.position += (to_player.normalized() * spd + strafe * strafe_weight) * delta

			"ridge_archer":
				var dist_to_player: float = to_player.length()
				if dist_to_player < 200.0:
					enemy.position -= to_player.normalized() * spd * delta
				elif dist_to_player > 350.0:
					enemy.position += to_player.normalized() * spd * delta

			"rift_caster":
				var dist_to_player: float = to_player.length()
				var orbit_angle: float = atan2(to_player.y, to_player.x) + PI / 2.0
				var tangent_dir := Vector2(cos(orbit_angle), sin(orbit_angle))
				var radial_correction: Vector2 = Vector2.ZERO
				if dist_to_player < 230.0:
					radial_correction = -to_player.normalized() * spd * 0.3
				elif dist_to_player > 270.0:
					radial_correction = to_player.normalized() * spd * 0.3
				enemy.position += (tangent_dir * spd * 0.7 + radial_correction) * delta

			"berserker":
				if not _enemy_state_timers[eid].has("burst"):
					_enemy_state_timers[eid]["burst"] = randf_range(0.3, 0.6)
					_enemy_state_timers[eid]["burst_moving"] = true
				_enemy_state_timers[eid]["burst"] -= delta
				if _enemy_state_timers[eid]["burst"] <= 0.0:
					var was_moving: bool = _enemy_state_timers[eid]["burst_moving"]
					_enemy_state_timers[eid]["burst_moving"] = not was_moving
					_enemy_state_timers[eid]["burst"] = randf_range(0.3, 0.55) if not was_moving else randf_range(0.08, 0.15)
				if _enemy_state_timers[eid]["burst_moving"] and to_player.length() > 1.0:
					enemy.position += to_player.normalized() * spd * 1.8 * delta

			"shield_wall":
				var dist_sw: float = to_player.length()
				if dist_sw > 55.0:
					enemy.position += to_player.normalized() * spd * 0.35 * delta

			"warden_hunter":
				if not _enemy_state_timers[eid].has("reposition"):
					_enemy_state_timers[eid]["reposition"] = 0.0
				if _enemy_state_timers[eid]["reposition"] > 0.0:
					var perp_dir := Vector2(-to_player.normalized().y, to_player.normalized().x)
					enemy.position += perp_dir * spd * delta
					_enemy_state_timers[eid]["reposition"] -= delta
				else:
					if to_player.length() > 1.0:
						enemy.position += to_player.normalized() * spd * delta

			"resonance_wraith":
				if not _enemy_state_timers[eid].has("teleport"):
					_enemy_state_timers[eid]["teleport"] = 2.0
					_enemy_state_timers[eid]["tp_cooldown"] = 0.0
				_enemy_state_timers[eid]["teleport"] -= delta
				_enemy_state_timers[eid]["tp_cooldown"] -= delta
				if _enemy_state_timers[eid]["teleport"] <= 0.0:
					var tp_angle: float = randf() * TAU
					var dist_tp: float = randf_range(180.0, 260.0)
					enemy.position = player.position + Vector2(cos(tp_angle), sin(tp_angle)) * dist_tp
					_enemy_state_timers[eid]["teleport"] = 2.0
					_enemy_state_timers[eid]["tp_cooldown"] = 0.5
					var sprite: Node = enemy.find_child("Sprite", false, false)
					if sprite and sprite is Sprite2D:
						(sprite as Sprite2D).modulate = Color(3.0, 3.0, 3.0)
						var tw := create_tween()
						tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
				else:
					if to_player.length() > 1.0:
						enemy.position += to_player.normalized() * spd * 0.4 * delta

			"cave_spider":
				if not _enemy_state_timers[eid].has("web_cooldown"):
					_enemy_state_timers[eid]["web_cooldown"] = randf_range(1.5, 2.5)
				if not _enemy_state_timers[eid].has("firing"):
					_enemy_state_timers[eid]["firing"] = false
				_enemy_state_timers[eid]["web_cooldown"] -= delta
				var dist_sp: float = to_player.length()
				if _enemy_state_timers[eid]["web_cooldown"] <= 0.0 and dist_sp < 320.0:
					_enemy_state_timers[eid]["firing"] = true
					_enemy_state_timers[eid]["web_cooldown"] = randf_range(2.0, 3.5)
					_fire_web_projectile(enemy)
					_enemy_state_timers[eid]["fire_pause"] = 0.55
				if _enemy_state_timers[eid].get("fire_pause", 0.0) > 0.0:
					_enemy_state_timers[eid]["fire_pause"] -= delta
				else:
					_enemy_state_timers[eid]["firing"] = false
					if not _enemy_state_timers[eid].has("scurry_dir"):
						_enemy_state_timers[eid]["scurry_dir"] = randf() * TAU
					if not _enemy_state_timers[eid].has("scurry_timer"):
						_enemy_state_timers[eid]["scurry_timer"] = randf_range(0.2, 0.5)
					_enemy_state_timers[eid]["scurry_timer"] -= delta
					if _enemy_state_timers[eid]["scurry_timer"] <= 0.0:
						var base_angle: float = atan2(to_player.y, to_player.x)
						_enemy_state_timers[eid]["scurry_dir"] = base_angle + randf_range(-0.9, 0.9)
						_enemy_state_timers[eid]["scurry_timer"] = randf_range(0.15, 0.4)
					var scurry_angle: float = _enemy_state_timers[eid]["scurry_dir"]
					var scurry_vec := Vector2(cos(scurry_angle), sin(scurry_angle))
					enemy.position += scurry_vec * spd * delta
			_:
				if to_player.length() > 1.0:
					enemy.position += to_player.normalized() * spd * delta

# ── Ranged Enemy Attacks ─────────────────────────────────────────────────────

func _update_archer_attacks(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("enemy_id", "") != "ridge_archer":
			continue
		var eid: int = enemy.get_instance_id()
		if not _enemy_state_timers.has(eid):
			_enemy_state_timers[eid] = {}
		if not _enemy_state_timers[eid].has("archer_cooldown"):
			_enemy_state_timers[eid]["archer_cooldown"] = 2.5
		_enemy_state_timers[eid]["archer_cooldown"] -= delta
		if _enemy_state_timers[eid]["archer_cooldown"] <= 0.0:
			var dist_to_player: float = player.position.distance_to(enemy.position)
			if dist_to_player <= 350.0:
				_enemy_state_timers[eid]["archer_cooldown"] = 2.5
				var proj := ColorRect.new()
				proj.size = Vector2(8, 8)
				proj.color = Color(1.0, 0.7, 0.15)
				proj.position = enemy.position - Vector2(4, 4)
				add_child(proj)
				var dmg_val: int = enemy.get_meta("damage", 10)
				var target_pos: Vector2 = player.position
				var tw := create_tween()
				tw.tween_property(proj, "position", target_pos - Vector2(4, 4), 0.4)
				tw.tween_callback(func():
					proj.queue_free()
					if player.position.distance_to(target_pos) < 50.0:
						player_health -= float(dmg_val)
						_flash_player_hit(dmg_val)
						if player_health <= 0.0:
							_on_player_death()
				)

func _update_caster_attacks(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("enemy_id", "") != "rift_caster":
			continue
		var eid: int = enemy.get_instance_id()
		if not _enemy_state_timers.has(eid):
			_enemy_state_timers[eid] = {}
		if not _enemy_state_timers[eid].has("caster_cooldown"):
			_enemy_state_timers[eid]["caster_cooldown"] = 3.5
		_enemy_state_timers[eid]["caster_cooldown"] -= delta
		if _enemy_state_timers[eid]["caster_cooldown"] <= 0.0:
			var dist_to_player: float = player.position.distance_to(enemy.position)
			if dist_to_player <= 280.0:
				_enemy_state_timers[eid]["caster_cooldown"] = 3.5
				var proj := ColorRect.new()
				proj.size = Vector2(14, 14)
				proj.color = Color(0.6, 0.15, 0.9)
				proj.position = enemy.position - Vector2(7, 7)
				add_child(proj)
				var dmg_val: int = enemy.get_meta("damage", 10)
				var target_pos: Vector2 = player.position
				var tw := create_tween()
				tw.tween_property(proj, "position", target_pos - Vector2(7, 7), 0.7)
				tw.tween_callback(func():
					proj.queue_free()
					if player.position.distance_to(target_pos) < 50.0:
						player_health -= float(dmg_val)
						_flash_player_hit(dmg_val)
						if player_health <= 0.0:
							_on_player_death()
				)

func _fire_web_projectile(spider: Node2D) -> void:
	var proj := ColorRect.new()
	proj.size = Vector2(10, 10)
	proj.color = Color(0.85, 0.85, 0.78, 0.9)
	proj.position = spider.position - Vector2(5, 5)
	add_child(proj)
	var target_pos: Vector2 = player.position
	var dmg: int = spider.get_meta("damage", 9)
	var tw := create_tween()
	tw.tween_property(proj, "position", target_pos - Vector2(5, 5), 1.4)
	tw.tween_callback(func():
		proj.queue_free()
		if player.position.distance_to(target_pos) < 55.0:
			var web_dmg: int = maxi(1, dmg)
			player_health -= float(web_dmg)
			player.modulate = Color(0.8, 0.8, 1.0)
			var flash_tw := create_tween()
			flash_tw.tween_property(player, "modulate", Color.WHITE, 0.4)
			if player_health <= 0.0:
				_on_player_death()
	)

func _flash_player_hit(dmg: int) -> void:
	player.modulate = Color(2.0, 0.2, 0.2)
	var flash_tw := create_tween()
	flash_tw.tween_property(player, "modulate", Color.WHITE, 0.25)
	var shake_origin: Vector2 = camera.offset
	var shake_tw := create_tween()
	shake_tw.tween_property(camera, "offset", shake_origin + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
	shake_tw.tween_property(camera, "offset", shake_origin, 0.1)
	var hit_lbl := Label.new()
	hit_lbl.text = "-%d" % dmg
	hit_lbl.position = player.position + Vector2(-10, -50)
	hit_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	hit_lbl.add_theme_font_size_override("font_size", 14)
	add_child(hit_lbl)
	var hl_tw := create_tween()
	hl_tw.tween_property(hit_lbl, "position", hit_lbl.position + Vector2(0, -28), 0.5)
	hl_tw.parallel().tween_property(hit_lbl, "modulate:a", 0.0, 0.5)
	hl_tw.tween_callback(hit_lbl.queue_free)

# ── Enemy Animation ──────────────────────────────────────────────────────────

func _animate_enemies(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		var sprite: Node = enemy.find_child("Sprite", false, false)
		if sprite == null or not sprite is Sprite2D:
			continue
		var sp := sprite as Sprite2D
		var enemy_id: String = enemy.get_meta("enemy_id", "scavenger_grunt")
		var eid: int = enemy.get_instance_id()
		var phase: float = float(eid % 17) * 0.6
		var is_moving: bool = true
		if enemy.get_meta("paused", false):
			is_moving = false
		elif enemy_id == "shieldbearer":
			var not_lunging: bool = not _enemy_state_timers.get(eid, {}).get("lunging", false)
			var close_enough: bool = (player.position - enemy.position).length() < 115.0
			if not_lunging and close_enough:
				var facing: float = 1.0 if (player.position - enemy.position).x > 0.0 else -1.0
				sp.position.y = 8.0
				sp.scale = Vector2(facing * 1.85, 1.2)
				sp.rotation = 0.0
				continue
		elif enemy_id == "berserker":
			is_moving = _enemy_state_timers.get(eid, {}).get("burst_moving", true)
		elif enemy_id == "shield_wall":
			is_moving = (player.position - enemy.position).length() > 55.0

		if is_moving:
			match enemy_id:
				"berserker":
					var bob_freq := 9.0
					var bob_amp := 5.0
					sp.position.y = sin(t * bob_freq + phase) * bob_amp
					var squish := 1.0 + sin(t * bob_freq + phase) * 0.12
					sp.scale = Vector2(sign(sp.scale.x) * abs(sp.scale.x) * (1.0 / squish), abs(sp.scale.y) * squish)
				"cave_spider":
					var is_firing: bool = _enemy_state_timers.get(eid, {}).get("firing", false)
					if is_firing:
						sp.position.y = 4.0
						sp.scale = Vector2(sign(sp.scale.x) * 1.7, 1.2)
						sp.rotation = sin(t * 20.0 + phase) * 0.04
					else:
						sp.position.y = abs(sin(t * 12.0 + phase)) * 3.0
						sp.scale = Vector2(sign(sp.scale.x) * 1.6, 1.3)
						sp.rotation = sin(t * 12.0 + phase) * 0.12
				"ash_flanker":
					var lean_freq := 7.0
					sp.position.y = sin(t * lean_freq + phase) * 3.5
					sp.rotation = sin(t * lean_freq * 0.5 + phase) * 0.1
				"shieldbearer", "shield_wall":
					var plod_freq := 3.5
					sp.position.y = abs(sin(t * plod_freq + phase)) * -4.0
					sp.scale = Vector2(sign(sp.scale.x) * 1.5, 1.5)
				"warden_hunter":
					var stride_freq := 5.5
					sp.position.y = sin(t * stride_freq + phase) * 3.0
					sp.rotation = sin(t * stride_freq * 0.5 + phase) * 0.06
				"resonance_wraith":
					sp.position.y = sin(t * 2.0 + phase) * 6.0
					sp.modulate = Color(1.0, 1.0, 1.0, 0.75 + sin(t * 3.0 + phase) * 0.2)
				_:
					var walk_freq := 6.0
					sp.position.y = sin(t * walk_freq + phase) * 3.0
		else:
			sp.position.y = 0.0
			sp.rotation = 0.0
			var breathe := 1.5 + sin(t * 1.5 + phase) * 0.02
			sp.scale = Vector2(sign(sp.scale.x) * breathe, breathe)

		var to_player: Vector2 = player.position - enemy.position
		if to_player.x != 0.0:
			sp.scale.x = abs(sp.scale.x) * (1.0 if to_player.x > 0.0 else -1.0)

# ── Contact Damage ───────────────────────────────────────────────────────────

func _check_enemy_damage(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
			continue
		var enemy_id: String = enemy.get_meta("enemy_id", "scavenger_grunt")
		if enemy_id == "ridge_archer" or enemy_id == "rift_caster":
			continue
		var contact_range: float = 72.0
		if enemy_id == "shield_wall" or enemy_id == "shieldbearer":
			contact_range = 80.0
		var dist: float = player.position.distance_to(enemy.position)
		if dist < contact_range:
			var key: int = enemy.get_instance_id()
			if not damage_timers.has(key):
				damage_timers[key] = 0.0
			damage_timers[key] -= delta
			if damage_timers[key] <= 0.0:
				if enemy_id == "shieldbearer":
					var is_lunging: bool = _enemy_state_timers.get(key, {}).get("lunging", false)
					if not is_lunging:
						var shield_dmg: int = maxi(1, int(enemy.get_meta("damage", 10) * 0.5))
						player_health -= float(shield_dmg)
						damage_timers[key] = 0.6
						var e_sp: Node = enemy.find_child("Sprite", false, false)
						if e_sp and e_sp is Sprite2D:
							(e_sp as Sprite2D).modulate = Color(1.5, 1.5, 2.0)
							var sb_tw := create_tween()
							sb_tw.tween_property(e_sp, "modulate", Color.WHITE, 0.15)
						if player_health <= 0.0:
							_on_player_death()
							return
						continue
				if enemy_id == "resonance_wraith":
					if _enemy_state_timers.has(key) and _enemy_state_timers[key].get("tp_cooldown", 0.0) > 0.0:
						continue
				var dmg: int = enemy.get_meta("damage", 10)
				if enemy_id == "shield_wall":
					dmg = int(dmg * 1.5)
				elif enemy_id == "warden_hunter":
					dmg = int(dmg * 1.2)
				player_health -= float(dmg)
				damage_timers[key] = 1.0
				if enemy_id == "warden_hunter":
					if _enemy_state_timers.has(key):
						_enemy_state_timers[key]["reposition"] = 0.4

				var e_sprite: Node = enemy.find_child("Sprite", false, false)
				if e_sprite and e_sprite is Sprite2D:
					(e_sprite as Sprite2D).modulate = Color(2.0, 0.6, 0.1)
					var e_flash := create_tween()
					e_flash.tween_property(e_sprite, "modulate", Color.WHITE, 0.2)

				var slash := Line2D.new()
				slash.width = 4.0
				slash.default_color = Color(1.0, 0.5, 0.1, 0.9)
				var attack_dir: Vector2 = (player.position - enemy.position).normalized()
				var perp_a: Vector2 = Vector2(-attack_dir.y, attack_dir.x)
				slash.add_point(enemy.position + perp_a * 12.0)
				slash.add_point(enemy.position + attack_dir * 38.0)
				slash.add_point(enemy.position - perp_a * 12.0)
				add_child(slash)
				var slash_tw := create_tween()
				slash_tw.tween_property(slash, "modulate:a", 0.0, 0.18)
				slash_tw.tween_callback(slash.queue_free)

				player.modulate = Color(2.0, 0.2, 0.2)
				var flash_tw := create_tween()
				flash_tw.tween_property(player, "modulate", Color.WHITE, 0.25)

				var shake_origin: Vector2 = camera.offset
				var shake_tw := create_tween()
				shake_tw.tween_property(camera, "offset", shake_origin + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
				shake_tw.tween_property(camera, "offset", shake_origin, 0.1)

				var overlay := ColorRect.new()
				overlay.color = Color(0.8, 0.0, 0.0, 0.22)
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var ol_layer := CanvasLayer.new()
				ol_layer.add_child(overlay)
				add_child(ol_layer)
				var ol_tw := create_tween()
				ol_tw.tween_property(overlay, "color", Color(0.8, 0.0, 0.0, 0.0), 0.3)
				ol_tw.tween_callback(func(): ol_layer.queue_free())

				var hit_lbl := Label.new()
				hit_lbl.text = "-%d" % dmg
				hit_lbl.position = player.position + Vector2(-10, -50)
				hit_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
				hit_lbl.add_theme_font_size_override("font_size", 14)
				add_child(hit_lbl)
				var hl_tw := create_tween()
				hl_tw.tween_property(hit_lbl, "position", hit_lbl.position + Vector2(0, -28), 0.5)
				hl_tw.parallel().tween_property(hit_lbl, "modulate:a", 0.0, 0.5)
				hl_tw.tween_callback(hit_lbl.queue_free)

				if player_health <= 0.0:
					_on_player_death()
					return

# ── Spawn Menu ───────────────────────────────────────────────────────────────

func _open_menu() -> void:
	if _menu_open:
		return
	_menu_open = true

	menu_panel = Panel.new()
	menu_panel.name = "SpawnMenu"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style.border_color = Color(0.4, 0.35, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	menu_panel.add_theme_stylebox_override("panel", style)
	menu_panel.position = Vector2(80, 40)
	menu_panel.size = Vector2(600, 520)
	hud_layer.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.position = Vector2(0, 0)
	margin.size = Vector2(600, 520)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	menu_panel.add_child(margin)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer_vbox)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "ENEMY TEST ARENA"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Spawn enemies to test their behavior. Click an enemy to spawn one."
	subtitle_lbl.add_theme_font_size_override("font_size", 11)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(subtitle_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	outer_vbox.add_child(spacer)

	# Scroll container for enemy list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	outer_vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(list_vbox)

	var zone_labels := { "inner": "Zone 1 \u2014 Inner", "mid": "Zone 2 \u2014 Mid", "outer": "Zone 3 \u2014 Outer" }
	var zone_colors := { "inner": Color(0.3, 0.8, 0.3), "mid": Color(0.9, 0.8, 0.2), "outer": Color(0.9, 0.3, 0.3) }

	for enemy_id in ENEMY_ORDER:
		var data: Dictionary = ENEMY_DATA[enemy_id]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		list_vbox.add_child(row)

		# Enemy name
		var name_lbl := Label.new()
		name_lbl.text = enemy_id.replace("_", " ").capitalize()
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
		name_lbl.custom_minimum_size = Vector2(130, 0)
		row.add_child(name_lbl)

		# Zone badge
		var zone_lbl := Label.new()
		zone_lbl.text = zone_labels.get(data["zone"], data["zone"])
		zone_lbl.add_theme_font_size_override("font_size", 10)
		zone_lbl.add_theme_color_override("font_color", zone_colors.get(data["zone"], Color.WHITE))
		zone_lbl.custom_minimum_size = Vector2(95, 0)
		row.add_child(zone_lbl)

		# Description
		var desc_lbl := Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc_lbl)

		# Spawn button
		var spawn_btn := Button.new()
		spawn_btn.text = "Spawn"
		spawn_btn.custom_minimum_size = Vector2(60, 0)
		var eid: String = enemy_id  # capture for lambda
		spawn_btn.pressed.connect(func(): _on_spawn_pressed(eid))
		row.add_child(spawn_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	outer_vbox.add_child(spacer2)

	# Bottom buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_child(btn_row)

	var clear_btn := Button.new()
	clear_btn.text = "Clear All Enemies"
	clear_btn.pressed.connect(_on_clear_all)
	btn_row.add_child(clear_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close_menu)
	btn_row.add_child(close_btn)

func _close_menu() -> void:
	_menu_open = false
	if menu_panel != null and is_instance_valid(menu_panel):
		menu_panel.queue_free()
		menu_panel = null

func _on_spawn_pressed(enemy_id: String) -> void:
	_close_menu()
	_spawn_specific_enemy(enemy_id)

func _on_clear_all() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	damage_timers.clear()
	_enemy_state_timers.clear()
	_close_menu()
