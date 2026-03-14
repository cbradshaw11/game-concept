extends Node
class_name GameState

const Telemetry = preload("res://scripts/systems/telemetry.gd")
const _SaveSystem = preload("res://scripts/systems/save_system.gd")

signal run_started(seed: int)
signal encounter_completed(reward_xp: int, reward_loot: int)
signal extracted(total_xp: int, total_loot: int, ring_id: String)
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
var xp_gain_multiplier: float = 1.0
var warden_map_unlocked: bool = false
var run_history: Array = []
var weapons_unlocked: Array = ["blade_iron"]
var _run_outcome_recorded: bool = false
var telemetry := Telemetry.new()
var active_modifiers: Array = []
var pending_modifier: Dictionary = {}

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
		"run_history": [],
		"weapons_unlocked": ["blade_iron"],
		"xp_gain_multiplier": 1.0,
		"warden_map_unlocked": false,
		"active_modifiers": [],
		"save_version": 5,
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
		"run_history": run_history,
		"weapons_unlocked": weapons_unlocked,
		"xp_gain_multiplier": xp_gain_multiplier,
		"warden_map_unlocked": warden_map_unlocked,
		"active_modifiers": active_modifiers,
		"save_version": 5,
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
	# TASK-701 migration guard: only restore run_history/weapons_unlocked if save_version >= 4
	if data.get("save_version", 0) >= 4:
		run_history = Array(data.get("run_history", []))
		weapons_unlocked = Array(data.get("weapons_unlocked", ["blade_iron"]), TYPE_STRING, "", null)
	else:
		run_history = []
		weapons_unlocked = ["blade_iron"]
	# xp_gain_multiplier and warden_map_unlocked: always read with defaults (present in v4+)
	xp_gain_multiplier = float(data.get("xp_gain_multiplier", 1.0))
	warden_map_unlocked = bool(data.get("warden_map_unlocked", false))
	# TASK-802 migration guard: only restore active_modifiers if save_version >= 5
	if data.get("save_version", 0) >= 5:
		active_modifiers = Array(data.get("active_modifiers", [])).filter(func(e): return e is Dictionary)
	else:
		active_modifiers = []

func start_run(seed: int, ring_id: String) -> void:
	active_modifiers = []
	xp_gain_multiplier = 1.0
	if not pending_modifier.is_empty():
		active_modifiers = [pending_modifier]
		pending_modifier = {}
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	encounters_cleared = 0
	_run_outcome_recorded = false
	# Carry pending per_run shop purchases into the new run, then clear the queue
	active_upgrades = pending_run_upgrades.duplicate()
	pending_run_upgrades = []
	telemetry.log_event("run_started", {
		"seed": active_seed,
		"ring": current_ring,
	})
	run_started.emit(seed)

func add_unbanked(xp_value: int, loot_value: int) -> void:
	unbanked_xp += int(xp_value * xp_gain_multiplier)
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
	# Append run record BEFORE clearing unbanked values so fields are still valid
	# Guard: skip if warden_defeated already recorded an outcome for this run
	if not _run_outcome_recorded:
		_run_outcome_recorded = true
		var record := {
			"ring_reached": current_ring,
			"encounters_cleared": encounters_cleared,
			"outcome": "extracted",
			"loot_banked": banked_loot,
			"xp_banked": banked_xp,
			"seed": active_seed,
			"upgrades": active_upgrades.map(func(u): return u.get("id", "")),
			"modifiers": active_modifiers.map(func(m): return m.get("id", "")),
			"run_number": run_history.size() + 1,
		}
		run_history.append(record)
		if run_history.size() > 20:
			run_history = run_history.slice(-20)
	unbanked_xp = 0
	unbanked_loot = 0
	current_ring = "sanctuary"
	telemetry.log_event("extracted", {
		"seed": active_seed,
		"ring": event_ring,
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
	})
	extracted.emit(banked_xp, banked_loot, event_ring)

func die_in_run() -> void:
	var event_ring := current_ring
	var retained: int = int(unbanked_loot * 0.25)
	banked_loot += retained
	# Append run record BEFORE zeroing run state so ring_reached/encounters_cleared are valid
	if not _run_outcome_recorded:
		_run_outcome_recorded = true
		var record := {
			"ring_reached": current_ring,
			"encounters_cleared": encounters_cleared,
			"outcome": "died",
			"loot_banked": banked_loot,
			"xp_banked": banked_xp,
			"seed": active_seed,
			"upgrades": active_upgrades.map(func(u): return u.get("id", "")),
			"modifiers": active_modifiers.map(func(m): return m.get("id", "")),
			"run_number": run_history.size() + 1,
		}
		run_history.append(record)
		if run_history.size() > 20:
			run_history = run_history.slice(-20)
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

func abandon_run() -> void:
	# Silently reset run state without recording a history entry or applying retention math.
	# Use this for quit-to-menu, not for actual deaths.
	unbanked_xp = 0
	unbanked_loot = 0
	encounters_cleared = 0
	current_ring = "sanctuary"
	active_upgrades = []
	active_modifiers = []
	pending_modifier = {}
	_run_outcome_recorded = false

func record_warden_defeated() -> void:
	if _run_outcome_recorded:
		return
	_run_outcome_recorded = true
	var record := {
		"ring_reached": current_ring,
		"encounters_cleared": encounters_cleared,
		"outcome": "warden_defeated",
		"loot_banked": banked_loot,
		"xp_banked": banked_xp,
		"seed": active_seed,
		"upgrades": active_upgrades.map(func(u): return u.get("id", "")),
		"modifiers": active_modifiers.map(func(m): return m.get("id", "")),
		"run_number": run_history.size() + 1,
	}
	run_history.append(record)
	if run_history.size() > 20:
		run_history = run_history.slice(-20)

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

func unlock_weapon(weapon_id: String) -> bool:
	if weapon_id in weapons_unlocked:
		return false  # already unlocked
	weapons_unlocked.append(weapon_id)
	return true

func can_afford_weapon_unlock(cost_xp: int) -> bool:
	return banked_xp >= cost_xp

func spend_xp(amount: int) -> void:
	banked_xp = max(0, banked_xp - amount)

func reset_for_new_game() -> void:
	var defaults := default_save_state()
	apply_save_state(defaults)
	active_upgrades = []
	pending_run_upgrades = []
	permanent_upgrades = []
	active_modifiers = []
	pending_modifier = {}
	active_seed = 0
	encounters_cleared = 0
	selected_weapon_id = "blade_iron"
	xp_gain_multiplier = 1.0
	warden_map_unlocked = false
	run_history = []
	weapons_unlocked = ["blade_iron"]
	prologue_seen = true  # preserve: prologue is a one-time player experience, not run state
	# Delete the save file so no stale state persists
	if FileAccess.file_exists(_SaveSystem.SAVE_PATH):
		DirAccess.remove_absolute(_SaveSystem.SAVE_PATH)
