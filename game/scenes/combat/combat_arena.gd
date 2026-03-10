extends Node2D
class_name CombatArena

signal attack_hook_triggered
signal dodge_hook_triggered
signal guard_hook_changed(is_guarding: bool)

@onready var player: PlayerController = $Player
@onready var combat_status: Label = $HUD/CombatStatus

var ring_id: String = "inner"
var seed: int = 0
var attack_count: int = 0
var dodge_count: int = 0
var guard_active: bool = false

func _ready() -> void:
	player.attack_triggered.connect(_on_attack_triggered)
	player.dodge_triggered.connect(_on_dodge_triggered)
	player.guard_changed.connect(_on_guard_changed)
	_update_status()

func set_context(next_ring_id: String, next_seed: int) -> void:
	ring_id = next_ring_id
	seed = next_seed
	attack_count = 0
	dodge_count = 0
	guard_active = false
	player.set_guarding(false)
	_update_status()

func set_arena_active(is_active: bool) -> void:
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _on_attack_triggered() -> void:
	attack_count += 1
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
	combat_status.text = "Ring %s Seed %d | Atk %d Dodge %d Guard %s | Stamina %d/%d" % [
		ring_id,
		seed,
		attack_count,
		dodge_count,
		"On" if guard_active else "Off",
		int(round(player.stamina)),
		player.max_stamina,
	]
