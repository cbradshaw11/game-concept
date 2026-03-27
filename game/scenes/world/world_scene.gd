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
var damage_timers: Dictionary = {}  # enemy node -> float cooldown
var player_health := 100.0
var player_max_health := 100.0
var home_hub: Node = null

# Zone colors
var zone_colors := {
	"sanctuary": Color(0.102, 0.165, 0.227),  # #1a2a3a
	"inner": Color(0.102, 0.165, 0.102),       # #1a2a1a
	"mid": Color(0.165, 0.118, 0.039),          # #2a1e0a
	"outer": Color(0.165, 0.039, 0.039)         # #2a0a0a
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

func _process(delta: float) -> void:
	_handle_input(delta)
	_update_background(delta)
	_update_enemies(delta)
	_check_enemy_damage(delta)
	_check_loot_pickup()
	_handle_sanctuary_regen(delta)
	_handle_spawning(delta)
	_handle_hub_interaction()
	_update_hud()

func _handle_input(delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0

	if direction != 0.0:
		player.position.x += direction * player_speed * delta
		player.position.x = maxf(player.position.x, 0.0)
		WorldManager.player_distance = player.position.x

func _update_background(delta: float) -> void:
	current_bg_color = current_bg_color.lerp(target_bg_color, delta * 3.0)
	background.color = current_bg_color
	# Keep background covering viewport around camera
	background.position.x = player.position.x - 700
	background.position.y = -400

func _on_zone_changed(old_zone: String, new_zone: String) -> void:
	target_bg_color = zone_colors.get(new_zone, zone_colors["sanctuary"])
	# Pause enemies when entering sanctuary
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
		var spd: float = enemy.get_meta("speed", 80)
		var zone: String = enemy.get_meta("zone", "inner")
		var boundary: float = WorldManager.get_zone_boundary(zone) + 10.0

		# Move toward player
		var dir := sign(player.position.x - enemy.position.x)
		enemy.position.x += dir * spd * delta

		# Enforce zone inner boundary
		if enemy.position.x < boundary:
			enemy.position.x = boundary

func _check_enemy_damage(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		var dist := absf(player.position.x - enemy.position.x)
		if dist < 40.0:
			var key := enemy.get_instance_id()
			if not damage_timers.has(key):
				damage_timers[key] = 0.0
			damage_timers[key] -= delta
			if damage_timers[key] <= 0.0:
				var dmg: int = enemy.get_meta("damage", 10)
				player_health -= dmg
				damage_timers[key] = 1.0
				if player_health <= 0.0:
					_on_player_death()
					return

func _check_loot_pickup() -> void:
	var to_remove: Array[int] = []
	for i in range(loot_drops.size() - 1, -1, -1):
		var loot := loot_drops[i]
		if not is_instance_valid(loot):
			loot_drops.remove_at(i)
			continue
		if absf(player.position.x - loot.position.x) < 30.0:
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
	var zone_enemies := _count_zone_enemies(zone)
	if zone_enemies >= max_count:
		return
	# Spawn at far edge of current zone beyond player
	var zone_end := _get_zone_end(zone)
	var spawn_x := maxf(player.position.x + 300.0, WorldManager.get_zone_boundary(zone) + 50.0)
	spawn_x = minf(spawn_x, zone_end - 20.0)
	var spawn_pos := Vector2(spawn_x, player.position.y)
	var enemy := spawner.spawn_enemy(zone, spawn_pos, enemy_container)
	if enemy != null:
		enemies.append(enemy)
	spawn_timer = SPAWN_INTERVAL

func _count_zone_enemies(zone: String) -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get_meta("alive", false) and enemy.get_meta("zone", "") == zone:
			count += 1
	return count

func _get_zone_end(zone: String) -> float:
	match zone:
		"inner":
			return WorldManager.MID_START
		"mid":
			return WorldManager.OUTER_START
		"outer":
			return WorldManager.OUTER_START + 500.0
		_:
			return WorldManager.INNER_START

func _on_player_death() -> void:
	InventorySystem.on_player_death(player.position)
	player.position.x = 0.0
	player_health = player_max_health
	WorldManager.player_distance = 0.0
	# Clean up damage timers
	damage_timers.clear()

func _on_inventory_dropped(gold: int, _items: Array, drop_position: Vector2) -> void:
	if gold <= 0:
		return
	var loot := Node2D.new()
	loot.position = drop_position
	loot.set_meta("gold", gold)
	var rect := ColorRect.new()
	rect.size = Vector2(16, 16)
	rect.position = Vector2(-8, -16)
	rect.color = Color(0.9, 0.8, 0.2)  # Gold color
	loot.add_child(rect)
	var lbl := Label.new()
	lbl.text = str(gold) + "g"
	lbl.position = Vector2(-10, -32)
	lbl.add_theme_font_size_override("font_size", 10)
	loot.add_child(lbl)
	loot_container.add_child(loot)
	loot_drops.append(loot)

func _handle_hub_interaction() -> void:
	if WorldManager.current_zone == "sanctuary" and player.position.x < 50.0:
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
	_add_zone_marker(WorldManager.INNER_START, "INNER")
	_add_zone_marker(WorldManager.MID_START, "MID")
	_add_zone_marker(WorldManager.OUTER_START, "OUTER")

func _add_zone_marker(x_pos: float, text: String) -> void:
	var marker := Node2D.new()
	marker.position = Vector2(x_pos, 0)
	var line := ColorRect.new()
	line.size = Vector2(2, 400)
	line.position = Vector2(-1, -200)
	line.color = Color(1, 1, 1, 0.3)
	marker.add_child(line)
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(5, -200)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	marker.add_child(lbl)
	zone_markers.add_child(marker)

func _update_hud() -> void:
	if not is_inside_tree():
		return
	var hp_ratio := player_health / player_max_health
	health_bar.size.x = 200.0 * hp_ratio
	health_bar.color = Color(0.2, 0.8, 0.2) if hp_ratio > 0.3 else Color(0.8, 0.2, 0.2)
	zone_label.text = "Zone: %s" % WorldManager.current_zone.capitalize()
	gold_label.text = "Carried: %dg" % InventorySystem.carried_gold
	bank_label.text = "Bank: %dg" % InventorySystem.bank_gold
	distance_label.text = "Distance: %d" % int(WorldManager.player_distance)
