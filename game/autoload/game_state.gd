extends Node
class_name GameState

signal run_started(seed: int)
signal encounter_completed(reward_xp: int, reward_loot: int)
signal extracted(total_xp: int, total_loot: int)
signal player_died()

var current_ring: String = "sanctuary"
var active_seed: int = 0
var banked_xp: int = 0
var banked_loot: int = 0
var unbanked_xp: int = 0
var unbanked_loot: int = 0

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	run_started.emit(seed)

func add_unbanked(xp_value: int, loot_value: int) -> void:
	unbanked_xp += xp_value
	unbanked_loot += loot_value
	encounter_completed.emit(xp_value, loot_value)

func extract() -> void:
	banked_xp += unbanked_xp
	banked_loot += unbanked_loot
	unbanked_xp = 0
	unbanked_loot = 0
	current_ring = "sanctuary"
	extracted.emit(banked_xp, banked_loot)

func die_in_run() -> void:
	unbanked_xp = int(unbanked_xp * 0.5)
	unbanked_loot = 0
	current_ring = "sanctuary"
	player_died.emit()
