extends Node
# class_name omitted — autoload singleton accessed via "GameState" globally

const Telemetry = preload("res://scripts/systems/telemetry.gd")

signal run_started(seed: int)
signal encounter_completed(reward_xp: int, reward_loot: int)
signal extracted(total_xp: int, total_loot: int)
signal player_died()
signal vendor_upgrade_purchased(upgrade_id: String)

var current_ring: String = "sanctuary"
var active_seed: int = 0
var banked_xp: int = 0
var banked_loot: int = 0
var unbanked_xp: int = 0
var unbanked_loot: int = 0
var telemetry := Telemetry.new()

# Permanent progression — persists across runs
# extractions_by_ring: { "inner": 2, "mid": 0, ... }
var extractions_by_ring: Dictionary = {}
# vendor_upgrades: { "iron_will": 0, "swift_feet": 1, ... } (purchase counts)
var vendor_upgrades: Dictionary = {}

# Run history — last 20 entries
var run_history: Array = []

const MAX_HISTORY := 20

# ── Per-run tracking (cleared on start_run) ───────────────────────────────────
var run_encounters_cleared: int = 0
var run_total_xp: int = 0
var run_total_loot: int = 0
var run_active_modifiers: Array = []
var run_last_enemy_killer: String = ""

func default_save_state() -> Dictionary:
	return {
		"banked_xp": 0,
		"banked_loot": 0,
		"unbanked_xp": 0,
		"unbanked_loot": 0,
		"current_ring": "sanctuary",
		"extractions_by_ring": {},
		"vendor_upgrades": {},
		"run_history": [],
	}

func to_save_state() -> Dictionary:
	return {
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
		"unbanked_xp": unbanked_xp,
		"unbanked_loot": unbanked_loot,
		"current_ring": current_ring,
		"extractions_by_ring": extractions_by_ring.duplicate(true),
		"vendor_upgrades": vendor_upgrades.duplicate(true),
		"run_history": run_history.duplicate(true),
	}

func apply_save_state(data: Dictionary) -> void:
	banked_xp = int(data.get("banked_xp", 0))
	banked_loot = int(data.get("banked_loot", 0))
	unbanked_xp = int(data.get("unbanked_xp", 0))
	unbanked_loot = int(data.get("unbanked_loot", 0))
	current_ring = str(data.get("current_ring", "sanctuary"))
	var ebr: Variant = data.get("extractions_by_ring", {})
	extractions_by_ring = ebr if typeof(ebr) == TYPE_DICTIONARY else {}
	var vu: Variant = data.get("vendor_upgrades", {})
	vendor_upgrades = vu if typeof(vu) == TYPE_DICTIONARY else {}
	var rh: Variant = data.get("run_history", [])
	run_history = rh if typeof(rh) == TYPE_ARRAY else []

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	run_encounters_cleared = 0
	run_total_xp = 0
	run_total_loot = 0
	run_last_enemy_killer = ""
	telemetry.log_event("run_started", {
		"seed": active_seed,
		"ring": current_ring,
	})
	run_started.emit(seed)

func add_unbanked(xp_value: int, loot_value: int) -> void:
	unbanked_xp += xp_value
	unbanked_loot += loot_value
	run_encounters_cleared += 1
	run_total_xp += xp_value
	run_total_loot += loot_value
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

	# Track extraction per ring
	var prev_count: int = int(extractions_by_ring.get(event_ring, 0))
	extractions_by_ring[event_ring] = prev_count + 1

	# Record run history entry
	_add_history_entry(event_ring, true)

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

	# Record run history entry (failed)
	_add_history_entry(event_ring, false)

	current_ring = "sanctuary"
	telemetry.log_event("player_died", {
		"seed": active_seed,
		"ring": event_ring,
		"remaining_unbanked_xp": unbanked_xp,
	})
	player_died.emit()

func has_extracted_from(ring_id: String) -> bool:
	return int(extractions_by_ring.get(ring_id, 0)) > 0

func get_extractions_from(ring_id: String) -> int:
	return int(extractions_by_ring.get(ring_id, 0))

func is_ring_unlocked(ring_id: String, rings_data: Dictionary) -> bool:
	var rings: Array = rings_data.get("rings", [])
	for ring in rings:
		if str(ring.get("id", "")) == ring_id:
			var condition := str(ring.get("unlock_condition", ""))
			if condition == "":
				return true
			if condition == "extracted_inner_once":
				return has_extracted_from("inner")
			# Generic: "extracted_<ring>_once"
			if condition.begins_with("extracted_") and condition.ends_with("_once"):
				var req_ring := condition.substr(10, condition.length() - 15)
				return has_extracted_from(req_ring)
			return false
	# Ring not found
	return false

# ── Vendor ────────────────────────────────────────────────────────────────────

func get_upgrade_level(upgrade_id: String) -> int:
	return int(vendor_upgrades.get(upgrade_id, 0))

func purchase_upgrade(upgrade_id: String, cost: int) -> bool:
	if banked_loot < cost:
		return false
	banked_loot -= cost
	vendor_upgrades[upgrade_id] = int(vendor_upgrades.get(upgrade_id, 0)) + 1
	telemetry.log_event("vendor_purchase", {
		"upgrade_id": upgrade_id,
		"cost": cost,
		"banked_loot_remaining": banked_loot,
	})
	vendor_upgrade_purchased.emit(upgrade_id)
	return true

func set_telemetry_enabled(enabled: bool) -> void:
	telemetry.enabled = enabled

# ── Run Modifiers ─────────────────────────────────────────────────────────────

func set_active_modifiers(modifier_list: Array) -> void:
	run_active_modifiers = modifier_list.duplicate(true)

func get_active_modifiers() -> Array:
	return run_active_modifiers.duplicate(true)

func has_modifier(modifier_id: String) -> bool:
	for mod in run_active_modifiers:
		if str(mod.get("id", "")) == modifier_id:
			return true
	return false

# ── Victory / Death Stats ─────────────────────────────────────────────────────

func get_run_stats() -> Dictionary:
	return {
		"ring": current_ring,
		"seed": active_seed,
		"encounters_cleared": run_encounters_cleared,
		"total_xp": run_total_xp,
		"total_loot": run_total_loot,
		"active_modifiers": run_active_modifiers.duplicate(true),
		"vendor_upgrades": _get_active_upgrade_names(),
	}

func _get_active_upgrade_names() -> Array:
	var result: Array = []
	for upg_id in vendor_upgrades:
		if int(vendor_upgrades[upg_id]) > 0:
			result.append(str(upg_id))
	return result

func set_killer_enemy(enemy_id: String) -> void:
	run_last_enemy_killer = enemy_id

# ── Run History ───────────────────────────────────────────────────────────────

func _add_history_entry(ring_id: String, extracted_ok: bool) -> void:
	var entry := {
		"ring": ring_id,
		"seed": active_seed,
		"unbanked_xp": unbanked_xp,
		"unbanked_loot": unbanked_loot,
		"extracted": extracted_ok,
		"timestamp": Time.get_unix_time_from_system(),
	}
	run_history.append(entry)
	if run_history.size() > MAX_HISTORY:
		run_history = run_history.slice(run_history.size() - MAX_HISTORY)

func get_run_history() -> Array:
	return run_history.duplicate(true)
