extends Node2D

const EnemySpawner = preload("res://scripts/systems/enemy_spawner.gd")
const UnifiedMenuScene = preload("res://scenes/hub/unified_menu.tscn")

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
var unified_menu: Node = null

# Mini-map state
var explored_positions := PackedVector2Array()
var explore_timer: float = 0.0
const EXPLORE_INTERVAL := 0.5
const EXPLORE_MAX := 5000
var minimap_expanded: bool = false
var minimap_control: Control = null
var minimap_expanded_control: Control = null

# Potion speed buff
var potion_speed_bonus: float = 0.0
var speed_buff_timer: float = 0.0

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
	_setup_home_icon()
	_setup_minimap()
	_wm().zone_changed.connect(_on_zone_changed)
	_inv().inventory_dropped.connect(_on_inventory_dropped)
	_inv().inventory_changed.connect(_update_hud)
	_inv().bank_changed.connect(_update_hud)
	_inv().potion_used.connect(_on_potion_used)
	_setup_potion_hud()
	# Make zone label subtle — small font at bottom of screen
	zone_label.add_theme_font_size_override("font_size", 10)
	zone_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	_update_hud()
	target_bg_color = zone_colors["sanctuary"]
	# DEV: start with gold for testing the shop/menu
	_inv().add_carried_gold(500)
	_inv().bank_gold = 500
	current_bg_color = target_bg_color
	player.position = HOME_POS

var attack_cooldown: float = 0.0
var _e_was_pressed: bool = false
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
	_handle_potion_input()
	_tick_speed_buff(delta)
	# Update distance as 2D from home
	var dist: float = player.position.distance_to(HOME_POS)
	_wm().player_distance = dist
	_update_hud()
	# Mini-map: track explored positions
	explore_timer -= delta
	if explore_timer <= 0.0:
		explore_timer = EXPLORE_INTERVAL
		if explored_positions.size() >= EXPLORE_MAX:
			explored_positions.remove_at(0)
		explored_positions.append(player.position)
	# Redraw minimaps
	if minimap_control != null:
		minimap_control.queue_redraw()
	if minimap_expanded_control != null and minimap_expanded:
		minimap_expanded_control.queue_redraw()

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
	return unified_menu != null

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
		effective_speed += potion_speed_bonus
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

	# Show/hide prompt near player when at home
	var menu_prompt: Node = get_node_or_null("MenuPrompt")

	if menu_prompt == null and in_sanctuary:
		var lbl := Label.new()
		lbl.name = "MenuPrompt"
		lbl.text = "E — Menu"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		lbl.z_index = 10
		add_child(lbl)
		menu_prompt = lbl
	if menu_prompt != null:
		menu_prompt.visible = in_sanctuary
		if in_sanctuary:
			(menu_prompt as Label).position = player.position + Vector2(-50, -75)

	# E at home → unified menu, default Shop tab
	var e_now: bool = Input.is_key_pressed(KEY_E)
	if in_sanctuary and e_now and not _e_was_pressed and not _is_menu_open():
		_open_unified_menu(true, 0)
	_e_was_pressed = e_now

	# I anywhere → unified menu, default Inventory tab
	var i_now: bool = Input.is_key_pressed(KEY_I)
	if i_now and not _i_was_pressed and not _is_menu_open():
		_open_unified_menu(in_sanctuary, 1)
	_i_was_pressed = i_now

func _open_unified_menu(at_home: bool, default_tab: int) -> void:
	unified_menu = UnifiedMenuScene.instantiate()
	unified_menu.at_home = at_home
	unified_menu.default_tab = default_tab
	add_child(unified_menu)
	unified_menu.menu_closed.connect(_on_unified_menu_closed)

func _on_unified_menu_closed() -> void:
	if unified_menu != null:
		unified_menu.queue_free()
		unified_menu = null


func _setup_zone_markers() -> void:
	# Sanctuary ground overlay — faint filled circle
	var sanctuary_fill := Polygon2D.new()
	var fill_points := PackedVector2Array()
	var fill_count := 120
	for i in range(fill_count):
		var angle: float = TAU * float(i) / float(fill_count)
		fill_points.append(Vector2(cos(angle), sin(angle)) * 300.0)
	sanctuary_fill.polygon = fill_points
	sanctuary_fill.color = Color(0.2, 0.4, 0.8, 0.08)
	zone_markers.add_child(sanctuary_fill)
	# Draw colored ring outlines
	_add_ring_outline(300.0, Color(0.4, 0.9, 0.4, 0.25))
	_add_ring_outline(2000.0, Color(0.9, 0.7, 0.2, 0.25))
	_add_ring_outline(2400.0, Color(0.9, 0.2, 0.2, 0.25))

func _add_ring_outline(radius: float, color: Color) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	var point_count := 120
	for i in range(point_count + 1):
		var angle: float = TAU * float(i) / float(point_count)
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	zone_markers.add_child(line)

func _setup_home_icon() -> void:
	# House base — filled square
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-10, -4), Vector2(10, -4), Vector2(10, 16), Vector2(-10, 16)
	])
	base.color = Color(0.85, 0.75, 0.5, 0.9)
	home_marker.add_child(base)
	# Roof — filled triangle
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-13, -4), Vector2(0, -16), Vector2(13, -4)
	])
	roof.color = Color(0.6, 0.35, 0.2, 0.9)
	home_marker.add_child(roof)
	# Door — small dark rectangle
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(-3, 8), Vector2(3, 8), Vector2(3, 16), Vector2(-3, 16)
	])
	door.color = Color(0.2, 0.15, 0.1, 0.9)
	home_marker.add_child(door)

# ── Mini-map ──────────────────────────────────────────

func _setup_minimap() -> void:
	# Mini-map container
	var panel := Panel.new()
	panel.name = "MinimapPanel"
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -170.0
	panel.offset_top = 10.0
	panel.offset_right = -10.0
	panel.offset_bottom = 170.0
	# Dark background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	style.border_color = Color(0.6, 0.6, 0.6, 0.6)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	panel.clip_contents = true
	hud_layer.add_child(panel)

	minimap_control = Control.new()
	minimap_control.name = "MinimapDraw"
	minimap_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minimap_control.draw.connect(_draw_minimap.bind(minimap_control, 160.0))
	minimap_control.gui_input.connect(_on_minimap_click)
	minimap_control.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(minimap_control)

	# "M" hint label
	var hint := Label.new()
	hint.text = "M"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	hint.position = Vector2(2, 0)
	minimap_control.add_child(hint)

	# Expanded map (hidden by default)
	var exp_panel := Panel.new()
	exp_panel.name = "ExpandedMapPanel"
	exp_panel.anchor_left = 0.5
	exp_panel.anchor_top = 0.5
	exp_panel.anchor_right = 0.5
	exp_panel.anchor_bottom = 0.5
	exp_panel.offset_left = -170.0
	exp_panel.offset_top = -185.0
	exp_panel.offset_right = 170.0
	exp_panel.offset_bottom = 170.0
	var exp_style := StyleBoxFlat.new()
	exp_style.bg_color = Color(0.04, 0.04, 0.06, 0.92)
	exp_style.border_color = Color(0.7, 0.7, 0.7, 0.7)
	exp_style.set_border_width_all(2)
	exp_panel.add_theme_stylebox_override("panel", exp_style)
	exp_panel.clip_contents = true
	exp_panel.visible = false
	hud_layer.add_child(exp_panel)

	# Title
	var title := Label.new()
	title.text = "Map"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 2)
	title.size = Vector2(340, 25)
	exp_panel.add_child(title)

	minimap_expanded_control = Control.new()
	minimap_expanded_control.name = "ExpandedMapDraw"
	minimap_expanded_control.position = Vector2(10, 30)
	minimap_expanded_control.size = Vector2(320, 320)
	minimap_expanded_control.draw.connect(_draw_minimap.bind(minimap_expanded_control, 320.0))
	minimap_expanded_control.gui_input.connect(_on_expanded_map_click)
	minimap_expanded_control.mouse_filter = Control.MOUSE_FILTER_STOP
	exp_panel.add_child(minimap_expanded_control)

func _draw_minimap(control: Control, map_size: float) -> void:
	# Map is player-centered. Scale: show ~800 world units around the player
	var view_radius: float = 800.0
	var scale_factor: float = (map_size * 0.5) / view_radius
	var center := Vector2(map_size / 2.0, map_size / 2.0)
	var cam_origin: Vector2 = player.position  # map center tracks player

	# Explored areas (fog of war reveal)
	for pos in explored_positions:
		var map_pos: Vector2 = (pos - cam_origin) * scale_factor + center
		if map_pos.x >= -10.0 and map_pos.x <= map_size + 10.0 and map_pos.y >= -10.0 and map_pos.y <= map_size + 10.0:
			control.draw_circle(map_pos, 6.0 * (map_size / 160.0), Color(0.3, 0.5, 0.3, 0.5))

	# Zone ring outlines (drawn relative to HOME_POS, which moves as cam moves)
	var rings := [
		[300.0, Color(0.4, 0.9, 0.4, 0.35)],
		[2000.0, Color(0.9, 0.7, 0.2, 0.35)],
		[2400.0, Color(0.9, 0.2, 0.2, 0.35)],
	]
	for ring_data in rings:
		var r: float = ring_data[0] * scale_factor
		var ring_center: Vector2 = (HOME_POS - cam_origin) * scale_factor + center
		control.draw_arc(ring_center, r, 0.0, TAU, 80, ring_data[1], 1.5)

	# Home icon — small square, positioned relative to camera
	var home_map: Vector2 = (HOME_POS - cam_origin) * scale_factor + center
	if home_map.x >= -6 and home_map.x <= map_size + 6 and home_map.y >= -6 and home_map.y <= map_size + 6:
		control.draw_rect(Rect2(home_map - Vector2(4, 4), Vector2(8, 8)), Color(0.85, 0.75, 0.5, 0.9))
		control.draw_rect(Rect2(home_map - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 1.0, 1.0, 0.5), false, 1.0)

	# Player dot — always at center of map
	var dot_r: float = 3.5 * (map_size / 160.0)
	control.draw_circle(center, dot_r, Color(1.0, 1.0, 0.3, 1.0))

func _on_minimap_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		minimap_expanded = true
		var exp_panel: Node = hud_layer.get_node_or_null("ExpandedMapPanel")
		if exp_panel:
			exp_panel.visible = true

func _on_expanded_map_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		minimap_expanded = false
		var exp_panel: Node = hud_layer.get_node_or_null("ExpandedMapPanel")
		if exp_panel:
			exp_panel.visible = false

# ── Potion system ──────────────────────────────────────

var _h_was_pressed: bool = false
var potion_hud_label: Label = null

func _setup_potion_hud() -> void:
	potion_hud_label = Label.new()
	potion_hud_label.add_theme_font_size_override("font_size", 12)
	potion_hud_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	potion_hud_label.anchor_left = 0.0
	potion_hud_label.anchor_top = 1.0
	potion_hud_label.anchor_right = 1.0
	potion_hud_label.anchor_bottom = 1.0
	potion_hud_label.offset_top = -30.0
	potion_hud_label.offset_bottom = 0.0
	potion_hud_label.offset_left = 10.0
	potion_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_layer.add_child(potion_hud_label)

func _update_potion_hud() -> void:
	if potion_hud_label == null:
		return
	var inv: Node = _inv()
	if inv == null:
		potion_hud_label.text = ""
		return
	var potions: Array = inv.get_all_potions()
	if potions.size() == 0:
		potion_hud_label.text = ""
		return
	var parts: Array = []
	for stack in potions:
		var short_name: String = _potion_short_name(stack["item"])
		parts.append("[%s x%d]" % [short_name, stack["count"]])
	potion_hud_label.text = "H=Heal  |  Potions: %s" % " ".join(parts)

func _potion_short_name(item: Dictionary) -> String:
	var n: String = item.get("name", "?")
	if n.begins_with("Small"):
		return "Heal S"
	if n.begins_with("Large"):
		return "Heal L"
	if n.find("Speed") >= 0:
		return "Speed"
	return n.substr(0, 8)

func _handle_potion_input() -> void:
	if _is_menu_open():
		return
	var h_now: bool = Input.is_key_pressed(KEY_H)
	if h_now and not _h_was_pressed:
		_use_healing_potion()
	_h_was_pressed = h_now

func _use_healing_potion() -> void:
	var inv: Node = _inv()
	if inv == null:
		return
	# Prefer small heal first, then large
	for pid in ["potion_heal_small", "potion_heal_large"]:
		if inv.get_potion_stack(pid).size() > 0:
			inv.use_potion(pid)
			return

func _on_potion_used(potion_id: String, item: Dictionary) -> void:
	if item.has("heal_amount"):
		var heal: float = float(item.get("heal_amount"))
		player_health = minf(player_health + heal, player_max_health)
	if item.has("speed_bonus") and item.has("duration"):
		potion_speed_bonus = float(item.get("speed_bonus"))
		speed_buff_timer = float(item.get("duration"))
	# Floating label
	var msg: String = "Used %s" % item.get("name", "Potion")
	if item.has("heal_amount"):
		msg += " +%d HP" % int(item.get("heal_amount"))
	_show_potion_toast(msg)

func _tick_speed_buff(delta: float) -> void:
	if speed_buff_timer > 0.0:
		speed_buff_timer -= delta
		if speed_buff_timer <= 0.0:
			potion_speed_bonus = 0.0
			speed_buff_timer = 0.0

func _show_potion_toast(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	lbl.anchor_left = 0.5
	lbl.anchor_top = 0.3
	lbl.offset_left = -100.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tw.tween_callback(lbl.queue_free)

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
	_update_potion_hud()
