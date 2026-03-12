extends RefCounted
class_name EnemyController

enum EnemyState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	DEAD,
}

signal attack_resolved(damage_amount: int)

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

func _init(max_health: int = 100, chase_distance: float = 6.0, attack_distance: float = 1.8, p_damage: int = 10) -> void:
	health = max_health
	chase_range = chase_distance
	attack_range = attack_distance
	damage = p_damage

func tick(distance_to_player: float, delta: float) -> EnemyState:
	if state == EnemyState.DEAD:
		return state

	if state == EnemyState.STAGGER:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			state = EnemyState.CHASE
		return state

	if distance_to_player <= attack_range and distance_to_player >= preferred_min_range:
		state = EnemyState.ATTACK
		if attack_cooldown_timer <= 0.0 and not guard_query.call():
			attack_cooldown_timer = attack_cooldown
			attack_resolved.emit(damage)
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
		EnemyState.ATTACK:
			return "ATTACK"
		EnemyState.STAGGER:
			return "STAGGER"
		EnemyState.DEAD:
			return "DEAD"
		_:
			return "UNKNOWN"
