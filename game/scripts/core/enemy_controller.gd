extends RefCounted
class_name EnemyController

const Profiles = preload("res://scripts/core/behavior_profiles.gd")

enum EnemyState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	DEAD,
	RETREAT,
	GUARD,
}

signal death_explosion
signal damage_absorbed
signal phase_vulnerable
signal phase_invulnerable

var state: EnemyState = EnemyState.IDLE
var health: int
var initial_health: int
var damage: int = 8
var base_damage: int = 8
var attack_range: float
var chase_range: float
var stagger_timer: float = 0.0
var attack_cooldown: float = 1.5
var base_attack_cooldown: float = 1.5
var _attack_timer: float = 0.0
var enemy_display_name: String = "Enemy"

# Boss phase system
var is_boss: bool = false
var boss_phase: int = 1
var boss_phases: int = 1

# Behavior profile system
var behavior_profile: String = Profiles.FRONTLINE_BASIC
var poise_threshold: int = 1

# guard_counter profile
var guarding: bool = false
var counter_pending: bool = false
var _guard_timer: float = 0.0
var _guard_chance: float = 0.4
var _guard_duration: float = 1.5

# flank_aggressive profile
var flank_offset: float = 2.0
var prefers_flank: bool = false

# kite_volley profile
var retreat_distance: float = 3.0
var _melee_fallback: bool = false
var _melee_fallback_timer: float = 0.0
var _kite_attack_range: float = 5.0
var _kite_cooldown: float = 2.5

# zone_control profile
var zone_active: bool = false
var _zone_timer: float = 0.0
var zone_damage_per_second: float = 4.0
var zone_radius: float = 2.5

# elite_pressure profile
var player_hp_percent: float = 1.0
var _poise_immune: bool = false

# phase_phantom profile
var phase_timer: float = 0.0
var is_vulnerable: bool = false
var phase_duration: float = 2.5
var vulnerable_duration: float = 1.8


func _init(max_health: int = 100, chase_distance: float = 6.0, attack_distance: float = 1.8, base_dmg: int = 8) -> void:
	health = max_health
	initial_health = max_health
	chase_range = chase_distance
	attack_range = attack_distance
	damage = base_dmg
	base_damage = base_dmg
	base_attack_cooldown = attack_cooldown

## Apply a behavior profile that sets combat parameters and special abilities.
func apply_profile(profile: String) -> void:
	behavior_profile = profile
	match profile:
		Profiles.FRONTLINE_BASIC:
			chase_range = 5.0
			attack_range = 1.5
			attack_cooldown = 1.5
			base_attack_cooldown = 1.5
		Profiles.GUARD_COUNTER:
			chase_range = 4.0
			attack_range = 1.8
			attack_cooldown = 2.0
			base_attack_cooldown = 2.0
		Profiles.FLANK_AGGRESSIVE:
			chase_range = 7.0
			attack_range = 1.6
			attack_cooldown = 1.2
			base_attack_cooldown = 1.2
			prefers_flank = true
		Profiles.KITE_VOLLEY:
			chase_range = 8.0
			attack_range = 5.0
			attack_cooldown = 2.5
			base_attack_cooldown = 2.5
			retreat_distance = 3.0
			_kite_attack_range = 5.0
			_kite_cooldown = 2.5
		Profiles.ZONE_CONTROL:
			chase_range = 6.0
			attack_range = 4.0
			attack_cooldown = 3.5
			base_attack_cooldown = 3.5
		Profiles.GLASS_CANNON_AGGRO:
			chase_range = 9.0
			attack_range = 1.4
			attack_cooldown = 0.8
			base_attack_cooldown = 0.8
		Profiles.POISE_GATE_TANK:
			chase_range = 3.5
			attack_range = 1.6
			attack_cooldown = 2.2
			base_attack_cooldown = 2.2
			poise_threshold = 60
		Profiles.ELITE_PRESSURE:
			chase_range = 8.0
			attack_range = 2.0
			attack_cooldown = 1.0
			base_attack_cooldown = 1.0
			_poise_immune = true
		Profiles.PHASE_PHANTOM:
			chase_range = 7.0
			attack_range = 1.8
			attack_cooldown = 1.2
			base_attack_cooldown = 1.2
			is_vulnerable = false
			phase_timer = phase_duration

## Configure this enemy as a boss with phase transitions.
func setup_boss(phases: int, cooldown: float) -> void:
	is_boss = true
	boss_phases = phases
	boss_phase = 1
	base_attack_cooldown = cooldown
	attack_cooldown = cooldown

## Returns the current boss phase (1-indexed). Non-bosses always return 1.
func get_boss_phase() -> int:
	return boss_phase

## Returns true if the enemy attacks this tick (caller should apply damage to player).
## For zone_control, also updates zone timer. Caller handles zone proximity damage.
func tick(distance_to_player: float, delta: float) -> bool:
	if state == EnemyState.DEAD:
		return false

	if state == EnemyState.STAGGER:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			state = EnemyState.CHASE
		return false

	# Update profile-specific timers
	_update_guard_counter(distance_to_player, delta)
	_update_zone_control(delta)
	_update_kite_fallback(delta)
	_update_elite_pressure_damage()
	_update_phase_phantom(delta)

	# Guard state blocks normal action
	if guarding:
		return false

	_attack_timer = max(0.0, _attack_timer - delta)

	# kite_volley: retreat if player is too close
	if behavior_profile == Profiles.KITE_VOLLEY and not _melee_fallback:
		if distance_to_player < retreat_distance:
			state = EnemyState.RETREAT
			return false

	if distance_to_player <= attack_range:
		state = EnemyState.ATTACK
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			# zone_control: activate zone after each attack
			if behavior_profile == Profiles.ZONE_CONTROL:
				zone_active = true
				_zone_timer = 2.5
			return true
	elif distance_to_player <= chase_range:
		state = EnemyState.CHASE
	else:
		state = EnemyState.IDLE
	return false

## Called by combat_arena when this enemy is hit while guarding (guard_counter profile).
## Returns true if a counter-attack should fire immediately.
func on_hit_while_guarding() -> bool:
	if guarding:
		guarding = false
		_guard_timer = 0.0
		counter_pending = true
		return true
	return false

## Update guard_counter behavior: chance to enter guard when player is in range.
func _update_guard_counter(distance_to_player: float, delta: float) -> void:
	if behavior_profile != Profiles.GUARD_COUNTER:
		return
	if guarding:
		_guard_timer -= delta
		if _guard_timer <= 0.0:
			guarding = false
		return
	# Chance to enter guard when player is in attack range and cooldown ready
	if distance_to_player <= attack_range and _attack_timer <= 0.0:
		if randf() < _guard_chance:
			guarding = true
			_guard_timer = _guard_duration
			_attack_timer = _guard_duration  # prevent re-rolling during guard
			state = EnemyState.GUARD

## Update zone_control zone timer.
func _update_zone_control(delta: float) -> void:
	if behavior_profile != Profiles.ZONE_CONTROL:
		return
	if zone_active:
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			zone_active = false

## Returns zone proximity damage for this tick (caller applies to player if in range).
func get_zone_damage(distance_to_player: float, delta: float) -> float:
	if behavior_profile != Profiles.ZONE_CONTROL:
		return 0.0
	if not zone_active:
		return 0.0
	if distance_to_player <= zone_radius:
		return zone_damage_per_second * delta
	return 0.0

## Update kite_volley melee fallback timer.
func _update_kite_fallback(delta: float) -> void:
	if behavior_profile != Profiles.KITE_VOLLEY:
		return
	if _melee_fallback:
		_melee_fallback_timer -= delta
		if _melee_fallback_timer <= 0.0:
			_melee_fallback = false
			attack_range = _kite_attack_range
			attack_cooldown = _kite_cooldown
			base_attack_cooldown = _kite_cooldown

## Called by combat_arena when kiter is cornered (cannot retreat further).
func enter_melee_fallback() -> void:
	if behavior_profile != Profiles.KITE_VOLLEY:
		return
	_melee_fallback = true
	_melee_fallback_timer = 2.0
	attack_range = 1.5
	attack_cooldown = 1.0
	base_attack_cooldown = 1.0

## Update elite_pressure damage scaling based on player HP.
func _update_elite_pressure_damage() -> void:
	if behavior_profile != Profiles.ELITE_PRESSURE:
		return
	if player_hp_percent < 0.5:
		damage = int(round(float(base_damage) * 1.2))
	else:
		damage = base_damage

## Set player HP percent for elite_pressure scaling.
func set_player_hp_percent(percent: float) -> void:
	player_hp_percent = percent

## Update phase_phantom phase cycling timer.
func _update_phase_phantom(delta: float) -> void:
	if behavior_profile != Profiles.PHASE_PHANTOM:
		return
	phase_timer -= delta
	if phase_timer <= 0.0:
		if is_vulnerable:
			# Transition to invulnerable
			is_vulnerable = false
			phase_timer = phase_duration
			phase_invulnerable.emit()
		else:
			# Transition to vulnerable
			is_vulnerable = true
			phase_timer = vulnerable_duration
			phase_vulnerable.emit()

## Configure phase durations from enemy data.
func set_phase_durations(p_duration: float, v_duration: float) -> void:
	phase_duration = p_duration
	vulnerable_duration = v_duration
	if not is_vulnerable:
		phase_timer = phase_duration

var _poise_damage_accumulated: int = 0

func apply_damage(amount: int, poise_break: bool = false) -> EnemyState:
	if state == EnemyState.DEAD:
		return state

	# phase_phantom: absorb damage while invulnerable
	if behavior_profile == Profiles.PHASE_PHANTOM and not is_vulnerable:
		damage_absorbed.emit()
		return state

	health = max(health - amount, 0)
	if health == 0:
		state = EnemyState.DEAD
		# glass_cannon_aggro: emit death explosion
		if behavior_profile == Profiles.GLASS_CANNON_AGGRO:
			death_explosion.emit()
		return state

	# Check boss phase transitions after taking damage
	if is_boss:
		_check_phase_transition()

	if poise_break and not _poise_immune:
		_poise_damage_accumulated += amount
		if _poise_damage_accumulated >= poise_threshold:
			state = EnemyState.STAGGER
			stagger_timer = 0.6
			_poise_damage_accumulated = 0
	return state

## Boss phase transition logic:
## Phase 1 (100%-70% HP): base stats
## Phase 2 (70%-35% HP): +25% damage, reduced cooldown
## Phase 3 (<35% HP): +50% damage, further reduced cooldown
func _check_phase_transition() -> void:
	if not is_boss or boss_phases < 2:
		return
	var hp_ratio := float(health) / float(initial_health)
	var new_phase := 1
	if hp_ratio <= 0.35 and boss_phases >= 3:
		new_phase = 3
	elif hp_ratio <= 0.70 and boss_phases >= 2:
		new_phase = 2
	if new_phase != boss_phase:
		boss_phase = new_phase
		_apply_phase_scaling()

func _apply_phase_scaling() -> void:
	match boss_phase:
		2:
			damage = int(round(float(base_damage) * 1.25))
			attack_cooldown = base_attack_cooldown * 0.8
		3:
			damage = int(round(float(base_damage) * 1.50))
			attack_cooldown = base_attack_cooldown * 0.6
		_:
			damage = base_damage
			attack_cooldown = base_attack_cooldown

static func state_name(value: EnemyState) -> String:
	match value:
		EnemyState.IDLE:
			return "IDLE"
		EnemyState.CHASE:
			return "CHASE"
		EnemyState.ATTACK:
			return "ATTACK"
		EnemyState.STAGGER:
			return "STAGGER"
		EnemyState.DEAD:
			return "DEAD"
		EnemyState.RETREAT:
			return "RETREAT"
		EnemyState.GUARD:
			return "GUARD"
		_:
			return "UNKNOWN"
