extends Node
# class_name omitted — autoload singleton accessed via "GameState" globally

const Telemetry = preload("res://scripts/systems/telemetry.gd")

signal run_started(seed: int)
signal encounter_completed(reward_xp: int, reward_loot: int)
signal extracted(total_xp: int, total_loot: int)
signal player_died()
signal vendor_upgrade_purchased(upgrade_id: String)
signal artifact_retrieved_signal
signal fragment_collected(fragment_id: String)

var current_ring: String = "sanctuary"
var artifact_retrieved: bool = false
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

# ── M21 — Persistent lifetime stats ──────────────────────────────────────────
var total_runs: int = 0
var total_extractions: int = 0
var total_deaths: int = 0
var deepest_ring_reached: String = ""
var artifact_retrievals: int = 0
var fastest_extraction_seconds: float = 0.0  # 0 = no record yet

# ── M23 — Collected lore fragments ──────────────────────────────────────────
var collected_fragments: Array = []  # Array of fragment id strings
var current_run_fragments: Array = []  # Fragments found this run (reset on start_run)

# ── M32 — Achievement lifetime stats ──────────────────────────────────────────
var unlocked_achievements: Array = []  # Array of achievement id strings
var lifetime_kills: int = 0
var lifetime_poise_breaks: int = 0
var completed_challenges: Array = []  # Array of challenge id strings completed

# ── M27 — Resonance Shards meta-progression ───────────────────────────────
var resonance_shards: int = 0         # Lifetime total accumulated
var resonance_spent: int = 0          # Lifetime total spent
var permanent_unlocks: Array = []     # List of unlock id strings currently active
var last_run_shards_earned: int = 0   # Shards earned in the most recent run (for display)

# ── Per-run tracking (cleared on start_run) ───────────────────────────────────
var run_encounters_cleared: int = 0
var run_total_xp: int = 0
var run_total_loot: int = 0
var run_active_modifiers: Array = []
var run_last_enemy_killer: String = ""
var encounter_damage_taken: int = 0  # M32 — Reset per encounter for no-damage achievement

# M21 — Detailed per-run stats dictionary (reset on start_run)
var current_run_stats: Dictionary = {}
var _run_start_time: float = 0.0

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
		"artifact_retrieved": false,
		# v8 — M21 lifetime stats
		"total_runs": 0,
		"total_extractions": 0,
		"total_deaths": 0,
		"deepest_ring_reached": "",
		"artifact_retrievals": 0,
		"fastest_extraction_seconds": 0.0,
		# v9 — M23 collected lore fragments
		"collected_fragments": [],
		# v10 — M27 resonance shards
		"resonance_shards": 0,
		"resonance_spent": 0,
		"permanent_unlocks": [],
		# v11 — M32 achievements
		"unlocked_achievements": [],
		"lifetime_kills": 0,
		"lifetime_poise_breaks": 0,
		"completed_challenges": [],
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
		"artifact_retrieved": artifact_retrieved,
		# v8 — M21 lifetime stats
		"total_runs": total_runs,
		"total_extractions": total_extractions,
		"total_deaths": total_deaths,
		"deepest_ring_reached": deepest_ring_reached,
		"artifact_retrievals": artifact_retrievals,
		"fastest_extraction_seconds": fastest_extraction_seconds,
		# v9 — M23 collected lore fragments
		"collected_fragments": collected_fragments.duplicate(),
		# v10 — M27 resonance shards
		"resonance_shards": resonance_shards,
		"resonance_spent": resonance_spent,
		"permanent_unlocks": permanent_unlocks.duplicate(),
		# v11 — M32 achievements
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"lifetime_kills": lifetime_kills,
		"lifetime_poise_breaks": lifetime_poise_breaks,
		"completed_challenges": completed_challenges.duplicate(),
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
	# v7 migration guard — artifact_retrieved
	artifact_retrieved = bool(data.get("artifact_retrieved", false))
	# v8 migration guard — M21 lifetime stats
	total_runs = int(data.get("total_runs", 0))
	total_extractions = int(data.get("total_extractions", 0))
	total_deaths = int(data.get("total_deaths", 0))
	deepest_ring_reached = str(data.get("deepest_ring_reached", ""))
	artifact_retrievals = int(data.get("artifact_retrievals", 0))
	fastest_extraction_seconds = float(data.get("fastest_extraction_seconds", 0.0))
	# v9 migration guard — M23 collected lore fragments
	var cf: Variant = data.get("collected_fragments", [])
	collected_fragments = cf if typeof(cf) == TYPE_ARRAY else []
	# v10 migration guard — M27 resonance shards
	resonance_shards = int(data.get("resonance_shards", 0))
	resonance_spent = int(data.get("resonance_spent", 0))
	var pu: Variant = data.get("permanent_unlocks", [])
	permanent_unlocks = pu if typeof(pu) == TYPE_ARRAY else []
	# v11 migration guard — M32 achievements
	var ua: Variant = data.get("unlocked_achievements", [])
	unlocked_achievements = ua if typeof(ua) == TYPE_ARRAY else []
	lifetime_kills = int(data.get("lifetime_kills", 0))
	lifetime_poise_breaks = int(data.get("lifetime_poise_breaks", 0))
	var cc: Variant = data.get("completed_challenges", [])
	completed_challenges = cc if typeof(cc) == TYPE_ARRAY else []

func start_run(seed: int, ring_id: String) -> void:
	active_seed = seed
	current_ring = ring_id
	unbanked_xp = 0
	unbanked_loot = 0
	# M27 — silver_sense permanent unlock: start with 15 bonus silver
	if has_permanent_unlock("silver_sense"):
		unbanked_loot = 15
	run_encounters_cleared = 0
	run_total_xp = 0
	run_total_loot = 0
	run_last_enemy_killer = ""
	encounter_damage_taken = 0
	# M23 — Reset per-run fragment tracking
	current_run_fragments = []
	# M21 — Reset per-run stats
	_run_start_time = Time.get_unix_time_from_system()
	current_run_stats = {
		"rings_cleared": [],
		"enemies_killed": 0,
		"damage_taken": 0,
		"damage_dealt": 0,
		"silver_earned": 0,
		"silver_spent": 0,
		"run_duration_seconds": 0.0,
		"extraction_ring": "",
	}
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
	# M21 — Track silver earned
	current_run_stats["silver_earned"] = int(current_run_stats.get("silver_earned", 0)) + loot_value
	telemetry.log_event("encounter_completed", {
		"seed": active_seed,
		"ring": current_ring,
		"xp_gain": xp_value,
		"loot_gain": loot_value,
	})
	encounter_completed.emit(xp_value, loot_value)
	# M32 — Reset per-encounter damage tracking after signal (achievement check reads it)
	encounter_damage_taken = 0

func extract() -> void:
	var event_ring := current_ring
	banked_xp += unbanked_xp
	banked_loot += unbanked_loot

	# Track extraction per ring
	var prev_count: int = int(extractions_by_ring.get(event_ring, 0))
	extractions_by_ring[event_ring] = prev_count + 1

	# Record run history entry
	_add_history_entry(event_ring, true)

	# M21 — Finalize run stats and update lifetime counters
	_finalize_run_stats(event_ring, "extraction")
	total_runs += 1
	total_extractions += 1
	_update_deepest_ring(event_ring)
	var duration := float(current_run_stats.get("run_duration_seconds", 0.0))
	if duration > 0.0 and (fastest_extraction_seconds <= 0.0 or duration < fastest_extraction_seconds):
		fastest_extraction_seconds = duration

	# M27 — Award resonance shards before resetting run state
	award_run_shards("extraction")

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

## Called when the Warden is defeated and the Artifact is retrieved.
## This is the MVP win condition.
func retrieve_artifact() -> void:
	artifact_retrieved = true
	# Bank everything — the player earned it
	banked_xp += unbanked_xp
	banked_loot += unbanked_loot
	var event_ring := current_ring
	var prev_count: int = int(extractions_by_ring.get(event_ring, 0))
	extractions_by_ring[event_ring] = prev_count + 1
	_add_history_entry(event_ring, true)
	# M21 — Finalize run stats and update lifetime counters
	_finalize_run_stats(event_ring, "artifact")
	total_runs += 1
	total_extractions += 1
	artifact_retrievals += 1
	_update_deepest_ring(event_ring)
	var duration := float(current_run_stats.get("run_duration_seconds", 0.0))
	if duration > 0.0 and (fastest_extraction_seconds <= 0.0 or duration < fastest_extraction_seconds):
		fastest_extraction_seconds = duration
	# M27 — Award resonance shards before resetting run state
	award_run_shards("artifact")
	# M27 — artifact_echo: store a random rare modifier for next run
	if has_permanent_unlock("artifact_echo"):
		_store_artifact_echo_modifier()

	unbanked_xp = 0
	unbanked_loot = 0
	current_ring = "sanctuary"
	telemetry.log_event("artifact_retrieved", {
		"seed": active_seed,
		"ring": event_ring,
		"banked_xp": banked_xp,
		"banked_loot": banked_loot,
	})
	artifact_retrieved_signal.emit()

func die_in_run() -> void:
	var event_ring := current_ring
	unbanked_xp = int(unbanked_xp * 0.5)
	unbanked_loot = 0

	# Record run history entry (failed)
	_add_history_entry(event_ring, false)

	# M21 — Finalize run stats and update lifetime counters
	_finalize_run_stats(event_ring, "death")
	total_runs += 1
	total_deaths += 1
	_update_deepest_ring(event_ring)

	# M27 — Award resonance shards before resetting run state
	award_run_shards("death")

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
	# M21 — Track silver spent (vendor purchases happen between runs but count toward stats)
	record_silver_spent(cost)
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

# ── M21 — Combat stat helpers (called from combat_arena) ─────────────────────

func record_enemy_killed() -> void:
	current_run_stats["enemies_killed"] = int(current_run_stats.get("enemies_killed", 0)) + 1
	lifetime_kills += 1

func record_damage_dealt(amount: int) -> void:
	current_run_stats["damage_dealt"] = int(current_run_stats.get("damage_dealt", 0)) + amount

func record_damage_taken(amount: int) -> void:
	current_run_stats["damage_taken"] = int(current_run_stats.get("damage_taken", 0)) + amount
	encounter_damage_taken += amount

func record_silver_spent(amount: int) -> void:
	current_run_stats["silver_spent"] = int(current_run_stats.get("silver_spent", 0)) + amount

# ── M21 — Run finalization helpers ────────────────────────────────────────────

const RING_DEPTH := {"inner": 1, "mid": 2, "outer": 3}

func _finalize_run_stats(event_ring: String, outcome: String) -> void:
	current_run_stats["extraction_ring"] = event_ring if outcome != "death" else "death"
	if _run_start_time > 0.0:
		current_run_stats["run_duration_seconds"] = Time.get_unix_time_from_system() - _run_start_time
	if not current_run_stats.get("rings_cleared", []).has(event_ring):
		var rings_arr: Array = current_run_stats.get("rings_cleared", [])
		rings_arr.append(event_ring)
		current_run_stats["rings_cleared"] = rings_arr

func _update_deepest_ring(ring_id: String) -> void:
	var new_depth: int = int(RING_DEPTH.get(ring_id, 0))
	var old_depth: int = int(RING_DEPTH.get(deepest_ring_reached, 0))
	if new_depth > old_depth:
		deepest_ring_reached = ring_id

func get_personal_bests(outcome: String) -> Array:
	## Returns an Array of Strings describing any personal bests set this run.
	var bests: Array = []
	var event_ring := str(current_run_stats.get("extraction_ring", ""))
	if event_ring == "death":
		event_ring = ""
	# New deepest ring?
	if event_ring != "":
		var new_depth: int = int(RING_DEPTH.get(event_ring, 0))
		# Compare against what deepest_ring_reached was BEFORE this run updated it
		# Since we call this after _update_deepest_ring, check if it equals event_ring
		# and old saved depth was less
		var saved_depth: int = int(RING_DEPTH.get(deepest_ring_reached, 0))
		if saved_depth == new_depth and total_extractions <= 1 and outcome != "death":
			# First extraction from this ring depth
			if new_depth > 1 or total_extractions == 1:
				bests.append("Personal Best: Deepest Ring")
	# Fastest extraction?
	if outcome != "death":
		var duration := float(current_run_stats.get("run_duration_seconds", 0.0))
		if duration > 0.0 and duration == fastest_extraction_seconds:
			bests.append("Personal Best: Fastest Run")
	# First artifact?
	if outcome == "artifact" and artifact_retrievals == 1:
		bests.append("First Artifact Retrieved")
	return bests

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

## Returns true if no completed runs exist and prologue has not been seen.
## Used by title screen to decide Begin routing (prologue vs sanctuary).
func is_first_run() -> bool:
	return run_history.is_empty()

# ── M23 — Lore Fragment Helpers ──────────────────────────────────────────────

func has_fragment(fragment_id: String) -> bool:
	return collected_fragments.has(fragment_id)

func collect_fragment(fragment_id: String) -> void:
	if not collected_fragments.has(fragment_id):
		collected_fragments.append(fragment_id)
		current_run_fragments.append(fragment_id)
		fragment_collected.emit(fragment_id)

func roll_fragment_drop(encounter_seed: int) -> String:
	## Roll for a lore fragment drop (15% chance). Returns fragment_id or "".
	var all_ids: Array = NarrativeManager.get_all_lore_fragment_ids()
	# Filter to uncollected only
	var available: Array = []
	for fid in all_ids:
		if not collected_fragments.has(str(fid)):
			available.append(str(fid))
	if available.is_empty():
		return ""
	# 15% drop chance
	var rng := RandomNumberGenerator.new()
	rng.seed = encounter_seed
	if rng.randf() > 0.15:
		return ""
	# Pick a random available fragment
	return str(available[rng.randi_range(0, available.size() - 1)])

# ── M27 — Resonance Shard Helpers ─────────────────────────────────────────

func calculate_shards_earned(outcome: String) -> int:
	## Calculate shards earned for the current run based on outcome and stats.
	var shards := 10  # Base: always 10

	# Ring bonus: +5 per ring reached beyond sanctuary
	var ring_id := str(current_run_stats.get("extraction_ring", ""))
	if ring_id == "death":
		# Use the ring from run history
		if not run_history.is_empty():
			ring_id = str(run_history[-1].get("ring", "inner"))
		else:
			ring_id = "inner"
	var depth: int = int(RING_DEPTH.get(ring_id, 0))
	shards += depth * 5  # inner=+5, mid=+10, outer=+15

	# Artifact bonus
	if outcome == "artifact":
		shards += 20

	# Enemy kill bonus
	shards += int(current_run_stats.get("enemies_killed", 0))

	# shard_investment permanent unlock: +25% shards
	if has_permanent_unlock("shard_investment"):
		shards = int(ceil(shards * 1.25))

	return shards

func award_run_shards(outcome: String) -> int:
	## Award shards at end of run. Returns shards earned.
	var earned := calculate_shards_earned(outcome)
	# M31 — Challenge run shard bonus on successful completion (not death)
	if ChallengeManager and ChallengeManager.is_challenge_active():
		if outcome != "death":
			earned += ChallengeManager.get_shard_bonus()
			# M32 — Track completed challenge for achievements
			record_challenge_completed(ChallengeManager.active_challenge)
		ChallengeManager.end_run()
	return earned

func has_permanent_unlock(unlock_id: String) -> bool:
	return permanent_unlocks.has(unlock_id)

func purchase_permanent_unlock(unlock_id: String, cost: int) -> bool:
	## Purchase a permanent unlock. Returns true on success.
	if has_permanent_unlock(unlock_id):
		return false
	var available_shards := resonance_shards - resonance_spent
	if available_shards < cost:
		return false
	resonance_spent += cost
	permanent_unlocks.append(unlock_id)
	telemetry.log_event("permanent_unlock_purchased", {
		"unlock_id": unlock_id,
		"cost": cost,
		"shards_remaining": resonance_shards - resonance_spent,
	})
	return true

func get_available_shards() -> int:
	return resonance_shards - resonance_spent

func _store_artifact_echo_modifier() -> void:
	## Pick a random rare (tier 3) run modifier and store its id for next run.
	var rares: Array = []
	for mod in DataStore.get_run_modifiers():
		if int(mod.get("tier", 0)) == 3:
			rares.append(mod)
	if rares.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(active_seed + 7777)
	var pick: Dictionary = rares[rng.randi_range(0, rares.size() - 1)]
	current_run_stats["_artifact_echo_modifier"] = str(pick.get("id", ""))

# ── M32 — Achievement stat helpers ──────────────────────────────────────────

func record_poise_break() -> void:
	lifetime_poise_breaks += 1

func record_challenge_completed(challenge_id: String) -> void:
	if not completed_challenges.has(challenge_id):
		completed_challenges.append(challenge_id)
