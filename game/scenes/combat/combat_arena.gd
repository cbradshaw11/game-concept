extends Node2D
class_name CombatArena

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

signal attack_hook_triggered
signal dodge_hook_triggered
signal guard_hook_changed(is_guarding: bool)
signal encounter_cleared(enemy_count: int)
signal boss_encounter_cleared
signal player_died()

@onready var player: PlayerController = $Player
@onready var combat_status: Label = $HUD/CombatStatus
@onready var hp_bar: ProgressBar = $HUD/Bars/HPBar
@onready var stamina_bar: ProgressBar = $HUD/Bars/StaminaBar
@onready var poise_bar: ProgressBar = $HUD/Bars/PoiseBar
@onready var _hit_land_player: AudioStreamPlayer = $HitLandPlayer
@onready var _damage_taken_player: AudioStreamPlayer = $DamageTakenPlayer
@onready var _dodge_guard_player: AudioStreamPlayer = $DodgeGuardPlayer
@onready var _player_death_player: AudioStreamPlayer = $PlayerDeathPlayer
@onready var _background: TextureRect = $Background
@onready var _player_sprite: Sprite2D = $PlayerSprite
@onready var _enemy_sprites: Array[Sprite2D] = [
	$EnemySprite0,
	$EnemySprite1,
	$EnemySprite2,
]
@onready var _combat_tutorial_overlay: Panel = $TutorialLayer/CombatTutorialOverlay
@onready var enemy_hud_container: VBoxContainer = $HUD/EnemyHUDContainer
@onready var action_feedback: Label = $HUD/ActionFeedback
@onready var wardan_phase_label: Label = $HUD/WardanPhaseLabel

var _tutorial_showing: bool = false
var _dismiss_frame: int = -1
var _feedback_tween: Tween = null
var _poise_flash_tween: Tween = null
var _shake_tween: Tween = null
var _shake_origin: Vector2 = Vector2.ZERO

const _ENEMY_TEXTURES: Dictionary = {
	"grunt": "res://assets/sprites/enemy_grunt.png",
	"flanker": "res://assets/sprites/enemy_grunt.png",
	"defender": "res://assets/sprites/enemy_defender.png",
	"ranged": "res://assets/sprites/enemy_ranged.png",
	"caster": "res://assets/sprites/enemy_ranged.png",
	"elite": "res://assets/sprites/enemy_defender.png",
}

var ring_id: String = "inner"
var seed: int = 0
var attack_count: int = 0
var dodge_count: int = 0
var guard_active: bool = false
var enemies: Array[EnemyController] = []
var encounter_enemy_count: int = 0
var encounter_completed: bool = false
var weapon_data: Dictionary = {}
var is_boss_encounter: bool = false

func _ready() -> void:
	player.attack_triggered.connect(_on_attack_triggered)
	player.dodge_triggered.connect(_on_dodge_triggered)
	player.guard_changed.connect(_on_guard_changed)
	player.player_died.connect(func() -> void: _player_death_player.play(); player_died.emit())
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	if player.has_signal("poise_changed"):
		player.poise_changed.connect(_on_poise_changed)
	if player.has_signal("player_staggered"):
		player.player_staggered.connect(_on_player_staggered)
	if player.has_signal("attack_evaded"):
		player.attack_evaded.connect(_on_attack_evaded)
	if player.has_signal("guard_broken"):
		player.guard_broken.connect(_on_guard_broken)
	player.heavy_attack_triggered.connect(_on_heavy_attack_triggered)
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina
	poise_bar.max_value = player.max_poise
	poise_bar.value = player.current_poise
	if not InputMap.has_action("heavy_attack"):
		InputMap.add_action("heavy_attack")
		var ev := InputEventKey.new()
		ev.keycode = KEY_X
		InputMap.action_add_event("heavy_attack", ev)
	player.reload_weapon_stats()
	_load_weapon_data()
	_load_player_sprite()
	_load_ring_background(GameState.current_ring)
	_update_status()

func _load_weapon_data() -> void:
	var all_weapons: Array = DataStore.weapons.get("weapons", [])
	for w in all_weapons:
		if w.get("id") == GameState.selected_weapon_id:
			weapon_data = w
			return
	weapon_data = {"light_damage": 14}

func set_context(next_ring_id: String, next_seed: int, enemy_count: int = 1) -> void:
	ring_id = next_ring_id
	seed = next_seed
	attack_count = 0
	dodge_count = 0
	guard_active = false
	encounter_enemy_count = max(1, enemy_count)
	encounter_completed = false
	is_boss_encounter = false
	_load_weapon_data()
	_spawn_enemies(encounter_enemy_count)
	_load_ring_background(ring_id)
	player.set_guarding(false)
	_update_status()
	if not GameState.first_run_complete:
		_show_first_run_tooltips()

func set_arena_active(is_active: bool) -> void:
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if _tutorial_showing:
		return
	if enemies.is_empty() or encounter_completed:
		return
	var player_zone := _player_zone()
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		var distance_to_player := absf(float(index - player_zone)) + 0.5
		enemy.tick(distance_to_player, delta)
	if _all_enemies_defeated():
		encounter_completed = true
		if is_boss_encounter:
			boss_encounter_cleared.emit()
		else:
			encounter_cleared.emit(encounter_enemy_count)
	_update_enemy_hud()
	_update_status()

func _show_first_run_tooltips() -> void:
	_tutorial_showing = true
	_combat_tutorial_overlay.visible = true

func _dismiss_tutorial() -> void:
	if not _tutorial_showing:
		return
	_tutorial_showing = false
	_dismiss_frame = Engine.get_process_frames()
	_combat_tutorial_overlay.visible = false
	GameState.first_run_complete = true

func _input(event: InputEvent) -> void:
	if _tutorial_showing:
		if event is InputEventKey and event.pressed:
			_dismiss_tutorial()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed:
			_dismiss_tutorial()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("heavy_attack"):
		player.heavy_attack()

func _on_attack_triggered() -> void:
	_dismiss_tutorial()
	if _dismiss_frame >= 0 and Engine.get_process_frames() <= _dismiss_frame:
		return
	attack_count += 1
	_apply_damage_to_front_enemy(weapon_data.get("light_damage", 14))
	_hit_land_player.play()
	_flash_front_enemy_sprite()
	_show_action_feedback("HIT +%d" % weapon_data.get("light_damage", 14))
	attack_hook_triggered.emit()
	_update_enemy_hud()
	_update_status()

func _on_heavy_attack_triggered(dmg: int) -> void:
	_apply_damage_to_front_enemy(dmg)
	_hit_land_player.play()
	_flash_front_enemy_sprite()
	_update_status()

func _on_dodge_triggered() -> void:
	dodge_count += 1
	_dodge_guard_player.play()
	dodge_hook_triggered.emit()
	_update_status()

func _on_guard_changed(is_guarding: bool) -> void:
	guard_active = is_guarding
	guard_hook_changed.emit(is_guarding)
	_update_status()

func _on_attack_evaded() -> void:
	_dodge_guard_player.play()
	_show_action_feedback("DODGED")

func _on_guard_broken() -> void:
	_show_action_feedback("BLOCKED")

func _on_player_staggered() -> void:
	_show_action_feedback("POISE BREAK!")
	if _poise_flash_tween:
		_poise_flash_tween.kill()
	_poise_flash_tween = create_tween()
	_poise_flash_tween.tween_property(poise_bar, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.05)
	_poise_flash_tween.tween_property(poise_bar, "modulate", Color(1.0, 1.0, 0.4, 1.0), 0.3)

func _update_status() -> void:
	var ring_name: String = GameState.current_ring.capitalize() if GameState.current_ring else ""
	var enc: int = GameState.encounters_cleared
	var target: int = 3
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == GameState.current_ring:
			target = r.get("contract_target", 3)
			break
	combat_status.text = "Ring: %s  |  Encounters: %d/%d" % [ring_name, enc, target]

func _update_enemy_hud() -> void:
	var slots := [
		enemy_hud_container.get_node_or_null("EnemyHUD_0"),
		enemy_hud_container.get_node_or_null("EnemyHUD_1"),
		enemy_hud_container.get_node_or_null("EnemyHUD_2"),
	]
	for i in slots.size():
		var slot = slots[i]
		if slot == null:
			continue
		if i < enemies.size() and enemies[i].state != EnemyController.EnemyState.DEAD:
			slot.visible = true
			var enemy_hp_bar: ProgressBar = slot.get_node_or_null("EnemyHPBar")
			var enemy_name_label: Label = slot.get_node_or_null("EnemyNameLabel")
			var enemy := enemies[i]
			if enemy_name_label:
				enemy_name_label.text = "%s  %d/%d" % [enemy.enemy_display_name, enemy.health, enemy.initial_health]
			if enemy_hp_bar:
				enemy_hp_bar.max_value = enemy.initial_health
				enemy_hp_bar.value = enemy.health
		else:
			slot.visible = false
	if is_boss_encounter and not enemies.is_empty():
		var boss_enemy := enemies[0]
		var phase: int = boss_enemy._current_phase
		if GameState.warden_map_unlocked:
			wardan_phase_label.text = "Phase %d / 3  (Phase 2: 840HP | Phase 3: 420HP)" % phase
		else:
			wardan_phase_label.text = "Phase %d / 3" % phase
		wardan_phase_label.visible = not encounter_completed
	else:
		wardan_phase_label.visible = false

func _show_action_feedback(text: String) -> void:
	if _feedback_tween:
		_feedback_tween.kill()
	action_feedback.text = text
	action_feedback.visible = true
	action_feedback.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(0.5)
	_feedback_tween.tween_property(action_feedback, "modulate:a", 0.0, 0.3)
	_feedback_tween.tween_callback(func() -> void: action_feedback.visible = false)

func _apply_behavior_profile(enemy: EnemyController, profile: String) -> void:
	match profile:
		"flank_aggressive":
			enemy.chase_range = 5.0
			enemy.attack_cooldown = 0.9
		"kite_volley":
			enemy.preferred_min_range = 1.5
			enemy.attack_range = 4.5
		"guard_counter":
			enemy.chase_range = 4.5
			var pc = player
			enemy.guard_query = func() -> bool: return pc.guarding
		"zone_control":
			enemy.chase_range = 6.0
			enemy.attack_cooldown = 1.8
		"elite_pressure":
			enemy.chase_range = 4.5
			enemy.attack_cooldown = 0.7
		_:
			pass

func _spawn_enemies(count: int) -> void:
	enemies.clear()
	var ring = GameState.current_ring
	var all_enemies: Array = DataStore.enemies.get("enemies", [])
	var enemy_pool: Array = all_enemies.filter(func(e: Dictionary) -> bool:
		return e.get("ring_availability", e.get("rings", [ring])[0]) == ring or e.get("rings", []).has(ring)
	)
	if enemy_pool.is_empty():
		enemy_pool = all_enemies
	var spawned_data: Array = []
	for i in range(count):
		var enemy_data: Dictionary = enemy_pool[i % enemy_pool.size()]
		spawned_data.append(enemy_data)
		var enemy := EnemyController.new(
			enemy_data.get("health", 60),
			3.5,
			1.2,
			enemy_data.get("damage", 10)
		)
		var poise_dmg: int = enemy_data.get("poise_damage", 0)
		enemy.attack_resolved.connect(func(amount: int) -> void:
			_apply_damage_to_player(amount, poise_dmg)
		)
		enemy.wind_up_started.connect(_on_enemy_wind_up)
		var profile: String = enemy_data.get("behavior_profile", "frontline_basic")
		_apply_behavior_profile(enemy, profile)
		enemy.enemy_display_name = enemy_data.get("role", "enemy").capitalize()
		enemies.append(enemy)
	_load_enemy_sprites(spawned_data)
	_update_enemy_hud()

func _spawn_boss(boss_id: String) -> EnemyController:
	var bosses = DataStore.enemies.get("bosses", [])
	var matches = bosses.filter(func(b: Dictionary) -> bool: return b.get("id") == boss_id)
	if matches.is_empty():
		push_error("Boss not found: " + boss_id)
		return null
	var boss_data: Dictionary = matches[0]
	var boss := EnemyController.new(
		boss_data.get("health", 1200),
		3.5,
		1.2,
		boss_data.get("damage", 22)
	)
	boss.attack_resolved.connect(func(amount: int) -> void:
		_apply_damage_to_player(amount, boss_data.get("poise_damage", 35))
	)
	boss.wind_up_started.connect(_on_enemy_wind_up)
	var profile: String = boss_data.get("behavior_profile", "elite_pressure")
	_apply_behavior_profile(boss, profile)
	boss.is_boss = true
	boss.enemy_display_name = boss_data.get("role", boss_data.get("id", "boss")).capitalize()
	return boss

func start_boss_encounter(boss_id: String) -> void:
	enemies.clear()
	encounter_completed = false
	is_boss_encounter = true
	attack_count = 0
	dodge_count = 0
	var boss := _spawn_boss(boss_id)
	if boss == null:
		return
	enemies.append(boss)
	encounter_enemy_count = 1
	player.set_guarding(false)
	var bosses = DataStore.enemies.get("bosses", [])
	var boss_matches = bosses.filter(func(b: Dictionary) -> bool: return b.get("id") == boss_id)
	if not boss_matches.is_empty():
		_load_enemy_sprites([boss_matches[0]])
	else:
		_load_enemy_sprites([{"role": "elite"}])
	_update_enemy_hud()
	_update_status()
	if GameState.warden_map_unlocked:
		wardan_phase_label.text = "Phase 1 / 3  (Phase 2: 840HP | Phase 3: 420HP)"
	else:
		wardan_phase_label.text = "Phase 1 / 3"
	wardan_phase_label.visible = true

func _player_zone() -> int:
	var zone := int(round(player.position.x / 160.0))
	return clampi(zone, 0, max(0, enemies.size() - 1))

func _apply_damage_to_front_enemy(damage: int) -> void:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			var prev_state := enemy.state
			enemy.apply_damage(damage, true)
			if prev_state != EnemyController.EnemyState.STAGGER and enemy.state == EnemyController.EnemyState.STAGGER:
				_show_action_feedback("STAGGERED")
			return

func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			return false
	return true

func _apply_damage_to_player(amount: int, poise_damage: int = 0) -> void:
	if player:
		var health_before: int = player.current_health
		player.take_damage(amount)
		if player.current_health < health_before:
			_damage_taken_player.play()
			_apply_hit_flash(_player_sprite)
			_screen_shake(0.15, 3.0)
		elif player.guarding:
			_dodge_guard_player.play()
		if poise_damage > 0:
			player.take_poise_damage(poise_damage)

func _load_ring_background(target_ring: String) -> void:
	if not is_instance_valid(_background):
		return
	var bg_path: String
	match target_ring:
		"inner":
			bg_path = "res://assets/backgrounds/inner.png"
		"mid":
			bg_path = "res://assets/backgrounds/mid.png"
		"outer":
			bg_path = "res://assets/backgrounds/outer.png"
		_:
			_background.texture = null
			return
	if ResourceLoader.exists(bg_path):
		_background.texture = load(bg_path)

func _load_player_sprite() -> void:
	if not is_instance_valid(_player_sprite):
		return
	var tex_path := "res://assets/sprites/player.png"
	if ResourceLoader.exists(tex_path):
		_player_sprite.texture = load(tex_path)
	_player_sprite.position = player.position

func _load_enemy_sprites(enemy_data_array: Array) -> void:
	for i in _enemy_sprites.size():
		var sprite := _enemy_sprites[i]
		if not is_instance_valid(sprite):
			continue
		if i < enemy_data_array.size():
			var role: String = enemy_data_array[i].get("role", "grunt")
			var tex_path: String = _ENEMY_TEXTURES.get(role, "res://assets/sprites/enemy_grunt.png")
			if ResourceLoader.exists(tex_path):
				sprite.texture = load(tex_path)
			sprite.visible = true
			# Space enemies evenly across the arena width
			var slot_x := 640.0 + float(i) * 120.0
			sprite.position = Vector2(slot_x, 270.0)
		else:
			sprite.visible = false
			sprite.texture = null

func _apply_hit_flash(sprite: Sprite2D) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.modulate = Color(2.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.1)

func _flash_front_enemy_sprite() -> void:
	for i in enemies.size():
		if i < _enemy_sprites.size() and enemies[i].state != EnemyController.EnemyState.DEAD:
			_apply_hit_flash(_enemy_sprites[i])
			return

func _screen_shake(duration: float, magnitude: float) -> void:
	var camera := get_viewport().get_camera_2d() if get_viewport() else null
	var target_node: Node2D = camera if is_instance_valid(camera) else self
	if _shake_tween:
		_shake_tween.kill()
		target_node.position = _shake_origin
	else:
		_shake_origin = target_node.position
	_shake_tween = create_tween()
	var steps := int(duration / 0.016)
	steps = max(steps, 4)
	for _i in steps:
		var offset := Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		)
		_shake_tween.tween_property(target_node, "position", _shake_origin + offset, duration / steps)
	_shake_tween.tween_property(target_node, "position", _shake_origin, 0.02)

func _on_enemy_wind_up() -> void:
	var tween := create_tween()
	tween.tween_property($ArenaBounds, "modulate", Color(1.5, 0.5, 0.5), 0.05)
	tween.tween_property($ArenaBounds, "modulate", Color(1.0, 1.0, 1.0), 0.15)

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	if float(current) / float(maximum) < 0.25:
		hp_bar.modulate = Color(0.5, 0.0, 0.0)
	else:
		hp_bar.modulate = Color(1.0, 0.2, 0.2)

func _on_stamina_changed(current: float, maximum: int) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func _on_poise_changed(current: int, maximum: int) -> void:
	poise_bar.max_value = maximum
	poise_bar.value = current
