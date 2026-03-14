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
signal heavy_attack_triggered(damage: int)

const GUARD_BREAK_THRESHOLD: int = 30

@export var move_speed: float = 180.0
@export var max_stamina: int = 100
@export var stamina_regen_per_sec: float = 18.0
@export var attack_cost: int = 12
@export var dodge_cost: int = 22

var stamina: float = 100.0
var guarding: bool = false
var guard_efficiency: float = 0.0
var heavy_damage: int = 24
var heavy_stamina_cost: float = 18.0
var current_health: int
var max_health: int
var current_poise: int
var max_poise: int
var is_staggered: bool = false
var stagger_duration: float = 0.5
var is_invulnerable: bool = false
var _conditional_bonuses: Dictionary = {}  # stat -> bonus_value
var dodge_iframe_duration: float = 0.22
var dodge_cooldown_duration: float = 0.5
var dodge_cooldown_timer: float = 0.0
var light_stamina_cost_multiplier: float = 1.0
var _last_rites_available: bool = false
var poise_damage_bonus: int = 0
var guard_damage_reduction: float = 0.0
var light_attack_bonus: int = 0
var stamina_on_kill: float = 0.0

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

func apply_upgrade(upgrade: Dictionary) -> void:
	var stat: String = upgrade.get("stat", "")
	var mod_type: String = upgrade.get("modifier_type", "add")
	var value = upgrade.get("value", 0)
	# Conditional upgrades are tracked dynamically via _conditional_bonuses.
	# Do not add them as flat stat changes -- just trigger a recalc so the
	# bonus is active immediately if the player is already below the threshold.
	if mod_type == "conditional_health_pct":
		_recalculate_conditional_bonuses()
		return
	match stat:
		"max_health":
			max_health += int(value)
			current_health = min(current_health + int(value), max_health)
			health_changed.emit(current_health, max_health)
		"max_stamina":
			max_stamina += int(value)
			stamina = min(stamina + float(value), float(max_stamina))
			stamina_changed.emit(stamina, max_stamina)
		"attack_damage":
			if "heavy_damage" in self:
				heavy_damage += int(value)
		"guard_efficiency":
			guard_efficiency = min(guard_efficiency + float(value), 0.95)
		"max_poise":
			max_poise += int(value)
		"stamina_regen_rate":
			if mod_type == "multiply":
				stamina_regen_per_sec *= float(value)
			else:
				stamina_regen_per_sec += float(value)
		"xp_multiplier":
			GameState.xp_gain_multiplier = max(GameState.xp_gain_multiplier + float(value), 0.1)
		"heavy_stamina_cost":
			heavy_stamina_cost = max(4.0, heavy_stamina_cost + float(value))
		"warden_map_owned":
			GameState.warden_map_unlocked = true
		"dodge_stamina_cost":
			dodge_cost = max(1, dodge_cost + int(value))
		"poise_damage_bonus":
			poise_damage_bonus += int(value)
		"guard_damage_reduction":
			guard_damage_reduction = min(0.95, guard_damage_reduction + float(value))
		"light_attack_bonus":
			light_attack_bonus += int(value)
		"stamina_on_kill":
			stamina_on_kill += float(value)

func apply_modifier(modifier: Dictionary) -> void:
	var mod_id: String = modifier.get("id", "")
	match mod_id:
		"ironclad":
			guard_efficiency = min(0.95, guard_efficiency + modifier.get("value", 0.0))
		"swift":
			light_stamina_cost_multiplier *= (1.0 + modifier.get("value", 0.0))
		"bloodlust":
			pass  # Checked at runtime in get_effective_attack_damage()
		"burden":
			max_stamina = max(10, max_stamina + int(modifier.get("value_a", 0)))
			stamina = min(stamina, float(max_stamina))
			stamina_changed.emit(stamina, max_stamina)
			GameState.xp_gain_multiplier *= (1.0 + modifier.get("value_b", 0.0))
		"last_rites":
			_last_rites_available = true
		"scavenger_instinct":
			pass  # Handled at reward calculation in main.gd
		"lone_hunter":
			GameState.loot_per_encounter_modifier += int(modifier.get("value_a", 0))
			max_health = max(1, max_health + int(modifier.get("value_b", 0)))
			current_health = min(current_health, max_health)
			health_changed.emit(current_health, max_health)
		"relentless":
			stamina_regen_per_sec += float(modifier.get("value_a", 0.0))
			guard_efficiency = clampf(guard_efficiency + float(modifier.get("value_b", 0.0)), 0.0, 0.95)
		"death_wish":
			pass  # Checked at runtime in get_effective_attack_damage()

func reset_for_run() -> void:
	# Restore base combat stats from data before upgrades/modifiers are applied.
	# Called at run start to prevent stats accumulating across reused player node.
	var combat_data: Dictionary = DataStore.weapons.get("global_combat", {})
	max_health = combat_data.get("max_health", 100)
	current_health = max_health
	max_poise = combat_data.get("max_poise", 100)
	current_poise = max_poise
	max_stamina = 100  # @export default -- upgrades will add to this after reset
	stamina = float(max_stamina)
	is_staggered = false
	is_invulnerable = false
	_conditional_bonuses = {}
	light_stamina_cost_multiplier = 1.0
	_last_rites_available = false
	poise_damage_bonus = 0
	guard_damage_reduction = 0.0
	light_attack_bonus = 0
	stamina_on_kill = 0.0
	reload_weapon_stats()  # reset guard_efficiency, heavy_damage, heavy_stamina_cost
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	poise_changed.emit(current_poise, max_poise)

func reload_weapon_stats() -> void:
	var weapons_list: Array = DataStore.weapons.get("weapons", [])
	for w in weapons_list:
		if w.get("id") == GameState.selected_weapon_id:
			guard_efficiency = float(w.get("guard_efficiency", 0.70))
			heavy_damage = w.get("heavy_damage", 24)
			heavy_stamina_cost = float(w.get("heavy_stamina_cost", 18.0))
			break

func _recalculate_conditional_bonuses() -> void:
	_conditional_bonuses = {}
	if max_health <= 0:
		return
	var health_pct: float = float(current_health) / float(max_health)
	for upgrade in GameState.active_upgrades:
		if upgrade.get("modifier_type", "") == "conditional_health_pct":
			var threshold: float = float(upgrade.get("threshold", 1.0))
			if health_pct < threshold:
				var stat: String = upgrade.get("stat", "")
				if stat.is_empty():
					continue
				var val: float = float(upgrade.get("value", 0))
				_conditional_bonuses[stat] = _conditional_bonuses.get(stat, 0.0) + val

func get_effective_attack_damage() -> int:
	var base: int = heavy_damage + int(_conditional_bonuses.get("attack_damage", 0))
	if max_health > 0:
		var hp_pct: float = float(current_health) / float(max_health)
		for m in GameState.active_modifiers:
			if m.get("modifier_type", "") == "conditional_damage_pct":
				if hp_pct < float(m.get("threshold", 1.0)):
					base = int(float(base) * (1.0 + float(m.get("value", 0.0))))
	return base

func get_effective_guard_efficiency() -> float:
	return min(guard_efficiency + float(_conditional_bonuses.get("guard_efficiency", 0.0)), 0.95)

func heavy_attack() -> bool:
	if is_staggered:
		return false
	if stamina < heavy_stamina_cost:
		return false
	stamina -= heavy_stamina_cost
	stamina_changed.emit(stamina, max_stamina)
	heavy_attack_triggered.emit(get_effective_attack_damage())
	return true

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		try_attack()
	if Input.is_action_just_pressed("ui_select"):
		try_dodge()

	var next_guarding := Input.is_action_pressed("guard")
	if next_guarding != guarding:
		set_guarding(next_guarding)

	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
	regenerate_stamina(delta)

func try_attack() -> bool:
	if is_staggered:
		return false
	var effective_attack_cost: int = max(1, int(attack_cost * light_stamina_cost_multiplier))
	if stamina < effective_attack_cost:
		return false
	stamina -= effective_attack_cost
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
			effective_damage = int(amount * (1.0 - get_effective_guard_efficiency()))
	current_health = max(0, current_health - effective_damage)
	_recalculate_conditional_bonuses()
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		if _last_rites_available:
			current_health = 1
			_last_rites_available = false
			health_changed.emit(current_health, max_health)
			return
		player_died.emit()

func take_poise_damage(amount: int) -> void:
	if is_invulnerable:
		return
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
	_recalculate_conditional_bonuses()
