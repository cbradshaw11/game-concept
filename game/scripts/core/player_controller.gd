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

# M26 — Modifier-adjusted stats (recalculated on modifier change)
var effective_max_hp: int = 100
var effective_max_stamina: int = 100
var effective_dodge_cost: int = 22

func _ready() -> void:
	stamina = float(max_stamina)
	effective_max_stamina = max_stamina
	effective_dodge_cost = dodge_cost
	var mm := _get_modifier_manager()
	if mm:
		mm.modifier_added.connect(_on_modifier_changed)
		mm.modifiers_cleared.connect(_on_modifier_changed)

func _get_modifier_manager() -> Node:
	if Engine.get_main_loop() == null:
		return null
	return Engine.get_main_loop().root.get_node_or_null("ModifierManager")

func _get_game_state() -> Node:
	if Engine.get_main_loop() == null:
		return null
	return Engine.get_main_loop().root.get_node_or_null("GameState")

func _on_modifier_changed(_mod: Variant = null) -> void:
	recalculate_modifiers()

func recalculate_modifiers() -> void:
	## Recalculate effective stats based on active run modifiers + permanent unlocks.
	var mm := _get_modifier_manager()
	var gs := _get_game_state()
	var hp_flat := int(mm.get_stat_bonus("max_hp_flat")) if mm else 0
	var hp_pct: float = mm.get_stat_bonus("max_hp_pct") if mm else 0.0
	# M27 — tougher_start permanent unlock: +8 max HP
	if gs and gs.has_method("has_permanent_unlock") and gs.has_permanent_unlock("tougher_start"):
		hp_flat += 8
	effective_max_hp = int(round((100 + hp_flat) * (1.0 + hp_pct)))

	var stam_flat := int(mm.get_stat_bonus("max_stamina_flat")) if mm else 0
	# M27 — extra_stamina permanent unlock: +10 max stamina
	if gs and gs.has_method("has_permanent_unlock") and gs.has_permanent_unlock("extra_stamina"):
		stam_flat += 10
	effective_max_stamina = max_stamina + stam_flat
	stamina = min(stamina, float(effective_max_stamina))

	var dodge_flat := int(mm.get_stat_bonus("dodge_cost_flat")) if mm else 0
	effective_dodge_cost = max(0, dodge_cost + dodge_flat)

func get_damage_multiplier() -> float:
	## Returns combined damage multiplier from run modifiers.
	var mm := _get_modifier_manager()
	if not mm:
		return 1.0
	return 1.0 + mm.get_stat_bonus("damage_pct")

func get_damage_taken_multiplier() -> float:
	## Returns combined damage-taken multiplier from run modifiers.
	var mm := _get_modifier_manager()
	if not mm:
		return 1.0
	return 1.0 + mm.get_stat_bonus("damage_taken_pct")

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * move_speed
	move_and_slide()

	# M38 — Attack inputs now handled by combat_arena (three-slot system)
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
	if stamina < effective_dodge_cost:
		return false
	stamina -= effective_dodge_cost
	dodge_triggered.emit()
	return true

func set_guarding(value: bool) -> void:
	guarding = value
	guard_changed.emit(guarding)

func regenerate_stamina(delta: float) -> void:
	stamina = min(float(effective_max_stamina), stamina + (stamina_regen_per_sec * delta))
