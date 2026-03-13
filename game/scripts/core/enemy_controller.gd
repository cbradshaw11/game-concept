extends RefCounted
class_name EnemyController

enum EnemyState {
	IDLE,
	CHASE,
	WIND_UP,
	ATTACK,
	STAGGER,
	DEAD,
}

signal attack_resolved(damage_amount: int)
signal wind_up_started

var state: EnemyState = EnemyState.IDLE
var health: int
var attack_range: float
var chase_range: float
var stagger_timer: float = 0.0
var damage: int = 0
var attack_cooldown_timer: float = 0.0
var attack_cooldown: float = 1.5
var preferred_min_range: float = 0.0
var guard_query: Callable = func() -> bool: return false
var wind_up_timer: float = 0.0
const WIND_UP_DURATION: float = 0.2
var is_boss: bool = false
var initial_health: int = 0
var damage_multiplier: float = 1.0
var _current_phase: int = 1

func _init(max_health: int = 100, chase_distance: float = 6.0, attack_distance: float = 1.8, p_damage: int = 10) -> void:
	health = max_health
	initial_health = max_health
	chase_range = chase_distance
	attack_range = attack_distance
	damage = p_damage

func _update_boss_phase() -> void:
	if not is_boss or initial_health <= 0:
		return
	var hp_ratio: float = float(health) / float(initial_health)
	var target_phase: int = 1
	if hp_ratio <= 0.35:
		target_phase = 3
	elif hp_ratio <= 0.70:
		target_phase = 2
	# Phases only advance, never regress
	if target_phase <= _current_phase:
		return
	_current_phase = target_phase
	if _current_phase == 2:
		damage_multiplier = 1.25
		attack_cooldown = 0.6
		if GameState.warden_phase_reached < 2:
			GameState.warden_phase_reached = 2
	elif _current_phase == 3:
		damage_multiplier = 1.5
		attack_cooldown = 0.4
		preferred_min_range = 0.0
		if GameState.warden_phase_reached < 3:
			GameState.warden_phase_reached = 3

func tick(distance_to_player: float, delta: float) -> EnemyState:
	if state == EnemyState.DEAD:
		return state

	_update_boss_phase()

	if state == EnemyState.STAGGER:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			state = EnemyState.CHASE
		return state

	if state == EnemyState.WIND_UP:
		wind_up_timer -= delta
		if wind_up_timer <= 0.0:
			state = EnemyState.ATTACK
			attack_cooldown_timer = attack_cooldown
			var final_damage: int = int(float(damage) * damage_multiplier)
			attack_resolved.emit(final_damage)
		return state

	if distance_to_player <= attack_range and distance_to_player >= preferred_min_range:
		if attack_cooldown_timer <= 0.0 and not guard_query.call():
			state = EnemyState.WIND_UP
			wind_up_timer = WIND_UP_DURATION
			wind_up_started.emit()
		else:
			state = EnemyState.ATTACK
	elif distance_to_player <= chase_range:
		state = EnemyState.CHASE
	else:
		state = EnemyState.IDLE

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	return state

func apply_damage(amount: int, poise_break: bool = false) -> EnemyState:
	if state == EnemyState.DEAD:
		return state

	health = max(health - amount, 0)
	if health == 0:
		state = EnemyState.DEAD
		return state

	if poise_break:
		state = EnemyState.STAGGER
		stagger_timer = 0.6
	return state

static func state_name(value: EnemyState) -> String:
	match value:
		EnemyState.IDLE:
			return "IDLE"
		EnemyState.CHASE:
			return "CHASE"
		EnemyState.WIND_UP:
			return "WIND_UP"
		EnemyState.ATTACK:
			return "ATTACK"
		EnemyState.STAGGER:
			return "STAGGER"
		EnemyState.DEAD:
			return "DEAD"
		_:
			return "UNKNOWN"
