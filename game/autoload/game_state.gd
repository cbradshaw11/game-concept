extends Node
class_name GameState

const Telemetry = preload("res://scripts/systems/telemetry.gd")

signal run_started(seed: int)
signal encounter_completed(reward_xp: int, reward_loot: int)
signal extracted(total_xp: int, total_loot: int)
signal player_died()

var current_ring: String = "sanctuary"
var active_seed: int = 0
var selected_weapon_id: String = "blade_iron"
var banked_xp: int = 0
var banked_loot: int = 0
var unbanked_xp: int = 0
var unbanked_loot: int = 0
var encounters_cleared: int = 0
var rings_cleared: Array[String] = []
var warden_defeated: bool = false
var game_completed: bool = false
var warden_phase_reached: int = -1
var active_upgrades: Array = []
var telemetry := Telemetry.new()

func default_save_state() -> Dictionary:
	return {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"rings_cleared": [],
		"warden_defeated": false,
		"game_completed": false,
	}

func to_save_state() -> Dictionary:
	return {
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
		"unbanked_xp": unbanked_xp,
		"unbanked_loot": unbanked_loot,
		"current_ring": current_ring,
		"rings_cleared": rings_cleared,
		"warden_defeated": warden_defeated,
		"game_completed": game_completed,
		"warden_phase_reached": warden_phase_reached,
		"save_version": 1,
	}

func apply_save_state(data: Dictionary) -> void:
	# M5 migration guard — must run BEFORE normal key assignments
	if data.get("save_version", 0) < 1:
		warden_phase_reached = -1
	banked_xp = int(data.get("banked_xp", 0))
	banked_loot = int(data.get("banked_loot", 0))
	unbanked_xp = int(data.get("unbanked_xp", 0))
	unbanked_loot = int(data.get("unbanked_loot", 0))
	current_ring = str(data.get("current_ring", "sanctuary"))
	rings_cleared = Array(data.get("rings_cleared", []), TYPE_STRING, "", null)
	warden_defeated = bool(data.get("warden_defeated", false))
	game_completed = bool(data.get("game_completed", false))
	warden_phase_reached = int(data.get("warden_phase_reached", -1))

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	encounters_cleared = 0
	active_upgrades = []
	telemetry.log_event("run_started", {
		"seed": active_seed,
		"ring": current_ring,
	})
	run_started.emit(seed)

func add_unbanked(xp_value: int, loot_value: int) -> void:
	unbanked_xp += xp_value
	unbanked_loot += loot_value
	encounters_cleared += 1
	telemetry.log_event("encounter_completed", {
		"seed": active_seed,
		"ring": current_ring,
		"xp_gain": xp_value,
		"loot_gain": loot_value,
	})
	encounter_completed.emit(xp_value, loot_value)

func extract() -> void:
	var event_ring := current_ring
	if current_ring != "sanctuary" and current_ring not in rings_cleared:
		rings_cleared.append(current_ring)
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
	var retained: int = int(unbanked_loot * 0.25)
	banked_loot += retained
	unbanked_xp = int(unbanked_xp * 0.5)
	unbanked_loot = 0
	encounters_cleared = 0
	current_ring = "sanctuary"
	telemetry.log_event("player_died", {
		"seed": active_seed,
		"ring": event_ring,
		"remaining_unbanked_xp": unbanked_xp,
	})
	player_died.emit()

func apply_upgrade(upgrade: Dictionary) -> void:
	active_upgrades.append(upgrade)

func set_telemetry_enabled(enabled: bool) -> void:
	telemetry.enabled = enabled
