extends Node2D

const EnemySpawner = preload("res://scripts/systems/enemy_spawner.gd")
const HomeHubScene = preload("res://scenes/hub/home_hub.tscn")
const ItemShopScene = preload("res://scenes/hub/item_shop.tscn")
const InventoryMenuScene = preload("res://scenes/hub/inventory_menu.tscn")

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
var item_shop: Node = null
var inventory_menu: Node = null

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
var _t_was_pressed: bool = false
var _i_was_pressed: bool = false
var _last_move_dir: Vector2 = Vector2.RIGHT

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
	if Input.is_action_just_pressed("attack_melee") and not _is_menu_open():
		_do_melee_attack()
		attack_cooldown = 0.5
	elif Input.is_action_just_pressed("attack_ranged"):
		_do_ranged_attack()
		attack_cooldown = 0.8

func _do_melee_attack() -> void:
	var nearest: Node2D = _get_nearest_enemy(120.0)
	var swing_dir: Vector2 = _last_move_dir
	if nearest != null:
		swing_dir = (nearest.position - player.position).normalized()
	# Sword sweep — pivot Node2D that rotates, with blade as child Line2D
	var pivot := Node2D.new()
	# Position relative to player so it moves with them
	pivot.position = swing_dir * 10.0
	pivot.rotation = atan2(swing_dir.y, swing_dir.x) - deg_to_rad(30.0)
	player.add_child(pivot)

	# Blade
	var blade := Line2D.new()
	blade.width = 5.0
	blade.default_color = Color(0.88, 0.94, 1.0)
	blade.add_point(Vector2(8, 0))
	blade.add_point(Vector2(54, 0))
	pivot.add_child(blade)

	# Guard (short crosspiece)
	var guard := Line2D.new()
	guard.width = 4.0
	guard.default_color = Color(0.75, 0.62, 0.25)
	guard.add_point(Vector2(6, -10))
	guard.add_point(Vector2(6, 10))
	pivot.add_child(guard)

	# Sweep arc over 100 degrees then fade
	var swing_tw := create_tween()
	swing_tw.tween_property(pivot, "rotation", pivot.rotation + deg_to_rad(60.0), 0.18).set_ease(Tween.EASE_OUT)
	swing_tw.tween_property(pivot, "modulate:a", 0.0, 0.08)
	swing_tw.tween_callback(pivot.queue_free)

	# Slash trail — faint white arc Line2D
	var trail := Line2D.new()
	trail.width = 18.0
	trail.default_color = Color(1.0, 1.0, 0.85, 0.35)
	# Position relative to player
	var perp := Vector2(-swing_dir.y, swing_dir.x)
	var trail_origin: Vector2 = swing_dir * 30.0
	trail.add_point(trail_origin + perp * 28.0 - swing_dir * 10.0)
	trail.add_point(trail_origin + swing_dir * 36.0)
	trail.add_point(trail_origin - perp * 28.0 - swing_dir * 10.0)
	player.add_child(trail)
	var trail_tw := create_tween()
	trail_tw.tween_property(trail, "modulate:a", 0.0, 0.18)
	trail_tw.tween_callback(trail.queue_free)

	# Deal damage — base 15 + melee_damage_bonus from equipment
	var base_dmg: int = 15
	var inv: Node = _inv()
	if inv:
		base_dmg += int(inv.get("melee_damage_bonus"))
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get_meta("alive", false):
			continue
		if player.position.distance_to(enemy.position) <= 80.0:
			_deal_damage_to_enemy(enemy, base_dmg)

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
	# Base 20 + ranged_damage_bonus from equipment
	var base_dmg: int = 20
	var inv: Node = _inv()
	if inv:
		base_dmg += int(inv.get("ranged_damage_bonus"))
	var dmg_val := base_dmg
	var tw := create_tween()
	tw.tween_property(proj, "position", nearest.position - Vector2(5, 5), 0.25)
	tw.tween_callback(func():
		proj.queue_free()
		if is_instance_valid(nearest) and nearest.get_meta("alive", false):
			_deal_damage_to_enemy(nearest, dmg_val)
	)

func _is_menu_open() -> bool:
	return home_hub != null or item_shop != null or inventory_menu != null

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
	if _is_menu_open():
		return
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
		# Apply speed bonus from equipment
		var effective_speed := player_speed
		var inv: Node = _inv()
		if inv:
			effective_speed += float(inv.get("speed_bonus"))
		player.position += norm_dir * effective_speed * delta
		_last_move_dir = norm_dir

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
				# Subtract total_defense from equipment (min 1 damage)
				var inv: Node = _inv()
				if inv:
					dmg = maxi(1, dmg - int(inv.get("total_defense")))
				player_health -= float(dmg)
				damage_timers[key] = 1.0

				# Enemy attack flash — orange glow on attacker
				var e_sprite: Node = enemy.find_child("Sprite", false, false)
				if e_sprite and e_sprite is Sprite2D:
					(e_sprite as Sprite2D).modulate = Color(2.0, 0.6, 0.1)
					var e_flash := create_tween()
					e_flash.tween_property(e_sprite, "modulate", Color.WHITE, 0.2)

				# Attack slash line from enemy toward player
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

				# Player hit flash — full red modulate
				player.modulate = Color(2.0, 0.2, 0.2)
				var flash_tw := create_tween()
				flash_tw.tween_property(player, "modulate", Color.WHITE, 0.25)

				# Screen shake — offset camera
				var cam: Camera2D = $Player/Camera2D
				var shake_origin: Vector2 = cam.offset
				var shake_tw := create_tween()
				shake_tw.tween_property(cam, "offset", shake_origin + Vector2(randf_range(-8,8), randf_range(-6,6)), 0.04)
				shake_tw.tween_property(cam, "offset", shake_origin, 0.1)

				# Red damage flash overlay on screen
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

				# Floating damage on player
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

	# Show/hide prompts near player when at home
	var bank_prompt: Node = get_node_or_null("BankPrompt")
	var shop_prompt: Node = get_node_or_null("ShopPrompt")

	if bank_prompt == null and in_sanctuary:
		var lbl := Label.new()
		lbl.name = "BankPrompt"
		lbl.text = "E — Bank"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		lbl.z_index = 10
		add_child(lbl)
		bank_prompt = lbl
	if bank_prompt != null:
		bank_prompt.visible = in_sanctuary
		if in_sanctuary:
			(bank_prompt as Label).position = player.position + Vector2(-50, -75)

	if shop_prompt == null and in_sanctuary:
		var lbl := Label.new()
		lbl.name = "ShopPrompt"
		lbl.text = "T — Shop    I — Inventory"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		lbl.z_index = 10
		add_child(lbl)
		shop_prompt = lbl
	if shop_prompt != null:
		shop_prompt.visible = in_sanctuary
		if in_sanctuary:
			(shop_prompt as Label).position = player.position + Vector2(-50, -55)

	# Open bank on E press
	var e_now: bool = Input.is_key_pressed(KEY_E)
	if in_sanctuary and e_now and not _e_was_pressed and not _is_menu_open():
		_open_home_hub()
	_e_was_pressed = e_now

	# Open shop on T press
	var t_now: bool = Input.is_key_pressed(KEY_T)
	if in_sanctuary and t_now and not _t_was_pressed and not _is_menu_open():
		_open_item_shop()
	_t_was_pressed = t_now

	# Open inventory on I press (anywhere)
	var i_now: bool = Input.is_key_pressed(KEY_I)
	if i_now and not _i_was_pressed and not _is_menu_open():
		_open_inventory_menu()
	_i_was_pressed = i_now

func _open_home_hub() -> void:
	home_hub = HomeHubScene.instantiate()
	add_child(home_hub)
	home_hub.hub_closed.connect(_on_hub_closed)

func _on_hub_closed() -> void:
	if home_hub != null:
		home_hub.queue_free()
		home_hub = null

func _open_item_shop() -> void:
	item_shop = ItemShopScene.instantiate()
	add_child(item_shop)
	item_shop.shop_closed.connect(_on_shop_closed)

func _on_shop_closed() -> void:
	if item_shop != null:
		item_shop.queue_free()
		item_shop = null

func _open_inventory_menu() -> void:
	inventory_menu = InventoryMenuScene.instantiate()
	add_child(inventory_menu)
	inventory_menu.inventory_closed.connect(_on_inventory_closed)

func _on_inventory_closed() -> void:
	if inventory_menu != null:
		inventory_menu.queue_free()
		inventory_menu = null

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
