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
var _enemy_state_timers: Dictionary = {}
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

# Ring gate system
var held_keys: Array[String] = []
var inner_gate_node: Node2D = null
var mid_gate_node: Node2D = null
var _f_was_pressed: bool = false

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
	_update_archer_attacks(delta)
	_update_caster_attacks(delta)
	_check_enemy_damage(delta)
	_check_loot_pickup()
	_handle_sanctuary_regen(delta)
	_handle_spawning(delta)
	_handle_hub_interaction()
	_handle_gate_interaction()
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
	if _wm().current_zone == "sanctuary":
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
	# Drop loot — gold
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
	# Key drop — 8% chance from inner/mid zone enemies
	var enemy_zone: String = enemy.get_meta("zone", "")
	var key_id := ""
	if enemy_zone == "inner" and _wm().is_ring_locked("inner_gate"):
		key_id = "inner_gate"
	elif enemy_zone == "mid" and _wm().is_ring_locked("mid_gate"):
		key_id = "mid_gate"
	if key_id != "" and randf() < 0.08:
		var key_loot := Node2D.new()
		key_loot.position = enemy.position + Vector2(20, 0)
		key_loot.set_meta("gold", 0)
		key_loot.set_meta("key_id", key_id)
		var key_rect := ColorRect.new()
		key_rect.size = Vector2(16, 16)
		key_rect.position = Vector2(-8, -8)
		key_rect.color = Color(1.0, 0.85, 0.1)
		key_loot.add_child(key_rect)
		var key_lbl := Label.new()
		var key_name: String = "Inner Key" if key_id == "inner_gate" else "Mid Key"
		key_lbl.text = key_name
		key_lbl.position = Vector2(-20, -28)
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		key_loot.add_child(key_lbl)
		loot_container.add_child(key_loot)
		loot_drops.append(key_loot)
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
		# Hard world boundary — clamp player inside outer ring
		var world_edge: float = _wm().WORLD_EDGE
		var dist_from_home: float = player.position.distance_to(HOME_POS)
		if dist_from_home > world_edge:
			player.position = HOME_POS + (player.position - HOME_POS).normalized() * world_edge
		# Ring gate walls — locked gates block passage outward
		for gate_id in ["inner_gate", "mid_gate"]:
			if _wm().is_ring_locked(gate_id):
				var gate_r: float = _wm().get_gate_radius(gate_id)
				var d: float = player.position.distance_to(HOME_POS)
				if d > gate_r:
					player.position = HOME_POS + (player.position - HOME_POS).normalized() * (gate_r - 5.0)

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
				enemy.visible = false
	elif old_zone == "sanctuary":
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.set_meta("paused", false)
				enemy.visible = true

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
		var enemy_id: String = enemy.get_meta("enemy_id", "scavenger_grunt")
		var to_player: Vector2 = player.position - enemy.position
		var eid: int = enemy.get_instance_id()
		if not _enemy_state_timers.has(eid):
			_enemy_state_timers[eid] = {}

		match enemy_id:
			"shieldbearer":
				# Slow advance, stop at 110px, "raise shield" pause, then lunge to strike
				if not _enemy_state_timers[eid].has("block_timer"):
					_enemy_state_timers[eid]["block_timer"] = 0.7
				if not _enemy_state_timers[eid].has("lunging"):
					_enemy_state_timers[eid]["lunging"] = false
				var dist_sb: float = to_player.length()
				if dist_sb > 110.0:
					# Approach slowly, reset block timer while closing
					enemy.position += to_player.normalized() * spd * 0.6 * delta
					_enemy_state_timers[eid]["block_timer"] = 0.7
					_enemy_state_timers[eid]["lunging"] = false
				elif _enemy_state_timers[eid]["lunging"]:
					# After wind-up: lunge forward fast to close distance and strike
					if dist_sb > 1.0:
						enemy.position += to_player.normalized() * spd * 1.4 * delta
				else:
					# Wind-up pause (shield raise)
					_enemy_state_timers[eid]["block_timer"] -= delta
					if _enemy_state_timers[eid]["block_timer"] <= 0.0:
						_enemy_state_timers[eid]["lunging"] = true

			"ash_flanker":
				# Wide zigzag strafe — cuts laterally before closing
				var t: float = Time.get_ticks_msec() / 1000.0
				var dir_norm: Vector2 = to_player.normalized()
				# Large amplitude strafe — 120px swing, unique phase per enemy
				var strafe_phase: float = float(eid % 13) * 0.8
				var strafe := Vector2(-dir_norm.y, dir_norm.x) * sin(t * 2.5 + strafe_phase) * 120.0
				# Strafe weight drops off when very close (so it actually closes in)
				var dist_fl: float = to_player.length()
				var strafe_weight: float = clampf(dist_fl / 150.0, 0.0, 1.0)
				if dist_fl > 1.0:
					enemy.position += (to_player.normalized() * spd + strafe * strafe_weight) * delta

			"ridge_archer":
				# Keep 200-350px distance
				var dist_to_player: float = to_player.length()
				if dist_to_player < 200.0:
					# Retreat
					enemy.position -= to_player.normalized() * spd * delta
				elif dist_to_player > 350.0:
					# Advance
					enemy.position += to_player.normalized() * spd * delta
				# else hold position

			"rift_caster":
				# Circle player at ~250px
				var dist_to_player: float = to_player.length()
				var orbit_angle: float = atan2(to_player.y, to_player.x) + PI / 2.0
				var tangent_dir := Vector2(cos(orbit_angle), sin(orbit_angle))
				# Drift toward 250px orbit distance
				var radial_correction: Vector2 = Vector2.ZERO
				if dist_to_player < 230.0:
					radial_correction = -to_player.normalized() * spd * 0.3
				elif dist_to_player > 270.0:
					radial_correction = to_player.normalized() * spd * 0.3
				enemy.position += (tangent_dir * spd * 0.7 + radial_correction) * delta

			"berserker":
				# Erratic burst-charge: full sprint → hard stop → sprint again
				if not _enemy_state_timers[eid].has("burst"):
					_enemy_state_timers[eid]["burst"] = randf_range(0.3, 0.6)
					_enemy_state_timers[eid]["burst_moving"] = true
				_enemy_state_timers[eid]["burst"] -= delta
				if _enemy_state_timers[eid]["burst"] <= 0.0:
					var was_moving: bool = _enemy_state_timers[eid]["burst_moving"]
					_enemy_state_timers[eid]["burst_moving"] = not was_moving
					# Move phase longer, stop phase shorter
					_enemy_state_timers[eid]["burst"] = randf_range(0.3, 0.55) if not was_moving else randf_range(0.08, 0.15)
				if _enemy_state_timers[eid]["burst_moving"] and to_player.length() > 1.0:
					enemy.position += to_player.normalized() * spd * 1.8 * delta

			"shield_wall":
				# Slow advance until within 55px, then plant and hammer
				# Only pursues if player is far; once within striking range it stays put
				var dist_sw: float = to_player.length()
				if dist_sw > 55.0:
					enemy.position += to_player.normalized() * spd * 0.35 * delta

			"warden_hunter":
				# Normal chase, reposition after dealing damage
				if not _enemy_state_timers[eid].has("reposition"):
					_enemy_state_timers[eid]["reposition"] = 0.0
				if _enemy_state_timers[eid]["reposition"] > 0.0:
					# Moving perpendicular
					var perp_dir := Vector2(-to_player.normalized().y, to_player.normalized().x)
					enemy.position += perp_dir * spd * delta
					_enemy_state_timers[eid]["reposition"] -= delta
				else:
					if to_player.length() > 1.0:
						enemy.position += to_player.normalized() * spd * delta

			"resonance_wraith":
				# Teleport every 2.0s
				if not _enemy_state_timers[eid].has("teleport"):
					_enemy_state_timers[eid]["teleport"] = 2.0
					_enemy_state_timers[eid]["tp_cooldown"] = 0.0
				_enemy_state_timers[eid]["teleport"] -= delta
				_enemy_state_timers[eid]["tp_cooldown"] -= delta
				if _enemy_state_timers[eid]["teleport"] <= 0.0:
					# Teleport to random position near player
					var angle: float = randf() * TAU
					var dist_tp: float = randf_range(180.0, 260.0)
					enemy.position = player.position + Vector2(cos(angle), sin(angle)) * dist_tp
					_enemy_state_timers[eid]["teleport"] = 2.0
					_enemy_state_timers[eid]["tp_cooldown"] = 0.5
					# Flash white
					var sprite: Node = enemy.find_child("Sprite", false, false)
					if sprite and sprite is Sprite2D:
						(sprite as Sprite2D).modulate = Color(3.0, 3.0, 3.0)
						var tw := create_tween()
						tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
				else:
					# Drift toward player slowly
					if to_player.length() > 1.0:
						enemy.position += to_player.normalized() * spd * 0.4 * delta

			_:
				# scavenger_grunt and default — beeline toward player
				if to_player.length() > 1.0:
					enemy.position += to_player.normalized() * spd * delta

		# Enforce zone boundary — enemy can't go closer to home than its zone start
		var enemy_dist: float = enemy.position.distance_to(HOME_POS)
		if enemy_dist < boundary_radius:
			var push_dir: Vector2 = (enemy.position - HOME_POS).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			enemy.position = HOME_POS + push_dir * (boundary_radius + 10.0)

func _update_archer_attacks(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
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
				# Fire orange-yellow projectile
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
						var inv: Node = _inv()
						if inv:
							dmg_val = maxi(1, dmg_val - int(inv.get("total_defense")))
						player_health -= float(dmg_val)
						_flash_player_hit(dmg_val)
						if player_health <= 0.0:
							_on_player_death()
				)

func _update_caster_attacks(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
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
				# Fire purple magic orb
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
						var inv: Node = _inv()
						if inv:
							dmg_val = maxi(1, dmg_val - int(inv.get("total_defense")))
						player_health -= float(dmg_val)
						_flash_player_hit(dmg_val)
						if player_health <= 0.0:
							_on_player_death()
				)

func _flash_player_hit(dmg: int) -> void:
	player.modulate = Color(2.0, 0.2, 0.2)
	var flash_tw := create_tween()
	flash_tw.tween_property(player, "modulate", Color.WHITE, 0.25)
	var cam: Camera2D = $Player/Camera2D
	var shake_origin: Vector2 = cam.offset
	var shake_tw := create_tween()
	shake_tw.tween_property(cam, "offset", shake_origin + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
	shake_tw.tween_property(cam, "offset", shake_origin, 0.1)
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

func _check_enemy_damage(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.get_meta("alive", false):
			continue
		if enemy.get_meta("paused", false):
			continue
		var enemy_id: String = enemy.get_meta("enemy_id", "scavenger_grunt")
		# Ranged enemies don't deal contact damage
		if enemy_id == "ridge_archer" or enemy_id == "rift_caster":
			continue
		# Wider contact range for heavy melee types
		var contact_range: float = 40.0
		if enemy_id == "shield_wall":
			contact_range = 60.0
		elif enemy_id == "shieldbearer":
			contact_range = 55.0
		var dist: float = player.position.distance_to(enemy.position)
		if dist < contact_range:
			var key: int = enemy.get_instance_id()
			if not damage_timers.has(key):
				damage_timers[key] = 0.0
			damage_timers[key] -= delta
			if damage_timers[key] <= 0.0:
				# Shieldbearer: only deal damage during lunge phase (not wind-up)
				if enemy_id == "shieldbearer":
					if _enemy_state_timers.has(key) and not _enemy_state_timers[key].get("lunging", false):
						continue
				# Resonance wraith teleport cooldown
				if enemy_id == "resonance_wraith":
					if _enemy_state_timers.has(key) and _enemy_state_timers[key].get("tp_cooldown", 0.0) > 0.0:
						continue
				var dmg: int = enemy.get_meta("damage", 10)
				# Damage multipliers for special types
				if enemy_id == "shield_wall":
					dmg = int(dmg * 1.5)
				elif enemy_id == "warden_hunter":
					dmg = int(dmg * 1.2)
				# Subtract total_defense from equipment (min 1 damage)
				var inv: Node = _inv()
				if inv:
					dmg = maxi(1, dmg - int(inv.get("total_defense")))
				player_health -= float(dmg)
				damage_timers[key] = 1.0
				# Warden hunter reposition after dealing damage
				if enemy_id == "warden_hunter":
					if _enemy_state_timers.has(key):
						_enemy_state_timers[key]["reposition"] = 0.4

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
			if loot.has_meta("key_id"):
				var kid: String = loot.get_meta("key_id")
				if kid not in held_keys:
					held_keys.append(kid)
				var key_name: String = "Inner Key" if kid == "inner_gate" else "Mid Key"
				_show_floating_text("Found %s!" % key_name, player.position, Color(1.0, 0.85, 0.1))
			else:
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
	# Clamp spawn position inside world boundary
	var world_edge: float = _wm().WORLD_EDGE
	if spawn_pos.distance_to(HOME_POS) > world_edge:
		spawn_pos = HOME_POS + spawn_pos.normalized() * (world_edge - 50.0)
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
		fill_points.append(Vector2(cos(angle), sin(angle)) * 150.0)
	sanctuary_fill.polygon = fill_points
	sanctuary_fill.color = Color(0.2, 0.4, 0.8, 0.08)
	zone_markers.add_child(sanctuary_fill)
	# Draw colored ring outlines
	_add_ring_outline(150.0, Color(0.4, 0.9, 0.4, 0.4))    # home base boundary
	_add_ring_outline(1200.0, Color(0.6, 0.8, 0.3, 0.3))  # inner ring
	_add_ring_outline(2000.0, Color(0.9, 0.7, 0.2, 0.3))  # mid ring
	_add_ring_outline(4000.0, Color(0.9, 0.2, 0.2, 0.3))  # outer ring
	# Gate nodes at ring boundaries
	inner_gate_node = _create_gate_node("inner_gate", _wm().MID_START)
	mid_gate_node = _create_gate_node("mid_gate", _wm().OUTER_START)

func _add_ring_outline(radius: float, color: Color) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	var point_count := 120
	for i in range(point_count + 1):
		var angle: float = TAU * float(i) / float(point_count)
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	zone_markers.add_child(line)

func _create_gate_node(gate_id: String, radius: float) -> Node2D:
	var gate := Node2D.new()
	gate.name = gate_id
	gate.position = HOME_POS + Vector2(0, -radius)  # north of home
	# Gate body
	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(20, 12)
	body.position = Vector2(-10, -6)
	body.color = Color(0.7, 0.6, 0.3, 0.9)
	gate.add_child(body)
	# Label
	var lbl := Label.new()
	lbl.name = "GateLabel"
	lbl.text = "[ Gate ]"
	lbl.position = Vector2(-24, -24)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3, 0.9))
	gate.add_child(lbl)
	zone_markers.add_child(gate)
	return gate

func _update_gate_visual(gate_node: Node2D, gate_id: String) -> void:
	if gate_node == null:
		return
	var body: ColorRect = gate_node.get_node_or_null("Body")
	var lbl: Label = gate_node.get_node_or_null("GateLabel")
	if _wm().is_ring_locked(gate_id):
		if body:
			body.color = Color(0.7, 0.6, 0.3, 0.9)
		if lbl:
			lbl.text = "[ Gate ]"
			lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3, 0.9))
	else:
		if body:
			body.color = Color(0.3, 0.3, 0.3, 0.3)
		if lbl:
			lbl.text = "[ Open ]"
			lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.3))

func _handle_gate_interaction() -> void:
	if _is_menu_open():
		return
	var gate_prompt: Node = get_node_or_null("GatePrompt")
	var show_prompt := false
	var prompt_text := ""
	var prompt_pos := Vector2.ZERO
	var gates := {"inner_gate": inner_gate_node, "mid_gate": mid_gate_node}
	var f_now: bool = Input.is_key_pressed(KEY_F)
	for gate_id in gates:
		var gate_node: Node2D = gates[gate_id]
		if gate_node == null:
			continue
		if not _wm().is_ring_locked(gate_id):
			continue
		var dist: float = player.position.distance_to(gate_node.position)
		if dist < 60.0:
			show_prompt = true
			prompt_pos = gate_node.position + Vector2(-80, -45)
			if gate_id in held_keys:
				prompt_text = "F — Unlock (key ready)"
				if f_now and not _f_was_pressed:
					_unlock_gate(gate_id, gate_node)
			else:
				prompt_text = "F — Locked (no key)"
	_f_was_pressed = f_now
	if show_prompt:
		if gate_prompt == null:
			var lbl := Label.new()
			lbl.name = "GatePrompt"
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
			lbl.z_index = 10
			add_child(lbl)
			gate_prompt = lbl
		(gate_prompt as Label).text = prompt_text
		(gate_prompt as Label).position = prompt_pos
		gate_prompt.visible = true
	elif gate_prompt != null:
		gate_prompt.visible = false

func _unlock_gate(gate_id: String, gate_node: Node2D) -> void:
	_wm().unlock_ring(gate_id)
	held_keys.erase(gate_id)
	# Flash white then update to open visual
	var body: ColorRect = gate_node.get_node_or_null("Body")
	if body:
		body.color = Color(1.0, 1.0, 1.0, 1.0)
		var tw := create_tween()
		tw.tween_property(body, "color", Color(0.3, 0.3, 0.3, 0.3), 0.5)
	_update_gate_visual(gate_node, gate_id)
	var gate_name: String = "Inner Ring" if gate_id == "inner_gate" else "Mid Ring"
	_show_floating_text("%s unlocked!" % gate_name, player.position, Color(1.0, 0.85, 0.1))

func _show_floating_text(text: String, pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos + Vector2(-40, -60)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)

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
	var view_radius: float = 800.0
	var scale_factor: float = (map_size * 0.5) / view_radius
	var center := Vector2(map_size / 2.0, map_size / 2.0)
	var cam_origin: Vector2 = player.position
	var reveal_r: float = 7.0 * (map_size / 160.0)  # reveal circle radius per point

	var ring_defs := [
		[150.0,  Color(0.4, 0.9, 0.4, 0.9)],
		[1200.0, Color(0.6, 0.8, 0.3, 0.9)],
		[2000.0, Color(0.9, 0.7, 0.2, 0.9)],
		[4000.0, Color(0.9, 0.2, 0.2, 0.9)],
	]
	var ring_center: Vector2 = (HOME_POS - cam_origin) * scale_factor + center

	# Step 1: Draw explored terrain (revealed ground)
	for pos in explored_positions:
		var map_pos: Vector2 = (pos - cam_origin) * scale_factor + center
		if map_pos.x >= -reveal_r and map_pos.x <= map_size + reveal_r and map_pos.y >= -reveal_r and map_pos.y <= map_size + reveal_r:
			control.draw_circle(map_pos, reveal_r, Color(0.18, 0.28, 0.18, 1.0))

	# Step 2: Draw ring segments only where they pass through explored areas
	# Check each ring arc segment — only draw segments near an explored point
	for ring_data in ring_defs:
		var world_r: float = ring_data[0]
		var ring_col: Color = ring_data[1]
		var map_r: float = world_r * scale_factor
		var seg_count := 120
		for i in range(seg_count):
			var angle_a: float = (float(i) / seg_count) * TAU
			var angle_b: float = (float(i + 1) / seg_count) * TAU
			var seg_mid_world: Vector2 = HOME_POS + Vector2(cos((angle_a + angle_b) * 0.5), sin((angle_a + angle_b) * 0.5)) * world_r
			# Check if any explored point is near this segment
			var visible := false
			for exp_pos in explored_positions:
				if exp_pos.distance_squared_to(seg_mid_world) < 120000.0:  # ~350 world units reveal radius for rings
					visible = true
					break
			if visible:
				var p_a: Vector2 = ring_center + Vector2(cos(angle_a), sin(angle_a)) * map_r
				var p_b: Vector2 = ring_center + Vector2(cos(angle_b), sin(angle_b)) * map_r
				control.draw_line(p_a, p_b, ring_col, 1.5)

	# Step 3: Home icon — always visible (home base is always known)
	var home_map: Vector2 = (HOME_POS - cam_origin) * scale_factor + center
	if home_map.x >= -6 and home_map.x <= map_size + 6 and home_map.y >= -6 and home_map.y <= map_size + 6:
		control.draw_rect(Rect2(home_map - Vector2(4, 4), Vector2(8, 8)), Color(0.85, 0.75, 0.5, 0.95))
		control.draw_rect(Rect2(home_map - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 1.0, 1.0, 0.6), false, 1.0)

	# Step 4: Home ring always visible (you always know where home is)
	var home_ring_r: float = 150.0 * scale_factor
	control.draw_arc(ring_center, home_ring_r, 0.0, TAU, 60, Color(0.4, 0.9, 0.4, 0.7), 1.5)

	# Step 5: Gate markers on minimap
	var gate_defs := {"inner_gate": inner_gate_node, "mid_gate": mid_gate_node}
	for gate_id in gate_defs:
		var gate_node: Node2D = gate_defs[gate_id]
		if gate_node == null:
			continue
		if not _wm().is_ring_locked(gate_id):
			continue
		var gate_map: Vector2 = (gate_node.position - cam_origin) * scale_factor + center
		if gate_map.x >= -4 and gate_map.x <= map_size + 4 and gate_map.y >= -4 and gate_map.y <= map_size + 4:
			# Only show if explored nearby
			var gate_visible := false
			for exp_pos in explored_positions:
				if exp_pos.distance_squared_to(gate_node.position) < 120000.0:
					gate_visible = true
					break
			if gate_visible:
				control.draw_rect(Rect2(gate_map - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 0.85, 0.1, 0.9))

	# Step 6: Player dot — always at center
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
