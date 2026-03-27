extends Node2D
class_name CombatArena

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const PlayerController = preload("res://scripts/core/player_controller.gd")
const Profiles = preload("res://scripts/core/behavior_profiles.gd")

signal attack_hook_triggered
signal dodge_hook_triggered
signal guard_hook_changed(is_guarding: bool)
signal encounter_cleared(enemy_count: int)
signal boss_phase_changed(phase: int)
signal boss_defeated

# ── Safe autoload accessors (avoid compile-time identifier resolution) ────────
func _gs() -> Node:
	return get_node_or_null("/root/GameState")
func _am() -> Node:
	return get_node_or_null("/root/AudioManager")
func _cm() -> Node:
	return get_node_or_null("/root/ChallengeManager")

@onready var player: PlayerController = $Player
@onready var player_sprite: Sprite2D = $Player/PlayerSprite
@onready var combat_status: Label = $HUD/CombatStatus
@onready var hp_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/HPBar
@onready var stamina_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/StaminaBar
@onready var poise_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/PoiseBar
@onready var enemy_container: Node2D = $EnemyContainer
@onready var camera: Camera2D = $Camera
@onready var arena_bg: Sprite2D = $ArenaBG

var ring_id: String = "inner"
var seed: int = 0
var attack_count: int = 0
var dodge_count: int = 0
var guard_active: bool = false
var player_health: int = 100
var player_max_health: int = 100

# M38 — Three-slot weapon system
var _equipped_melee: String = "blade_iron"
var _equipped_ranged: String = "bow_iron"
var _equipped_magic: String = "resonance_staff"
var _melee_cooldown: float = 0.0
var _ranged_cooldown: float = 0.0
var _magic_cooldown: float = 0.0
var _last_attack_slot: String = "melee"

signal player_died
var enemies: Array[EnemyController] = []
var enemy_sprites: Array[Sprite2D] = []
var enemy_nodes: Array[Node2D] = []
var encounter_enemy_count: int = 0
var encounter_completed: bool = false
var is_boss_encounter: bool = false
var _last_boss_phase: int = 1

# Camera shake state
var _shake_amount: float = 0.0
var _shake_timer: float = 0.0
var _camera_origin: Vector2 = Vector2.ZERO

# Hit flash timers per enemy (lerp progress, negative = hold phase)
var _hit_flash_timers: Array[float] = []
# Flash type per enemy: "hit" or "poise" or "warden_phase"
var _hit_flash_types: Array[String] = []

# Hit stop state
var _hit_stop_timer: float = 0.0
var _hit_stop_active: bool = false
var _pre_hit_stop_time_scale: float = 1.0

# Phase transition flash overlay
var _phase_flash_overlay: ColorRect = null

# Bow heavy charge state
# _bow_suppress_ticks[enemy_index] = remaining suppression ticks
var _enemy_suppress_ticks: Array[int] = []

# M36 — Player attack flash timer (negative = hold phase, positive = lerp phase)
var _player_attack_flash_timer: float = 0.0
# M37 — Per-family flash tracking
var _player_attack_flash_family: String = ""
# Player damage flash (zone_control / death explosion)
var _player_damage_flash_timer: float = 0.0

# ─── M19 Juice Constants ─────────────────────────────────────────────────────
const HIT_STOP_DURATION := 0.065  # seconds (~65ms, range 50-80ms)
const HIT_STOP_TIME_SCALE := 0.05

const SHAKE_MAGNITUDE_SMALL := 5.0   # player hit
const SHAKE_MAGNITUDE_MEDIUM := 8.0  # enemy death
const SHAKE_MAGNITUDE_LARGE := 18.0  # Warden phase transition
const SHAKE_DURATION_DEFAULT := 0.3

const HIT_FLASH_COLOR := Color(1.5, 0.5, 0.5, 1.0)
const HIT_FLASH_HOLD := 0.0167  # ~1 frame at 60fps
const HIT_FLASH_LERP_DURATION := 0.15

const POISE_BREAK_FLASH_COLOR := Color(0.8, 0.8, 2.0, 1.0)
const POISE_BREAK_FLASH_DURATION := 0.2

const WARDEN_PHASE_FLASH_HOLD := 0.3  # longer hold for Warden phase transition

# M30 — Phase phantom (Resonance Wraith) flash colors
const PHASE_IMMUNE_FLASH_COLOR := Color(0.3, 0.3, 2.0, 0.8)
const PHASE_VULNERABLE_FLASH_COLOR := Color(1.8, 1.0, 0.2, 1.0)
const PHASE_INVULNERABLE_FLASH_COLOR := Color(0.1, 0.1, 0.8, 1.0)
const PHASE_PHANTOM_FLASH_DURATION := 0.25

# M36/M37 — Player attack flash (per-family colors)
const PLAYER_ATTACK_FLASH_COLOR := Color(1.2, 1.2, 0.8, 1.0)

# M37 — Per-family flash colors
const FAMILY_FLASH_COLORS := {
	"blade": Color(1.0, 1.0, 0.7),
	"dagger": Color(0.7, 1.0, 0.7),
	"polearm": Color(0.7, 0.9, 1.0),
	"hammer": Color(1.0, 0.6, 0.3),
	"bow": Color(0.9, 1.0, 0.7),
	"staff": Color(0.8, 0.6, 1.0),
	"greatsword": Color(1.0, 0.8, 0.4),
	"crossbow": Color(0.8, 0.9, 1.0),
	"orb": Color(0.5, 0.8, 1.0),
}

# M37 — Per-family flash durations {family: [hold, lerp]}
const FAMILY_FLASH_DURATIONS := {
	"dagger": [0.05, 0.08],
	"hammer": [0.12, 0.18],
}
const DEFAULT_FLASH_HOLD := 0.08
const DEFAULT_FLASH_LERP := 0.12
const PLAYER_ATTACK_FLASH_HOLD := 0.08   # 80ms hold
const PLAYER_ATTACK_FLASH_LERP := 0.12   # 120ms lerp back

# M39 — Attack animation constants
const MELEE_LUNGE_PX := 30.0
const MELEE_LUNGE_DURATION := 0.1
const MELEE_SNAP_BACK_DURATION := 0.08
const SLASH_ARC_FADE_DURATION := 0.15
const ENEMY_LUNGE_PX := 30.0
const ENEMY_LUNGE_DURATION := 0.1
const ENEMY_SNAP_BACK_DURATION := 0.1
const PROJECTILE_TRAVEL_DURATION := 0.2
const MISS_LABEL_DURATION := 0.6
const TELEGRAPH_READINESS_THRESHOLD := 0.85
const TELEGRAPH_COLOR := Color(1.0, 0.6, 0.1, 1.0)  # orange
const DEFAULT_MELEE_RANGE := 1.5  # zones

const SPRITE_BASE := "res://assets/sprites/"
const ENEMY_SPRITE_NAMES := {
	"grunt": "enemy_grunt.png",
	"defender": "enemy_defender.png",
	"ranged": "enemy_ranged.png",
	"warden": "enemy_warden.png",
}

func _ready() -> void:
	player.dodge_triggered.connect(_on_dodge_triggered)
	player.guard_changed.connect(_on_guard_changed)
	_camera_origin = camera.offset
	_load_background()
	_load_player_sprite()
	_setup_phase_flash_overlay()
	_update_hud()

func set_equipped_weapons(melee_id: String, ranged_id: String, magic_id: String) -> void:
	_equipped_melee = melee_id
	_equipped_ranged = ranged_id
	_equipped_magic = magic_id
	_melee_cooldown = 0.0
	_ranged_cooldown = 0.0
	_magic_cooldown = 0.0

func _load_background() -> void:
	# Check ring data for a named background, fallback to default
	var _ds_bg: Node = get_node_or_null("/root/DataStore")
	var ring_data: Dictionary = _ds_bg.get_ring(ring_id) if _ds_bg else {}
	var bg_name := str(ring_data.get("background", ""))
	if bg_name == "":
		bg_name = "arena_bg.png"
	var bg_path := "res://assets/backgrounds/" + bg_name
	if ResourceLoader.exists(bg_path):
		arena_bg.texture = load(bg_path) as Texture2D
	elif ResourceLoader.exists("res://assets/backgrounds/arena_bg.png"):
		arena_bg.texture = load("res://assets/backgrounds/arena_bg.png") as Texture2D

func _load_player_sprite() -> void:
	var path := SPRITE_BASE + "player.png"
	if ResourceLoader.exists(path):
		player_sprite.texture = load(path) as Texture2D

func set_context(next_ring_id: String, next_seed: int, enemy_count: int = 1, boss_fight: bool = false) -> void:
	ring_id = next_ring_id
	seed = next_seed
	attack_count = 0
	dodge_count = 0
	guard_active = false
	encounter_enemy_count = max(1, enemy_count)
	encounter_completed = false
	is_boss_encounter = boss_fight
	# M31 — iron_road: preserve HP between encounters (no healing)
	var _cm_ctx := _cm()
	if _cm_ctx and _cm_ctx.has_challenge("iron_road") and player_health > 0:
		pass  # Keep current HP, no reset
	else:
		player_health = player_max_health
	_load_background()
	if boss_fight:
		_spawn_boss()
	else:
		_spawn_enemies(encounter_enemy_count)
	player.set_guarding(false)
	_update_hud()

func set_arena_active(is_active: bool) -> void:
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	_update_hit_stop(delta)
	_update_camera_shake(delta)
	_update_hit_flashes(delta)
	_update_player_attack_flash(delta)
	_update_player_damage_flash(delta)
	_update_enemy_telegraph(delta)
	# M38 — Tick independent cooldowns
	_melee_cooldown = maxf(0.0, _melee_cooldown - delta)
	_ranged_cooldown = maxf(0.0, _ranged_cooldown - delta)
	_magic_cooldown = maxf(0.0, _magic_cooldown - delta)
	# M38 — Three independent attack inputs
	if not encounter_completed and not enemies.is_empty():
		if Input.is_action_just_pressed("attack_melee"):
			_try_slot_attack("melee")
		if Input.is_action_just_pressed("attack_ranged"):
			_try_slot_attack("ranged")
		if Input.is_action_just_pressed("attack_magic"):
			_try_slot_attack("magic")

	if enemies.is_empty() or encounter_completed:
		return
	var player_zone := _player_zone()
	var hp_percent := float(player_health) / float(player_max_health)
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		# Suppressed enemies skip their action for this tick
		if index < _enemy_suppress_ticks.size() and _enemy_suppress_ticks[index] > 0:
			_enemy_suppress_ticks[index] -= 1
			continue
		# elite_pressure: update player HP tracking each tick
		if enemy.behavior_profile == Profiles.ELITE_PRESSURE:
			enemy.set_player_hp_percent(hp_percent)
		var distance_to_player := absf(enemy_nodes[index].position.x - player.position.x) / 160.0 if index < enemy_nodes.size() else absf(float(index - player_zone)) + 0.5
		# kite_volley: if retreating and at arena edge, enter melee fallback
		if enemy.state == EnemyController.EnemyState.RETREAT:
			if index >= enemies.size() - 1:
				enemy.enter_melee_fallback()
		var did_attack := enemy.tick(distance_to_player, delta)
		if did_attack:
			# M39 — Enemy lunge animation on every attack attempt
			_animate_enemy_attack(index)
			# Only deal damage if within attack range
			if distance_to_player > enemy.attack_range:
				continue
			var dmg := enemy.damage
			# M31 — cursed_ground: +25% enemy damage
			var _cm_cg := _cm()
			if _cm_cg and _cm_cg.has_challenge("cursed_ground"):
				dmg = int(ceil(float(dmg) * 1.25))
			if player.guarding:
				dmg = max(1, dmg / 2)
			player_health = max(0, player_health - dmg)
			# M21 — Track damage taken
			if _gs(): _gs().record_damage_taken(dmg)
			_trigger_hit_stop()
			trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, SHAKE_DURATION_DEFAULT)
			if _am():
				_am().play_sfx("hit_player")
			if player_health <= 0:
				_on_player_died()
				return
		# zone_control: apply proximity damage
		var zone_dmg := enemy.get_zone_damage(distance_to_player, delta)
		if zone_dmg > 0.0:
			var zone_int := int(ceil(zone_dmg))
			player_health = max(0, player_health - zone_int)
			if _gs(): _gs().record_damage_taken(zone_int)
			_trigger_hit_stop()
			trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, SHAKE_DURATION_DEFAULT)
			_flash_player_damage()
			if player_health <= 0:
				_on_player_died()
				return
	# Check boss phase transitions for visual signals
	if is_boss_encounter and not enemies.is_empty():
		var boss := enemies[0]
		if boss.is_boss and boss.state != EnemyController.EnemyState.DEAD:
			if boss.boss_phase != _last_boss_phase:
				_last_boss_phase = boss.boss_phase
				boss_phase_changed.emit(boss.boss_phase)
				print("WARDEN PHASE %d" % boss.boss_phase)
				if _am():
					_am().play_sfx("warden_phase")
				trigger_screen_shake(SHAKE_MAGNITUDE_LARGE, 0.5)
				_trigger_phase_flash()
				# Extended hit flash for Warden during phase transition
				if 0 < _hit_flash_timers.size():
					_hit_flash_timers[0] = WARDEN_PHASE_FLASH_HOLD
					_hit_flash_types[0] = "warden_phase"

	if _all_enemies_defeated():
		encounter_completed = true
		if is_boss_encounter:
			boss_defeated.emit()
		else:
			encounter_cleared.emit(encounter_enemy_count)
	_update_hud()

func _get_family_flash_color(family: String) -> Color:
	return FAMILY_FLASH_COLORS.get(family, PLAYER_ATTACK_FLASH_COLOR)

func _get_family_flash_durations(family: String) -> Array:
	return FAMILY_FLASH_DURATIONS.get(family, [DEFAULT_FLASH_HOLD, DEFAULT_FLASH_LERP])

func _get_family_sfx(family: String, heavy: bool) -> String:
	var prefix := "heavy_swing_" if heavy else "swing_"
	var family_key := prefix + family
	var fallback := "heavy_swing" if heavy else "swing"
	# Check if family-specific SFX exists in registry
	if _am() and family_key in _am().SFX_REGISTRY:
		return family_key
	return fallback

func _try_slot_attack(slot: String) -> void:
	# Check cooldown
	match slot:
		"melee":
			if _melee_cooldown > 0.0:
				return
		"ranged":
			if _ranged_cooldown > 0.0:
				return
		"magic":
			if _magic_cooldown > 0.0:
				return
	# Check stamina
	var weapon_data := _get_weapon_data_for_slot(slot)
	if weapon_data.is_empty():
		return
	var stamina_cost := int(weapon_data.get("heavy_stamina_cost", int(weapon_data.get("light_stamina_cost", 12))))
	if player.stamina < stamina_cost:
		return
	player.stamina -= stamina_cost
	# Set cooldown
	var cooldown_defaults := {"melee": 1.0, "ranged": 1.5, "magic": 1.1}
	var cooldown_val := float(weapon_data.get("attack_cooldown", cooldown_defaults.get(slot, 1.0)))
	match slot:
		"melee":
			_melee_cooldown = cooldown_val
		"ranged":
			_ranged_cooldown = cooldown_val
		"magic":
			_magic_cooldown = cooldown_val
	_execute_attack(slot, weapon_data)

func _execute_attack(slot: String, weapon_data: Dictionary) -> void:
	_last_attack_slot = slot
	attack_count += 1
	var family := str(weapon_data.get("family", ""))
	_player_attack_flash_family = family
	var durations := _get_family_flash_durations(family)
	_player_attack_flash_timer = durations[0] + durations[1]
	# Use heavy mechanic as the primary attack (simplified: no light/heavy distinction per slot)
	var mechanic := str(weapon_data.get("heavy_mechanic", "single_target"))
	var is_heavy := true
	if _am():
		_am().play_sfx(_get_family_sfx(family, is_heavy))
	var category := str(weapon_data.get("category", "melee"))
	# M39 — Route through animation wrappers based on weapon category
	if category == "ranged":
		_execute_ranged_attack(weapon_data, mechanic)
	elif category == "magic":
		_execute_magic_attack(weapon_data, mechanic)
	else:
		_execute_melee_attack(weapon_data, mechanic)
	attack_hook_triggered.emit()
	_update_hud()

func _execute_melee_attack(weapon_data: Dictionary, mechanic: String) -> void:
	# M39 — Melee swing animation always plays
	_animate_player_melee_swing()
	# Range check: only deal damage if front enemy is within melee range
	var melee_range := _get_melee_range_for_slot(weapon_data)
	var dist := _get_front_enemy_distance()
	if dist > melee_range and mechanic != "sweep_all":
		# Out of range — show miss, deal no damage
		_spawn_miss_label(player.position)
		return
	match mechanic:
		"sweep_all":
			var sweep_ratio := float(weapon_data.get("light_sweep_ratio", 0.8))
			var base_dmg := int(weapon_data.get("heavy_damage", 28))
			var sweep_dmg := int(round(float(base_dmg) * sweep_ratio))
			_apply_damage_to_all_enemies(sweep_dmg)
		"lunge_poise":
			var base_dmg := int(weapon_data.get("heavy_damage", 28))
			_apply_damage_to_front_enemy(base_dmg, true)
		"drain_stamina":
			var base_dmg := int(weapon_data.get("heavy_damage", 18))
			_apply_damage_to_front_enemy(base_dmg)
			_apply_stamina_drain_to_front_enemy(2)
		_:
			var base_dmg := int(weapon_data.get("heavy_damage", int(weapon_data.get("light_damage", 14))))
			_apply_damage_to_front_enemy(base_dmg)

func _execute_ranged_attack(weapon_data: Dictionary, mechanic: String) -> void:
	# M39 — Ranged projectile: white 8x8 rect
	var target_idx := _get_front_enemy_index()
	if target_idx < 0:
		return
	var from_pos := player.position + Vector2(20, 0)
	var to_pos := enemy_nodes[target_idx].position if target_idx < enemy_nodes.size() else from_pos + Vector2(200, 0)
	var dmg := int(weapon_data.get("heavy_damage", int(weapon_data.get("light_damage", 18))))
	var w_data := weapon_data
	var mech := mechanic
	_spawn_projectile(from_pos, to_pos, Color(1.0, 1.0, 1.0, 1.0), 8.0, func():
		match mech:
			"ranged_single":
				_apply_damage_to_front_enemy(dmg)
			"charged_suppress":
				var suppress_ticks := int(w_data.get("heavy_suppress_ticks", 1))
				_suppress_front_enemy(suppress_ticks)
				_apply_damage_to_front_enemy(dmg)
			"ranged_pierce":
				var ratio := float(w_data.get("ranged_pierce_ratio", 1.0))
				var pierce_dmg := int(round(float(dmg) * ratio))
				_apply_damage_to_all_enemies(pierce_dmg)
			_:
				_apply_damage_to_front_enemy(dmg)
	)

func _execute_magic_attack(weapon_data: Dictionary, mechanic: String) -> void:
	# M39 — Magic projectile: purple 12x12 rect
	var target_idx := _get_front_enemy_index()
	if target_idx < 0:
		return
	var from_pos := player.position + Vector2(20, 0)
	var to_pos := enemy_nodes[target_idx].position if target_idx < enemy_nodes.size() else from_pos + Vector2(200, 0)
	var dmg := int(weapon_data.get("heavy_damage", int(weapon_data.get("light_damage", 14))))
	var mech := mechanic
	_spawn_projectile(from_pos, to_pos, Color(0.6, 0.2, 1.0, 1.0), 12.0, func():
		match mech:
			"arcane_burst":
				_apply_damage_to_all_enemies_with_poise(dmg)
			"drain_stamina":
				_apply_damage_to_front_enemy(dmg)
				_apply_stamina_drain_to_front_enemy(2)
			_:
				_apply_damage_to_front_enemy(dmg)
	)

func _on_dodge_triggered() -> void:
	dodge_count += 1
	dodge_hook_triggered.emit()
	if _am():
		_am().play_sfx("dodge")
	_update_hud()

func _on_guard_changed(is_guarding: bool) -> void:
	guard_active = is_guarding
	guard_hook_changed.emit(is_guarding)
	if is_guarding and _am():
		_am().play_sfx("guard_break")
	_update_hud()

func _update_hud() -> void:
	# Debug status label (small, subtle)
	var state_parts: PackedStringArray = []
	for index in enemies.size():
		var enemy := enemies[index]
		state_parts.append("E%d:%s(%d)" % [index + 1, EnemyController.state_name(enemy.state), enemy.health])
	var enemies_text := " | ".join(state_parts)
	if OS.is_debug_build():
		var m_data := _get_weapon_data_for_slot("melee")
		var r_data := _get_weapon_data_for_slot("ranged")
		var mg_data := _get_weapon_data_for_slot("magic")
		var m_name := str(m_data.get("name", "None"))
		var r_name := str(r_data.get("name", "None"))
		var mg_name := str(mg_data.get("name", "None"))
		combat_status.text = "M: %s | R: %s | Mg: %s | Ring %s | Atk %d Dodge %d | %s" % [
			m_name, r_name, mg_name,
			ring_id,
			attack_count,
			dodge_count,
			enemies_text,
		]
	else:
		combat_status.visible = false

	# Stat bars
	if hp_bar:
		hp_bar.value = (float(player_health) / float(player_max_health)) * 100.0
	if stamina_bar:
		stamina_bar.value = (player.stamina / float(player.max_stamina)) * 100.0


func _on_player_died() -> void:
	encounter_completed = true
	if _am():
		_am().play_sfx("player_death")
	set_arena_active(false)
	player_died.emit()

func _on_death_explosion(enemy_index: int) -> void:
	# glass_cannon_aggro: deal 8 damage to player if within 2 zones
	var player_zone := _player_zone()
	var distance := absf(float(enemy_index - player_zone)) + 0.5
	if distance <= 2.0:
		var dmg := 8
		if player.guarding:
			dmg = max(1, dmg / 2)
		player_health = max(0, player_health - dmg)
		if _gs(): _gs().record_damage_taken(dmg)
		_trigger_hit_stop()
		trigger_screen_shake(SHAKE_MAGNITUDE_MEDIUM, SHAKE_DURATION_DEFAULT)
		_flash_player_damage()
		if player_health <= 0:
			_on_player_died()


func _spawn_enemies(count: int) -> void:
	enemies.clear()
	_hit_flash_timers.clear()
	_hit_flash_types.clear()
	_enemy_suppress_ticks.clear()

	for node in enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	enemy_nodes.clear()
	enemy_sprites.clear()

	var archetypes := ["grunt", "ranged", "defender"]
	var arena_width := 960.0
	var spacing := arena_width / float(count + 1)

	for i in count:
		# Pull stats from DataStore if available
		var _ds_en: Node = get_node_or_null("/root/DataStore")
		var ring_enemies: Array = _ds_en.get_enemies_for_ring(ring_id) if _ds_en else []
		var enemy_data: Dictionary = {}
		if not ring_enemies.is_empty():
			enemy_data = ring_enemies[i % ring_enemies.size()]
		var hp: int = int(enemy_data.get("health", 100))
		var dmg: int = int(enemy_data.get("damage", 8))
		var ec := EnemyController.new(hp, 3.5, 1.2, dmg)
		ec.enemy_display_name = str(enemy_data.get("id", "Enemy")).replace("_", " ").capitalize()
		var profile := str(enemy_data.get("behavior_profile", Profiles.FRONTLINE_BASIC))
		# Inner ring enemies are melee-only; override ranged/zone profiles if they appear
		if ring_id == "inner" and (profile == Profiles.KITE_VOLLEY or profile == Profiles.ZONE_CONTROL):
			profile = Profiles.FRONTLINE_BASIC
		ec.apply_profile(profile)
		# Use data poise as threshold if profile didn't set a higher one
		var data_poise := int(enemy_data.get("poise", 20))
		if data_poise > ec.poise_threshold:
			ec.poise_threshold = data_poise
		# glass_cannon_aggro: wire death explosion
		if profile == Profiles.GLASS_CANNON_AGGRO:
			ec.death_explosion.connect(_on_death_explosion.bind(i))
		# phase_phantom: wire phase signals + configure durations from data
		if profile == Profiles.PHASE_PHANTOM:
			var p_dur := float(enemy_data.get("phase_duration", 2.5))
			var v_dur := float(enemy_data.get("vulnerable_duration", 1.8))
			ec.set_phase_durations(p_dur, v_dur)
			ec.damage_absorbed.connect(_on_damage_absorbed.bind(i))
			ec.phase_vulnerable.connect(_on_phase_vulnerable.bind(i))
			ec.phase_invulnerable.connect(_on_phase_invulnerable.bind(i))
		enemies.append(ec)
		_hit_flash_timers.append(0.0)
		_hit_flash_types.append("hit")
		_enemy_suppress_ticks.append(0)

		var archetype := "grunt"
		if count == 1 and ring_id == "outer":
			archetype = "warden"
		elif i < archetypes.size():
			archetype = archetypes[i]
		else:
			archetype = archetypes[i % archetypes.size()]

		var node := Node2D.new()
		var sprite := Sprite2D.new()

		var sprite_name := ENEMY_SPRITE_NAMES.get(archetype, "enemy_grunt.png") as String
		var tex_path := SPRITE_BASE + sprite_name
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path) as Texture2D

		if archetype == "warden":
			sprite.scale = Vector2(2.0, 2.0)

		node.add_child(sprite)
		enemy_container.add_child(node)
		node.position = Vector2(spacing * (i + 1), 280.0)

		enemy_nodes.append(node)
		enemy_sprites.append(sprite)


# ─── M30 Phase Phantom Signal Handlers ───────────────────────────────────────

func _on_damage_absorbed(enemy_index: int) -> void:
	if enemy_index < _hit_flash_timers.size():
		_hit_flash_timers[enemy_index] = PHASE_PHANTOM_FLASH_DURATION
		_hit_flash_types[enemy_index] = "phase_immune"

func _on_phase_vulnerable(enemy_index: int) -> void:
	if enemy_index < _hit_flash_timers.size():
		_hit_flash_timers[enemy_index] = PHASE_PHANTOM_FLASH_DURATION
		_hit_flash_types[enemy_index] = "phase_vulnerable"

func _on_phase_invulnerable(enemy_index: int) -> void:
	if enemy_index < _hit_flash_timers.size():
		_hit_flash_timers[enemy_index] = PHASE_PHANTOM_FLASH_DURATION
		_hit_flash_types[enemy_index] = "phase_invulnerable"


func _spawn_boss() -> void:
	enemies.clear()
	_hit_flash_timers.clear()
	_hit_flash_types.clear()
	_enemy_suppress_ticks.clear()
	_last_boss_phase = 1

	for node in enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	enemy_nodes.clear()
	enemy_sprites.clear()

	var _ds_boss: Node = get_node_or_null("/root/DataStore")
	var boss_data: Dictionary = _ds_boss.get_boss(ring_id) if _ds_boss else {}
	var hp: int = int(boss_data.get("health", 1200))
	var dmg: int = int(boss_data.get("damage", 18))
	var cooldown: float = float(boss_data.get("attack_cooldown", 2.5))
	var phases: int = int(boss_data.get("phases", 3))

	var ec := EnemyController.new(hp, 4.0, 1.5, dmg)
	ec.setup_boss(phases, cooldown)
	ec.enemy_display_name = "The Warden"
	enemies.append(ec)
	_hit_flash_timers.append(0.0)
	_hit_flash_types.append("hit")
	_enemy_suppress_ticks.append(0)
	encounter_enemy_count = 1

	var node := Node2D.new()
	var sprite := Sprite2D.new()
	var tex_path := SPRITE_BASE + "enemy_warden.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path) as Texture2D
	sprite.scale = Vector2(2.5, 2.5)
	node.add_child(sprite)
	enemy_container.add_child(node)
	node.position = Vector2(480.0, 280.0)
	enemy_nodes.append(node)
	enemy_sprites.append(sprite)


func _player_zone() -> int:
	var zone := int(round(player.position.x / 160.0))
	return clampi(zone, 0, max(0, enemies.size() - 1))


func _get_weapon_data_for_slot(slot: String) -> Dictionary:
	var weapon_id: String = ""
	match slot:
		"melee":
			weapon_id = _equipped_melee
		"ranged":
			weapon_id = _equipped_ranged
		"magic":
			weapon_id = _equipped_magic
	var ds := get_node_or_null("/root/DataStore")
	return ds.get_weapon(weapon_id) if ds and weapon_id != "" else {}

func _apply_damage_to_front_enemy(damage: int, force_poise_break: bool = false) -> void:
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state != EnemyController.EnemyState.DEAD:
			# guard_counter: if guarding, absorb hit and counter-attack
			if enemy.guarding and enemy.on_hit_while_guarding():
				# M35 — guard_penetration: weapon bypasses a fraction of guard absorption
				var guard_pen := float(_get_weapon_data_for_slot(_last_attack_slot).get("guard_penetration", 0.0))
				if guard_pen > 0.0:
					var pen_dmg := int(round(float(damage) * guard_pen))
					if pen_dmg > 0:
						enemy.apply_damage(pen_dmg, false)
						if _gs(): _gs().record_damage_dealt(pen_dmg)
				var counter_dmg := enemy.damage
				if player.guarding:
					counter_dmg = max(1, counter_dmg / 2)
				player_health = max(0, player_health - counter_dmg)
				if _gs(): _gs().record_damage_taken(counter_dmg)
				trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, SHAKE_DURATION_DEFAULT)
				if player_health <= 0:
					_on_player_died()
				return
			var prev_health := enemy.health
			var prev_state := enemy.state
			enemy.apply_damage(damage, force_poise_break or true)

			# phase_phantom: if health unchanged and not dead, damage was absorbed
			if enemy.behavior_profile == Profiles.PHASE_PHANTOM and enemy.health == prev_health and enemy.state != EnemyController.EnemyState.DEAD:
				# Immune flash — no damage tracked, no hit stop
				if i < _hit_flash_timers.size():
					_hit_flash_timers[i] = PHASE_PHANTOM_FLASH_DURATION
					_hit_flash_types[i] = "phase_immune"
				if _am():
					_am().play_sfx("hit_enemy")
				return

			# M21 — Track damage dealt
			if _gs(): _gs().record_damage_dealt(damage)

			# Hit flash — poise break gets distinct blue-white flash
			if i < _hit_flash_timers.size():
				if enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
					_hit_flash_timers[i] = POISE_BREAK_FLASH_DURATION
					_hit_flash_types[i] = "poise"
				else:
					_hit_flash_timers[i] = HIT_FLASH_HOLD + HIT_FLASH_LERP_DURATION
					_hit_flash_types[i] = "hit"

			# Hit stop on every landed hit
			_trigger_hit_stop()

			if enemy.state == EnemyController.EnemyState.DEAD and prev_state != EnemyController.EnemyState.DEAD:
				# Death: dissolve + medium shake
				_start_death_dissolve(i)
				trigger_screen_shake(SHAKE_MAGNITUDE_MEDIUM, SHAKE_DURATION_DEFAULT)
				if _gs(): _gs().record_enemy_killed()
				if _am():
					_am().play_sfx("enemy_death")
			elif enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
				# Poise break: distinct sound
				trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, 0.12)
				if _gs(): _gs().record_poise_break()
				if _am():
					_am().play_sfx("poise_break")
			else:
				# Regular hit: small shake
				trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, 0.12)
				if _am():
					_am().play_sfx("hit_enemy")
			return


func _apply_damage_to_all_enemies(damage: int) -> void:
	# Polearm sweep: hits all non-dead enemies
	var hit_any := false
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		var prev_health := enemy.health
		var prev_state := enemy.state
		enemy.apply_damage(damage, false)

		# phase_phantom: if health unchanged and not dead, damage was absorbed
		if enemy.behavior_profile == Profiles.PHASE_PHANTOM and enemy.health == prev_health and enemy.state != EnemyController.EnemyState.DEAD:
			if i < _hit_flash_timers.size():
				_hit_flash_timers[i] = PHASE_PHANTOM_FLASH_DURATION
				_hit_flash_types[i] = "phase_immune"
			continue

		hit_any = true
		# M21 — Track damage dealt
		if _gs(): _gs().record_damage_dealt(damage)

		if i < _hit_flash_timers.size():
			if enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
				_hit_flash_timers[i] = POISE_BREAK_FLASH_DURATION
				_hit_flash_types[i] = "poise"
			else:
				_hit_flash_timers[i] = HIT_FLASH_HOLD + HIT_FLASH_LERP_DURATION
				_hit_flash_types[i] = "hit"

		if enemy.state == EnemyController.EnemyState.DEAD and prev_state != EnemyController.EnemyState.DEAD:
			_start_death_dissolve(i)
			if _gs(): _gs().record_enemy_killed()
			if _am():
				_am().play_sfx("enemy_death")
		elif enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
			if _gs(): _gs().record_poise_break()
			if _am():
				_am().play_sfx("poise_break")
		else:
			if _am():
				_am().play_sfx("hit_enemy")

	if hit_any:
		_trigger_hit_stop()
		trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, 0.18)


func _apply_damage_to_all_enemies_with_poise(damage: int) -> void:
	# Arcane burst: hits all non-dead enemies with poise break
	var hit_any := false
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		var prev_health := enemy.health
		var prev_state := enemy.state
		enemy.apply_damage(damage, true)

		# phase_phantom: if health unchanged and not dead, damage was absorbed
		if enemy.behavior_profile == Profiles.PHASE_PHANTOM and enemy.health == prev_health and enemy.state != EnemyController.EnemyState.DEAD:
			if i < _hit_flash_timers.size():
				_hit_flash_timers[i] = PHASE_PHANTOM_FLASH_DURATION
				_hit_flash_types[i] = "phase_immune"
			continue

		hit_any = true
		if _gs(): _gs().record_damage_dealt(damage)

		if i < _hit_flash_timers.size():
			if enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
				_hit_flash_timers[i] = POISE_BREAK_FLASH_DURATION
				_hit_flash_types[i] = "poise"
			else:
				_hit_flash_timers[i] = HIT_FLASH_HOLD + HIT_FLASH_LERP_DURATION
				_hit_flash_types[i] = "hit"

		if enemy.state == EnemyController.EnemyState.DEAD and prev_state != EnemyController.EnemyState.DEAD:
			_start_death_dissolve(i)
			if _gs(): _gs().record_enemy_killed()
			if _am():
				_am().play_sfx("enemy_death")
		elif enemy.state == EnemyController.EnemyState.STAGGER and prev_state != EnemyController.EnemyState.STAGGER:
			if _gs(): _gs().record_poise_break()
			if _am():
				_am().play_sfx("poise_break")
		else:
			if _am():
				_am().play_sfx("hit_enemy")

	if hit_any:
		_trigger_hit_stop()
		trigger_screen_shake(SHAKE_MAGNITUDE_SMALL, 0.18)


func _apply_stamina_drain_to_front_enemy(ticks: int) -> void:
	# Void Lance heavy: apply stamina drain (skip attacks) to front enemy
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state != EnemyController.EnemyState.DEAD:
			enemy.stamina_drained_ticks = ticks
			return


func _suppress_front_enemy(ticks: int) -> void:
	# Bow heavy: suppress the first living enemy for N ticks
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state != EnemyController.EnemyState.DEAD:
			if i < _enemy_suppress_ticks.size():
				_enemy_suppress_ticks[i] = ticks
			return


func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			return false
	return true


# ─── Hit Stop (M19 T1) ───────────────────────────────────────────────────────

func _trigger_hit_stop() -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	_hit_stop_timer = HIT_STOP_DURATION
	_pre_hit_stop_time_scale = Engine.time_scale
	Engine.time_scale = HIT_STOP_TIME_SCALE

func _update_hit_stop(_delta: float) -> void:
	if not _hit_stop_active:
		return
	# Use unscaled time for hit stop duration
	_hit_stop_timer -= get_process_delta_time() / max(Engine.time_scale, 0.001)
	if _hit_stop_timer <= 0.0:
		_hit_stop_active = false
		Engine.time_scale = _pre_hit_stop_time_scale

# ─── Hit Flash (M19 T3 + T7) ────────────────────────────────────────────────

func _update_hit_flashes(delta: float) -> void:
	for i in _hit_flash_timers.size():
		if _hit_flash_timers[i] <= 0.0:
			continue
		_hit_flash_timers[i] -= delta
		if i >= enemy_sprites.size() or not is_instance_valid(enemy_sprites[i]):
			continue
		var sprite := enemy_sprites[i]
		var flash_type := _hit_flash_types[i] if i < _hit_flash_types.size() else "hit"

		if _hit_flash_timers[i] <= 0.0:
			# Flash complete — restore
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		elif flash_type == "poise":
			# Poise break: solid blue-white for full duration
			sprite.modulate = POISE_BREAK_FLASH_COLOR
		elif flash_type == "warden_phase":
			# Warden phase: hold the hit flash color longer
			sprite.modulate = HIT_FLASH_COLOR
		elif flash_type == "phase_immune":
			# M30 — Phase phantom: immune flash (blue-white pulse)
			sprite.modulate = PHASE_IMMUNE_FLASH_COLOR
		elif flash_type == "phase_vulnerable":
			# M30 — Phase phantom: vulnerability window opening
			sprite.modulate = PHASE_VULNERABLE_FLASH_COLOR
		elif flash_type == "phase_invulnerable":
			# M30 — Phase phantom: invulnerability resumed
			sprite.modulate = PHASE_INVULNERABLE_FLASH_COLOR
		else:
			# Normal hit: hold for 1 frame then lerp back
			var remaining := _hit_flash_timers[i]
			if remaining > HIT_FLASH_LERP_DURATION:
				# Hold phase
				sprite.modulate = HIT_FLASH_COLOR
			else:
				# Lerp phase
				var t := 1.0 - (remaining / HIT_FLASH_LERP_DURATION)
				sprite.modulate = HIT_FLASH_COLOR.lerp(Color(1.0, 1.0, 1.0, 1.0), t)


# ─── Player Attack Flash (M36) ───────────────────────────────────────────────

func _update_player_attack_flash(delta: float) -> void:
	if _player_attack_flash_timer <= 0.0:
		return
	_player_attack_flash_timer -= delta
	if not is_instance_valid(player_sprite):
		return
	var flash_color := _get_family_flash_color(_player_attack_flash_family)
	var durations := _get_family_flash_durations(_player_attack_flash_family)
	var lerp_dur: float = durations[1]
	if _player_attack_flash_timer <= 0.0:
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif _player_attack_flash_timer > lerp_dur:
		# Hold phase
		player_sprite.modulate = flash_color
	else:
		# Lerp back to normal
		var t := 1.0 - (_player_attack_flash_timer / lerp_dur)
		player_sprite.modulate = flash_color.lerp(Color(1.0, 1.0, 1.0, 1.0), t)


# ─── Player Damage Flash (zone_control / death explosion) ────────────────────

const PLAYER_DAMAGE_FLASH_COLOR := Color(1.5, 0.3, 0.3, 1.0)
const PLAYER_DAMAGE_FLASH_TOTAL := 0.2  # hold + lerp

func _flash_player_damage() -> void:
	_player_damage_flash_timer = PLAYER_DAMAGE_FLASH_TOTAL

func _update_player_damage_flash(delta: float) -> void:
	if _player_damage_flash_timer <= 0.0:
		return
	_player_damage_flash_timer -= delta
	if not is_instance_valid(player_sprite):
		return
	if _player_damage_flash_timer <= 0.0:
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif _player_damage_flash_timer > HIT_FLASH_LERP_DURATION:
		player_sprite.modulate = PLAYER_DAMAGE_FLASH_COLOR
	else:
		var t := 1.0 - (_player_damage_flash_timer / HIT_FLASH_LERP_DURATION)
		player_sprite.modulate = PLAYER_DAMAGE_FLASH_COLOR.lerp(Color(1.0, 1.0, 1.0, 1.0), t)


# ─── Death Dissolve ───────────────────────────────────────────────────────────

func _start_death_dissolve(enemy_index: int) -> void:
	if enemy_index >= enemy_sprites.size():
		return
	var sprite := enemy_sprites[enemy_index]
	if not is_instance_valid(sprite):
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.4)


# ─── M39 Attack Animations ──────────────────────────────────────────────────

func _animate_player_melee_swing() -> void:
	if not is_instance_valid(player_sprite):
		return
	var origin := player_sprite.position
	var tween := create_tween()
	tween.tween_property(player_sprite, "position", origin + Vector2(MELEE_LUNGE_PX, 0), MELEE_LUNGE_DURATION)
	tween.tween_property(player_sprite, "position", origin, MELEE_SNAP_BACK_DURATION)
	# Slash arc: short-lived Line2D near the player
	_spawn_slash_arc()

func _spawn_slash_arc() -> void:
	var arc := Line2D.new()
	arc.width = 3.0
	arc.default_color = Color(1.0, 1.0, 0.6, 1.0)
	# Draw a small arc in front of the player
	var base_pos := player.position + Vector2(40.0, 0.0)
	var points: PackedVector2Array = []
	for i in 7:
		var angle := deg_to_rad(-60.0 + (i * 20.0))
		points.append(base_pos + Vector2(cos(angle), sin(angle)) * 28.0)
	arc.points = points
	add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate", Color(1.0, 1.0, 0.6, 0.0), SLASH_ARC_FADE_DURATION)
	tween.tween_callback(arc.queue_free)

func _animate_enemy_attack(index: int) -> void:
	if index >= enemy_nodes.size():
		return
	var node := enemy_nodes[index]
	if not is_instance_valid(node):
		return
	var origin := node.position
	var tween := create_tween()
	tween.tween_property(node, "position", origin + Vector2(-ENEMY_LUNGE_PX, 0), ENEMY_LUNGE_DURATION)
	tween.tween_property(node, "position", origin, ENEMY_SNAP_BACK_DURATION)

func _spawn_projectile(from_pos: Vector2, to_pos: Vector2, color: Color, size: float, on_hit: Callable) -> void:
	var proj := ColorRect.new()
	proj.size = Vector2(size, size)
	proj.color = color
	proj.position = from_pos - Vector2(size / 2.0, size / 2.0)
	add_child(proj)
	var tween := create_tween()
	tween.tween_property(proj, "position", to_pos - Vector2(size / 2.0, size / 2.0), PROJECTILE_TRAVEL_DURATION)
	tween.tween_callback(on_hit)
	tween.tween_callback(proj.queue_free)

func _spawn_miss_label(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "Miss"
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	label.position = pos + Vector2(-15, -40)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -20), MISS_LABEL_DURATION)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), MISS_LABEL_DURATION)
	tween.tween_callback(label.queue_free)

func _get_front_enemy_index() -> int:
	for i in enemies.size():
		if enemies[i].state != EnemyController.EnemyState.DEAD:
			return i
	return -1

func _get_front_enemy_distance() -> float:
	var idx := _get_front_enemy_index()
	if idx < 0:
		return 999.0
	if idx < enemy_nodes.size():
		return absf(enemy_nodes[idx].position.x - player.position.x) / 160.0
	var player_zone := _player_zone()
	return absf(float(idx - player_zone)) + 0.5

func _get_melee_range_for_slot(weapon_data: Dictionary) -> float:
	return float(weapon_data.get("melee_range", DEFAULT_MELEE_RANGE))

func _update_enemy_telegraph(delta: float) -> void:
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		if i >= enemy_sprites.size() or not is_instance_valid(enemy_sprites[i]):
			continue
		# Skip if a hit flash is active (don't override it)
		if i < _hit_flash_timers.size() and _hit_flash_timers[i] > 0.0:
			continue
		var readiness := enemy.get_attack_readiness()
		var sprite := enemy_sprites[i]
		if readiness > TELEGRAPH_READINESS_THRESHOLD and (enemy.state == EnemyController.EnemyState.CHASE or enemy.state == EnemyController.EnemyState.ATTACK):
			var t := (readiness - TELEGRAPH_READINESS_THRESHOLD) / (1.0 - TELEGRAPH_READINESS_THRESHOLD)
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(TELEGRAPH_COLOR, t)
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


# ─── Screen Shake (M19 T2) ──────────────────────────────────────────────────

func trigger_screen_shake(amount: float = 6.0, duration: float = 0.25) -> void:
	# Only override if new shake is stronger
	if amount >= _shake_amount:
		_shake_amount = amount
		_shake_timer = duration

func _update_camera_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var shake_x := randf_range(-_shake_amount, _shake_amount)
		var shake_y := randf_range(-_shake_amount, _shake_amount)
		camera.offset = _camera_origin + Vector2(shake_x, shake_y)
	else:
		camera.offset = _camera_origin


# ─── Phase Transition Flash (M19 T4) ────────────────────────────────────────

func _setup_phase_flash_overlay() -> void:
	_phase_flash_overlay = ColorRect.new()
	_phase_flash_overlay.name = "PhaseFlashOverlay"
	_phase_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_phase_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Add to HUD CanvasLayer so it covers the screen
	var hud := $HUD as CanvasLayer
	if hud:
		var rect := _phase_flash_overlay
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hud.add_child(rect)

func _trigger_phase_flash() -> void:
	if _phase_flash_overlay == null:
		return
	_phase_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.3)
	var tween := create_tween()
	tween.tween_property(_phase_flash_overlay, "color", Color(1.0, 1.0, 1.0, 0.0), 0.5)
