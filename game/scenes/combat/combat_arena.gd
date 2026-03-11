extends Node2D
class_name CombatArena

const EnemyController = preload("res://scripts/core/enemy_controller.gd")

signal attack_hook_triggered
signal dodge_hook_triggered
signal guard_hook_changed(is_guarding: bool)
signal encounter_cleared(enemy_count: int)
signal player_died()

@onready var player: PlayerController = $Player
@onready var combat_status: Label = $HUD/CombatStatus
@onready var hp_bar: ProgressBar = $HUD/Bars/HPBar
@onready var stamina_bar: ProgressBar = $HUD/Bars/StaminaBar
@onready var poise_bar: ProgressBar = $HUD/Bars/PoiseBar

var ring_id: String = "inner"
var seed: int = 0
var attack_count: int = 0
var dodge_count: int = 0
var guard_active: bool = false
var enemies: Array[EnemyController] = []
var encounter_enemy_count: int = 0
var encounter_completed: bool = false
var weapon_data: Dictionary = {}

func _ready() -> void:
	player.attack_triggered.connect(_on_attack_triggered)
	player.dodge_triggered.connect(_on_dodge_triggered)
	player.guard_changed.connect(_on_guard_changed)
	player.player_died.connect(func() -> void: player_died.emit())
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	if player.has_signal("poise_changed"):
		player.poise_changed.connect(_on_poise_changed)
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina
	poise_bar.max_value = player.max_poise
	poise_bar.value = player.current_poise
	_load_weapon_data()
	_update_status()

func _load_weapon_data() -> void:
	var all_weapons: Array = DataStore.weapons.get("weapons", [])
	for w in all_weapons:
		if w.get("id") == GameState.selected_weapon_id:
			weapon_data = w
			return
	weapon_data = {"light_damage": 14}

func set_context(next_ring_id: String, next_seed: int, enemy_count: int = 1) -> void:
	ring_id = next_ring_id
	seed = next_seed
	attack_count = 0
	dodge_count = 0
	guard_active = false
	encounter_enemy_count = max(1, enemy_count)
	encounter_completed = false
	_load_weapon_data()
	_spawn_enemies(encounter_enemy_count)
	player.set_guarding(false)
	_update_status()

func set_arena_active(is_active: bool) -> void:
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if enemies.is_empty() or encounter_completed:
		return
	var player_zone := _player_zone()
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		var distance_to_player := absf(float(index - player_zone)) + 0.5
		enemy.tick(distance_to_player, delta)
	if _all_enemies_defeated():
		encounter_completed = true
		encounter_cleared.emit(encounter_enemy_count)
	_update_status()

func _on_attack_triggered() -> void:
	attack_count += 1
	_apply_damage_to_front_enemy(weapon_data.get("light_damage", 14))
	attack_hook_triggered.emit()
	_update_status()

func _on_dodge_triggered() -> void:
	dodge_count += 1
	dodge_hook_triggered.emit()
	_update_status()

func _on_guard_changed(is_guarding: bool) -> void:
	guard_active = is_guarding
	guard_hook_changed.emit(is_guarding)
	_update_status()

func _update_status() -> void:
	var state_parts: PackedStringArray = []
	for index in enemies.size():
		var enemy := enemies[index]
		state_parts.append("E%d:%s(%d)" % [index + 1, EnemyController.state_name(enemy.state), enemy.health])
	var enemies_text := " | ".join(state_parts)
	combat_status.text = "Ring %s Seed %d | Atk %d Dodge %d Guard %s | Stamina %d/%d | %s" % [
		ring_id,
		seed,
		attack_count,
		dodge_count,
		"On" if guard_active else "Off",
		int(round(player.stamina)),
		player.max_stamina,
		enemies_text,
	]

func _spawn_enemies(count: int) -> void:
	enemies.clear()
	var all_enemies: Array = DataStore.enemies.get("enemies", [])
	var enemy_pool: Array = all_enemies.filter(func(e: Dictionary) -> bool:
		return e.get("rings", []).has(ring_id)
	)
	if enemy_pool.is_empty():
		enemy_pool = all_enemies
	for i in range(count):
		var enemy_data: Dictionary = enemy_pool[i % enemy_pool.size()]
		var enemy := EnemyController.new(
			enemy_data.get("health", 60),
			3.5,
			1.2,
			enemy_data.get("damage", 10)
		)
		var poise_dmg: int = enemy_data.get("poise_damage", 0)
		enemy.attack_resolved.connect(func(amount: int) -> void:
			_apply_damage_to_player(amount, poise_dmg)
		)
		enemies.append(enemy)

func _player_zone() -> int:
	var zone := int(round(player.position.x / 160.0))
	return clampi(zone, 0, max(0, enemies.size() - 1))

func _apply_damage_to_front_enemy(damage: int) -> void:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			enemy.apply_damage(damage, true)
			return

func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			return false
	return true

func _apply_damage_to_player(amount: int, poise_damage: int = 0) -> void:
	if player:
		player.take_damage(amount)
		if poise_damage > 0:
			player.take_poise_damage(poise_damage)

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	if float(current) / float(maximum) < 0.25:
		hp_bar.modulate = Color(0.5, 0.0, 0.0)
	else:
		hp_bar.modulate = Color(1.0, 0.2, 0.2)

func _on_stamina_changed(current: float, maximum: int) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func _on_poise_changed(current: int, maximum: int) -> void:
	poise_bar.max_value = maximum
	poise_bar.value = current
