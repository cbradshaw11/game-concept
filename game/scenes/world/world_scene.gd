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

func _ready() -> void:
	_setup_zone_markers()
	WorldManager.zone_changed.connect(_on_zone_changed)
	InventorySystem.inventory_dropped.connect(_on_inventory_dropped)
	InventorySystem.inventory_changed.connect(_update_hud)
	InventorySystem.bank_changed.connect(_update_hud)
	_update_hud()
	target_bg_color = zone_colors["sanctuary"]
	current_bg_color = target_bg_color
	player.position = HOME_POS

var attack_cooldown: float = 0.0

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
	WorldManager.player_distance = dist
	_update_hud()

func _handle_attack(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown > 0.0:
		return
	var did_attack := false
	if Input.is_action_just_pressed("attack_melee"):
		# Melee — hit enemies within 80px
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
				continue
			if player.position.distance_to(enemy.position) <= 80.0:
				_deal_damage_to_enemy(enemy, 15)
		did_attack = true
		attack_cooldown = 0.5
	elif Input.is_action_just_pressed("attack_ranged"):
		# Ranged — hit nearest enemy within 400px
		var nearest: Node2D = null
		var nearest_dist := 400.0
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
				continue
			var d: float = player.position.distance_to(enemy.position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = enemy
		if nearest != null:
			_deal_damage_to_enemy(nearest, 20)
		did_attack = true
		attack_cooldown = 0.8

func _deal_damage_to_enemy(enemy: Node2D, dmg: int) -> void:
	var hp: int = enemy.get_meta("hp", 0)
	hp -= dmg
	enemy.set_meta("hp", hp)
	# Flash red briefly
	var sprite: ColorRect = enemy.get_child(0) if enemy.get_child_count() > 0 else null
	if sprite and sprite is ColorRect:
		var orig: Color = sprite.color
		sprite.color = Color(1, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_callback(func(): if is_instance_valid(sprite): sprite.color = orig)
	# Show damage number
	var lbl := Label.new()
	lbl.text = "-%d" % dmg
	lbl.position = enemy.position + Vector2(-10, -30)
	lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	lbl.add_theme_font_size_override("font_size", 12)
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
		var boundary_radius: float = WorldManager.get_zone_boundary(zone)

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
			InventorySystem.add_carried_gold(gold)
			loot.queue_free()
			loot_drops.remove_at(i)

func _handle_sanctuary_regen(delta: float) -> void:
	if WorldManager.current_zone == "sanctuary" and player_health < player_max_health:
		player_health = minf(player_health + player_max_health * 0.05 * delta, player_max_health)

func _handle_spawning(delta: float) -> void:
	var zone := WorldManager.current_zone
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
	InventorySystem.on_player_death(player.position)
	player.position = HOME_POS
	player_health = player_max_health
	WorldManager.player_distance = 0.0
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
	if WorldManager.current_zone == "sanctuary":
		if Input.is_action_just_pressed("interact") and home_hub == null:
			_open_home_hub()

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
	_add_circle_marker(WorldManager.INNER_START, "INNER", Color(0.4, 0.8, 0.4, 0.4))
	_add_circle_marker(WorldManager.MID_START, "MID", Color(0.8, 0.6, 0.2, 0.4))
	_add_circle_marker(WorldManager.OUTER_START, "OUTER", Color(0.8, 0.2, 0.2, 0.4))

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
	zone_label.text = "Zone: %s" % WorldManager.current_zone.capitalize()
	gold_label.text = "Carried: %dg" % InventorySystem.carried_gold
	bank_label.text = "Bank: %dg" % InventorySystem.bank_gold
	distance_label.text = "Move: WASD  |  Melee: Z/Click  |  Ranged: Q  |  Distance: %d" % int(WorldManager.player_distance)
