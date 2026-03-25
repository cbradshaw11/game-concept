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

func _init(max_health: int = 100, chase_distance: float = 6.0, attack_distance: float = 1.8, base_dmg: int = 8) -> void:
	health = max_health
	initial_health = max_health
	chase_range = chase_distance
	attack_range = attack_distance
	damage = base_dmg
	base_damage = base_dmg
	base_attack_cooldown = attack_cooldown

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

	# Check boss phase transitions after taking damage
	if is_boss:
		_check_phase_transition()

	if poise_break:
		state = EnemyState.STAGGER
		stagger_timer = 0.6
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
			attack_cooldown = base_attack_cooldown * 0.8  # 2.5 -> 2.0
		3:
			damage = int(round(float(base_damage) * 1.50))
			attack_cooldown = base_attack_cooldown * 0.6  # 2.5 -> 1.5
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
		_:
			return "UNKNOWN"
