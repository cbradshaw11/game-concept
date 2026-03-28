extends Node2D

const EnemySpawner = preload("res://scripts/systems/enemy_spawner.gd")
const HomeHubScene = preload("res://scenes/hub/home_hub.tscn")

var player_speed := 200.0
var spawner := EnemySpawner.new()
var spawn_timer := 0.0
const SPAWN_INTERVAL := 3.0
var max_enemies_per_zone := { "inner": 3, "mid": 4, "outer": 5 }
var enemies: Array[Node2D] = []
var loot_drops: Array[Node2D] = []
var damage_timers: Dictionary = {}
var player_health := 100.0
var player_max_health := 100.0
var home_hub: Node = null

const HOME_POS := Vector2.ZERO

# Zone colors
var zone_colors := {
	"sanctuary": Color(0.102, 0.165, 0.227),
	"inner":     Color(0.102, 0.165, 0.102),
	"mid":       Color(0.165, 0.118, 0.039),
	"outer":     Color(0.165, 0.039, 0.039)
}
var current_bg_color: Color = Color(0.102, 0.165, 0.227)
var target_bg_color: Color = Color(0.102, 0.165, 0.227)

@onready var player: Sprite2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var background: ColorRect = $Background
@onready var hud_layer: CanvasLayer = $HUD
@onready var health_bar: ColorRect = $HUD/HealthBar
@onready var health_bar_bg: ColorRect = $HUD/HealthBarBG
@onready var zone_label: Label = $HUD/ZoneLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var bank_label: Label = $HUD/BankLabel
@onready var distance_label: Label = $HUD/DistanceLabel
@onready var home_marker: Node2D = $HomeMarker
@onready var enemy_container: Node2D = $EnemyContainer
@onready var loot_container: Node2D = $LootContainer
@onready var zone_markers: Node2D = $ZoneMarkers

# Autoload accessors — safe fallback if autoloads aren't cached yet
var _world_manager: Node = null
var _inventory: Node = null
func _wm() -> Node:
	if _world_manager == null:
		_world_manager = get_node_or_null("/root/WorldManager")
	return _world_manager
func _inv() -> Node:
	if _inventory == null:
		_inventory = get_node_or_null("/root/InventorySystem")
	return _inventory

func _ready() -> void:
	_setup_zone_markers()
	_wm().zone_changed.connect(_on_zone_changed)
	_inv().inventory_dropped.connect(_on_inventory_dropped)
	_inv().inventory_changed.connect(_update_hud)
	_inv().bank_changed.connect(_update_hud)
	_update_hud()
	target_bg_color = zone_colors["sanctuary"]
	current_bg_color = target_bg_color
	player.position = HOME_POS

var attack_cooldown: float = 0.0
var _e_was_pressed: bool = false

func _process(delta: float) -> void:
	_handle_input(delta)
	_handle_attack(delta)
	_update_background(delta)
	_update_enemies(delta)
	_check_enemy_damage(delta)
	_check_loot_pickup()
	_handle_sanctuary_regen(delta)
	_handle_spawning(delta)
	_handle_hub_interaction()
	# Update distance as 2D from home
	var dist: float = player.position.distance_to(HOME_POS)
	_wm().player_distance = dist
	_update_hud()

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

func _do_melee_attack() -> void:
	# Lunge player sprite forward toward nearest enemy
	var nearest: Node2D = _get_nearest_enemy(120.0)
	var lunge_dir := Vector2.RIGHT
	if nearest != null:
		lunge_dir = (nearest.position - player.position).normalized()
	var origin: Vector2 = player.position
	var tw := create_tween()
	tw.tween_property(player, "position", origin + lunge_dir * 18.0, 0.07)
	tw.tween_property(player, "position", origin, 0.1)

	# Sword arc — white/yellow Line2D that fades out
	var arc := Line2D.new()
	arc.width = 3.0
	arc.default_color = Color(1.0, 0.95, 0.5, 1.0)
	var arc_origin: Vector2 = player.position + lunge_dir * 10.0
	var perp := Vector2(-lunge_dir.y, lunge_dir.x)
	arc.add_point(arc_origin + perp * 20.0)
	arc.add_point(arc_origin + lunge_dir * 40.0)
	arc.add_point(arc_origin - perp * 20.0)
	add_child(arc)
	var arc_tw := create_tween()
	arc_tw.tween_property(arc, "modulate:a", 0.0, 0.15)
	arc_tw.tween_callback(arc.queue_free)

	# Deal damage to enemies in range
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if player.position.distance_to(enemy.position) <= 80.0:
			_deal_damage_to_enemy(enemy, 15)

func _do_ranged_attack() -> void:
	var nearest: Node2D = _get_nearest_enemy(500.0)
	if nearest == null:
		return
	# Spawn a white projectile that flies to the enemy
	var proj := ColorRect.new()
	proj.size = Vector2(10, 10)
	proj.color = Color(0.9, 0.95, 1.0)
	proj.position = player.position - Vector2(5, 5)
	add_child(proj)
	var tw := create_tween()
	tw.tween_property(proj, "position", nearest.position - Vector2(5, 5), 0.25)
	tw.tween_callback(func():
		proj.queue_free()
		if is_instance_valid(nearest) and nearest.get_meta("alive", false):
			_deal_damage_to_enemy(nearest, 20)
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

func _deal_damage_to_enemy(enemy: Node2D, dmg: int) -> void:
	var hp: int = enemy.get_meta("hp", 0)
	var max_hp: int = enemy.get_meta("max_hp", 1)
	hp = max(0, hp - dmg)
	enemy.set_meta("hp", hp)

	# Update HP bar
	var hp_bar: Node = enemy.find_child("HPBar", false, false)
	if hp_bar and hp_bar is ColorRect:
		var ratio: float = float(hp) / float(max_hp)
		(hp_bar as ColorRect).size.x = 48.0 * ratio
		(hp_bar as ColorRect).color = Color(0.2, 0.85, 0.2) if ratio > 0.4 else Color(0.85, 0.2, 0.2)

	# Flash sprite red
	var sprite: Node = enemy.find_child("Sprite", false, false)
	if sprite and sprite is Sprite2D:
		(sprite as Sprite2D).modulate = Color(1.5, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_interval(0.1)
		tw.tween_callback(func(): if is_instance_valid(sprite): (sprite as Sprite2D).modulate = Color.WHITE)

	# Floating damage number
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
	# Drop loot
	var gold: int = randi_range(5, 20)
	var loot := Node2D.new()
	loot.position = enemy.position
	loot.set_meta("gold", gold)
	var rect := ColorRect.new()
	rect.size = Vector2(16, 16)
	rect.position = Vector2(-8, -8)
	rect.color = Color(0.9, 0.8, 0.2)
	loot.add_child(rect)
	var lbl := Label.new()
	lbl.text = str(gold) + "g"
	lbl.position = Vector2(-10, -28)
	lbl.add_theme_font_size_override("font_size", 10)
	loot.add_child(lbl)
	loot_container.add_child(loot)
	loot_drops.append(loot)
	# Fade out and remove enemy
	var tw := create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 0.3)
	tw.tween_callback(enemy.queue_free)

func _handle_input(delta: float) -> void:
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
		player.position += dir.normalized() * player_speed * delta

func _update_background(delta: float) -> void:
	current_bg_color = current_bg_color.lerp(target_bg_color, delta * 3.0)
	background.color = current_bg_color
	background.position = player.position - Vector2(700, 400)

func _on_zone_changed(old_zone: String, new_zone: String) -> void:
	target_bg_color = zone_colors.get(new_zone, zone_colors["sanctuary"])
	if new_zone == "sanctuary":
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.set_meta("paused", true)
	elif old_zone == "sanctuary":
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.set_meta("paused", false)

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
			continue
		var spd: float = enemy.get_meta("speed", 80.0)
		var zone: String = enemy.get_meta("zone", "inner")
		var boundary_radius: float = _wm().get_zone_boundary(zone)

		# Move toward player in 2D
		var to_player: Vector2 = player.position - enemy.position
		if to_player.length() > 1.0:
			enemy.position += to_player.normalized() * spd * delta

		# Enforce zone boundary — enemy can't go closer to home than its zone start
		var enemy_dist: float = enemy.position.distance_to(HOME_POS)
		if enemy_dist < boundary_radius:
			# Push back out to boundary edge
			var push_dir: Vector2 = (enemy.position - HOME_POS).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			enemy.position = HOME_POS + push_dir * (boundary_radius + 10.0)

func _check_enemy_damage(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
			continue
		var dist: float = player.position.distance_to(enemy.position)
		if dist < 40.0:
			var key: int = enemy.get_instance_id()
			if not damage_timers.has(key):
				damage_timers[key] = 0.0
			damage_timers[key] -= delta
			if damage_timers[key] <= 0.0:
				var dmg: int = enemy.get_meta("damage", 10)
				player_health -= float(dmg)
				damage_timers[key] = 1.0
				# Flash player red
				player.modulate = Color(1.5, 0.3, 0.3)
				var tw := create_tween()
				tw.tween_interval(0.15)
				tw.tween_callback(func(): if is_instance_valid(player): player.modulate = Color.WHITE)
				if player_health <= 0.0:
					_on_player_death()
					return

func _check_loot_pickup() -> void:
	for i in range(loot_drops.size() - 1, -1, -1):
		var loot: Node2D = loot_drops[i]
		if not is_instance_valid(loot):
			loot_drops.remove_at(i)
			continue
		if player.position.distance_to(loot.position) < 40.0:
			var gold: int = loot.get_meta("gold", 0)
			_inv().add_carried_gold(gold)
			loot.queue_free()
			loot_drops.remove_at(i)

func _handle_sanctuary_regen(delta: float) -> void:
	if _wm().current_zone == "sanctuary" and player_health < player_max_health:
		player_health = minf(player_health + player_max_health * 0.05 * delta, player_max_health)

func _handle_spawning(delta: float) -> void:
	var zone: String = str(_wm().current_zone)
	if zone == "sanctuary":
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	var max_count: int = max_enemies_per_zone.get(zone, 3)
	if _count_zone_enemies(zone) >= max_count:
		return
	# Spawn ahead of player (in the direction away from home)
	var away_dir: Vector2 = (player.position - HOME_POS).normalized()
	if away_dir == Vector2.ZERO:
		away_dir = Vector2.RIGHT
	var spawn_pos: Vector2 = player.position + away_dir * 300.0
	var enemy: Node2D = spawner.spawn_enemy(zone, spawn_pos, enemy_container)
	if enemy != null:
		enemies.append(enemy)
	spawn_timer = SPAWN_INTERVAL

func _count_zone_enemies(zone: String) -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get_meta("alive", false) and enemy.get_meta("zone", "") == zone:
			count += 1
	return count

func _on_player_death() -> void:
	_inv().on_player_death(player.position)
	player.position = HOME_POS
	player_health = player_max_health
	_wm().player_distance = 0.0
	damage_timers.clear()

func _on_inventory_dropped(gold: int, _items: Array, drop_position: Vector2) -> void:
	if gold <= 0:
		return
	var loot := Node2D.new()
	loot.position = drop_position
	loot.set_meta("gold", gold)
	var rect := ColorRect.new()
	rect.size = Vector2(16, 16)
	rect.position = Vector2(-8, -8)
	rect.color = Color(0.9, 0.8, 0.2)
	loot.add_child(rect)
	var lbl := Label.new()
	lbl.text = str(gold) + "g"
	lbl.position = Vector2(-10, -28)
	lbl.add_theme_font_size_override("font_size", 10)
	loot.add_child(lbl)
	loot_container.add_child(loot)
	loot_drops.append(loot)

func _handle_hub_interaction() -> void:
	var in_sanctuary: bool = str(_wm().current_zone) == "sanctuary"
	# Show/hide "Press E — Bank" prompt near player when at home
	var prompt: Node = get_node_or_null("BankPrompt")
	if prompt == null and in_sanctuary:
		var lbl := Label.new()
		lbl.name = "BankPrompt"
		lbl.text = "Press E — Bank"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		lbl.z_index = 10
		add_child(lbl)
	elif prompt != null:
		prompt.visible = in_sanctuary
		if in_sanctuary:
			(prompt as Label).position = player.position + Vector2(-50, -75)
	# Open bank on E press
	var e_now: bool = Input.is_key_pressed(KEY_E)
	if in_sanctuary and e_now and not _e_was_pressed and home_hub == null:
		_open_home_hub()
	_e_was_pressed = e_now

func _open_home_hub() -> void:
	home_hub = HomeHubScene.instantiate()
	add_child(home_hub)
	home_hub.hub_closed.connect(_on_hub_closed)

func _on_hub_closed() -> void:
	if home_hub != null:
		home_hub.queue_free()
		home_hub = null

func _setup_zone_markers() -> void:
	# Draw concentric circle markers for each zone boundary
	_add_circle_marker(200.0, "INNER", Color(0.4, 0.8, 0.4, 0.4))
	_add_circle_marker(500.0, "MID", Color(0.8, 0.6, 0.2, 0.4))
	_add_circle_marker(900.0, "OUTER", Color(0.8, 0.2, 0.2, 0.4))

func _add_circle_marker(radius: float, text: String, color: Color) -> void:
	# Use a label at the right edge of the radius
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(radius + 5.0, -10.0)
	lbl.add_theme_color_override("font_color", color)
	zone_markers.add_child(lbl)
	# Add a home label
	if text == "INNER":
		var home_lbl := Label.new()
		home_lbl.text = "HOME"
		home_lbl.position = Vector2(-20.0, -40.0)
		home_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0, 0.9))
		zone_markers.add_child(home_lbl)

func _update_hud() -> void:
	if not is_inside_tree():
		return
	var hp_ratio: float = player_health / player_max_health
	health_bar.size.x = 200.0 * hp_ratio
	health_bar.color = Color(0.2, 0.8, 0.2) if hp_ratio > 0.3 else Color(0.8, 0.2, 0.2)
	zone_label.text = "Zone: %s" % _wm().current_zone.capitalize()
	gold_label.text = "Carried: %dg" % _inv().carried_gold
	bank_label.text = "Bank: %dg" % _inv().bank_gold
	distance_label.text = "Move: WASD  |  Melee: Z/Click  |  Ranged: Q  |  Distance: %d" % int(_wm().player_distance)
