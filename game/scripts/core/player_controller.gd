extends CharacterBody2D
class_name PlayerController

signal attack_triggered
signal dodge_triggered
signal guard_changed(is_guarding: bool)
signal guard_broken()
signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: int)
signal player_died()
signal poise_changed(current: int, maximum: int)
signal player_staggered()
signal attack_evaded()

const GUARD_BREAK_THRESHOLD: int = 30

@export var move_speed: float = 180.0
@export var max_stamina: int = 100
@export var stamina_regen_per_sec: float = 18.0
@export var attack_cost: int = 12
@export var dodge_cost: int = 22

var stamina: float = 100.0
var guarding: bool = false
var guard_efficiency: float = 0.0
var current_health: int
var max_health: int
var current_poise: int
var max_poise: int
var is_staggered: bool = false
var stagger_duration: float = 0.5
var is_invulnerable: bool = false
var dodge_iframe_duration: float = 0.22
var dodge_cooldown_duration: float = 0.5
var dodge_cooldown_timer: float = 0.0

func _ready() -> void:
	stamina = float(max_stamina)
	var combat_data: Dictionary = DataStore.weapons.get("global_combat", {})
	max_health = combat_data.get("max_health", 100)
	current_health = max_health
	max_poise = combat_data.get("max_poise", 100)
	current_poise = max_poise
	dodge_iframe_duration = combat_data.get("dodge_iframe_ms", 220) / 1000.0
	var all_weapons: Array = DataStore.weapons.get("weapons", [])
	for w in all_weapons:
		if w.get("id") == GameState.selected_weapon_id:
			guard_efficiency = w.get("guard_efficiency", 0.0)
			break

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		try_attack()
	if Input.is_action_just_pressed("ui_select"):
		try_dodge()

	var next_guarding := Input.is_action_pressed("ui_cancel")
	if next_guarding != guarding:
		set_guarding(next_guarding)

	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
	regenerate_stamina(delta)

func try_attack() -> bool:
	if is_staggered:
		return false
	if stamina < attack_cost:
		return false
	stamina -= attack_cost
	stamina_changed.emit(stamina, max_stamina)
	attack_triggered.emit()
	return true

func try_dodge() -> bool:
	if is_staggered:
		return false
	if dodge_cooldown_timer > 0.0:
		return false
	if stamina < dodge_cost:
		return false
	stamina -= dodge_cost
	stamina_changed.emit(stamina, max_stamina)
	dodge_triggered.emit()
	_start_iframe_window()
	return true

func _start_iframe_window() -> void:
	is_invulnerable = true
	dodge_cooldown_timer = dodge_cooldown_duration
	await get_tree().create_timer(dodge_iframe_duration).timeout
	is_invulnerable = false

func set_guarding(value: bool) -> void:
	guarding = value
	guard_changed.emit(guarding)

func regenerate_stamina(delta: float) -> void:
	stamina = min(float(max_stamina), stamina + (stamina_regen_per_sec * delta))
	stamina_changed.emit(stamina, max_stamina)

func take_damage(amount: int) -> void:
	if is_invulnerable:
		attack_evaded.emit()
		return
	var effective_damage = amount
	if guarding:
		if amount > GUARD_BREAK_THRESHOLD:
			guard_broken.emit()
			guarding = false
			effective_damage = amount - GUARD_BREAK_THRESHOLD
		else:
			effective_damage = int(amount * (1.0 - guard_efficiency))
	current_health = max(0, current_health - effective_damage)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		player_died.emit()

func take_poise_damage(amount: int) -> void:
	if is_staggered:
		return
	current_poise = max(0, current_poise - amount)
	poise_changed.emit(current_poise, max_poise)
	if current_poise <= 0:
		_trigger_stagger()

func _trigger_stagger() -> void:
	is_staggered = true
	player_staggered.emit()
	await get_tree().create_timer(stagger_duration).timeout
	is_staggered = false
	current_poise = max_poise
	poise_changed.emit(current_poise, max_poise)
