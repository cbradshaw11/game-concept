extends CharacterBody2D
class_name PlayerController

signal attack_triggered
signal dodge_triggered
signal guard_changed(is_guarding: bool)

@export var move_speed: float = 180.0
@export var max_stamina: int = 100
@export var stamina_regen_per_sec: float = 18.0
@export var attack_cost: int = 12
@export var dodge_cost: int = 22

var stamina: float = 100.0
var guarding: bool = false

func _ready() -> void:
	stamina = float(max_stamina)

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

	regenerate_stamina(delta)

func try_attack() -> bool:
	if stamina < attack_cost:
		return false
	stamina -= attack_cost
	attack_triggered.emit()
	return true

func try_dodge() -> bool:
	if stamina < dodge_cost:
		return false
	stamina -= dodge_cost
	dodge_triggered.emit()
	return true

func set_guarding(value: bool) -> void:
	guarding = value
	guard_changed.emit(guarding)

func regenerate_stamina(delta: float) -> void:
	stamina = min(float(max_stamina), stamina + (stamina_regen_per_sec * delta))
