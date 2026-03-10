extends Node
class_name GameState

const Telemetry = preload("res://scripts/systems/telemetry.gd")

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
var telemetry := Telemetry.new()

func default_save_state() -> Dictionary:
	return {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
	}

func to_save_state() -> Dictionary:
	return {
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
		"unbanked_xp": unbanked_xp,
		"unbanked_loot": unbanked_loot,
		"current_ring": current_ring,
	}

func apply_save_state(data: Dictionary) -> void:
	banked_xp = int(data.get("banked_xp", 0))
	banked_loot = int(data.get("banked_loot", 0))
	unbanked_xp = int(data.get("unbanked_xp", 0))
	unbanked_loot = int(data.get("unbanked_loot", 0))
	current_ring = str(data.get("current_ring", "sanctuary"))

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	telemetry.log_event("run_started", {
		"seed": active_seed,
		"ring": current_ring,
	})
	run_started.emit(seed)

func add_unbanked(xp_value: int, loot_value: int) -> void:
	unbanked_xp += xp_value
	unbanked_loot += loot_value
	telemetry.log_event("encounter_completed", {
		"seed": active_seed,
		"ring": current_ring,
		"xp_gain": xp_value,
		"loot_gain": loot_value,
	})
	encounter_completed.emit(xp_value, loot_value)

func extract() -> void:
	var event_ring := current_ring
	banked_xp += unbanked_xp
	banked_loot += unbanked_loot
	unbanked_xp = 0
	unbanked_loot = 0
	current_ring = "sanctuary"
	telemetry.log_event("extracted", {
		"seed": active_seed,
		"ring": event_ring,
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
	})
	extracted.emit(banked_xp, banked_loot)

func die_in_run() -> void:
	var event_ring := current_ring
	unbanked_xp = int(unbanked_xp * 0.5)
	unbanked_loot = 0
	current_ring = "sanctuary"
	telemetry.log_event("player_died", {
		"seed": active_seed,
		"ring": event_ring,
		"remaining_unbanked_xp": unbanked_xp,
	})
	player_died.emit()

func set_telemetry_enabled(enabled: bool) -> void:
	telemetry.enabled = enabled
