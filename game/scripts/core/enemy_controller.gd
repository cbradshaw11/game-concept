extends RefCounted
class_name EnemyController

enum EnemyState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	DEAD,
}

var state: EnemyState = EnemyState.IDLE
var health: int
var initial_health: int
var damage: int = 8
var attack_range: float
var chase_range: float
var stagger_timer: float = 0.0
var attack_cooldown: float = 1.5
var _attack_timer: float = 0.0
var enemy_display_name: String = "Enemy"

func _init(max_health: int = 100, chase_distance: float = 6.0, attack_distance: float = 1.8, base_damage: int = 8) -> void:
	health = max_health
	initial_health = max_health
	chase_range = chase_distance
	attack_range = attack_distance
	damage = base_damage

## Returns true if the enemy attacks this tick (caller should apply damage to player)
func tick(distance_to_player: float, delta: float) -> bool:
	if state == EnemyState.DEAD:
		return false

	if state == EnemyState.STAGGER:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			state = EnemyState.CHASE
		return false

	_attack_timer = max(0.0, _attack_timer - delta)

	if distance_to_player <= attack_range:
		state = EnemyState.ATTACK
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			return true
	elif distance_to_player <= chase_range:
		state = EnemyState.CHASE
	else:
		state = EnemyState.IDLE
	return false

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
