extends Node
class_name GameState

const Telemetry = preload("res://scripts/systems/telemetry.gd")
const _SaveSystem = preload("res://scripts/systems/save_system.gd")

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
var pending_run_upgrades: Array = []
var permanent_upgrades: Array = []
var prologue_seen: bool = false
var first_run_complete: bool = false
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
		"warden_phase_reached": -1,
		"prologue_seen": false,
		"first_run_complete": false,
		"permanent_upgrades": [],
		"selected_weapon_id": "blade_iron",
		"save_version": 3,
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
		"prologue_seen": prologue_seen,
		"first_run_complete": first_run_complete,
		"permanent_upgrades": permanent_upgrades,
		"selected_weapon_id": selected_weapon_id,
		"save_version": 3,
	}

func apply_save_state(data: Dictionary) -> void:
	banked_xp = int(data.get("banked_xp", 0))
	banked_loot = int(data.get("banked_loot", 0))
	unbanked_xp = int(data.get("unbanked_xp", 0))
	unbanked_loot = int(data.get("unbanked_loot", 0))
	current_ring = str(data.get("current_ring", "sanctuary"))
	rings_cleared = Array(data.get("rings_cleared", []), TYPE_STRING, "", null)
	warden_defeated = bool(data.get("warden_defeated", false))
	game_completed = bool(data.get("game_completed", false))
	# M5 migration guard: only restore warden_phase_reached from save if save_version >= 1
	if data.get("save_version", 0) >= 1:
		warden_phase_reached = int(data.get("warden_phase_reached", -1))
	else:
		warden_phase_reached = -1
	# M6 migration guard: only restore prologue/first_run fields if save_version >= 2
	if data.get("save_version", 0) >= 2:
		prologue_seen = bool(data.get("prologue_seen", false))
		first_run_complete = bool(data.get("first_run_complete", false))
	else:
		prologue_seen = false
		first_run_complete = false
	# TASK-604 migration guard: only restore permanent_upgrades if save_version >= 3
	if data.get("save_version", 0) >= 3:
		var raw = data.get("permanent_upgrades", [])
		permanent_upgrades = raw.filter(func(e): return e is Dictionary)
	else:
		permanent_upgrades = []
	selected_weapon_id = str(data.get("selected_weapon_id", "blade_iron"))

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	encounters_cleared = 0
	# Carry pending per_run shop purchases into the new run, then clear the queue
	active_upgrades = pending_run_upgrades.duplicate()
	pending_run_upgrades = []
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

func get_loot_per_encounter_bonus() -> int:
	var bonus: int = 0
	for upgrade in active_upgrades:
		if upgrade.get("stat", "") == "loot_per_encounter":
			bonus += int(upgrade.get("value", 0))
	return bonus

func apply_upgrade(upgrade: Dictionary) -> void:
	active_upgrades.append(upgrade)

func apply_shop_item(item: Dictionary) -> void:
	var item_type: String = str(item.get("type", "per_run"))
	var stat: String = str(item.get("stat", ""))

	if item_type == "permanent":
		permanent_upgrades.append(item)
		telemetry.log_event("shop_item_purchased", {
			"item_id": item.get("id", ""),
			"type": "permanent",
			"stat": stat,
		})
	else:
		# per_run: store in pending_run_upgrades so they survive start_run() clearing active_upgrades
		pending_run_upgrades.append(item)
		telemetry.log_event("shop_item_purchased", {
			"item_id": item.get("id", ""),
			"type": "per_run",
			"stat": stat,
		})

func set_telemetry_enabled(enabled: bool) -> void:
	telemetry.enabled = enabled

func reset_for_new_game() -> void:
	var defaults := default_save_state()
	apply_save_state(defaults)
	active_upgrades = []
	pending_run_upgrades = []
	permanent_upgrades = []
	active_seed = 0
	encounters_cleared = 0
	selected_weapon_id = "blade_iron"
	prologue_seen = true  # preserve: prologue is a one-time player experience, not run state
	# Delete the save file so no stale state persists
	if FileAccess.file_exists(_SaveSystem.SAVE_PATH):
		DirAccess.remove_absolute(_SaveSystem.SAVE_PATH)
