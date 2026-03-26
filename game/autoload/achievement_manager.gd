extends Node
# class_name omitted — autoload singleton accessed via "AchievementManager" globally

signal achievement_unlocked(id: String)

var _achievement_data: Array = []
var _achievements_by_id: Dictionary = {}

func _ready() -> void:
	_load_achievements()
	# Connect to GameState signals for achievement checking
	GameState.encounter_completed.connect(_on_encounter_completed)
	GameState.extracted.connect(_on_extracted)
	GameState.player_died.connect(_on_player_died)
	GameState.artifact_retrieved_signal.connect(_on_artifact_retrieved)
	GameState.fragment_collected.connect(_on_fragment_collected)
	GameState.run_started.connect(_on_run_started)

func _load_achievements() -> void:
	var path := "res://data/achievements.json"
	if not FileAccess.file_exists(path):
		push_error("Missing achievements data file: %s" % path)
		return
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid achievements json: %s" % path)
		return
	_achievement_data = parsed.get("achievements", [])
	for ach in _achievement_data:
		_achievements_by_id[str(ach.get("id", ""))] = ach

# ── Public API ────────────────────────────────────────────────────────────────

func get_all_achievements() -> Array:
	return _achievement_data.duplicate(true)

func get_achievement(id: String) -> Dictionary:
	if _achievements_by_id.has(id):
		return _achievements_by_id[id].duplicate(true)
	return {}

func is_unlocked(id: String) -> bool:
	return GameState.unlocked_achievements.has(id)

func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	if not _achievements_by_id.has(id):
		return
	GameState.unlocked_achievements.append(id)
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	achievement_unlocked.emit(id)

func get_unlocked_count() -> int:
	return GameState.unlocked_achievements.size()

func get_total_count() -> int:
	return _achievement_data.size()

func get_progress(id: String) -> Dictionary:
	## Returns {current, target} for count-based achievements.
	match id:
		"poise_master":
			return {"current": GameState.lifetime_poise_breaks, "target": 50}
		"kill_count_100":
			return {"current": GameState.lifetime_kills, "target": 100}
		"kill_count_500":
			return {"current": GameState.lifetime_kills, "target": 500}
		"ten_runs":
			return {"current": GameState.total_runs, "target": 10}
		"five_artifacts":
			return {"current": GameState.artifact_retrievals, "target": 5}
		"all_challenges":
			return {"current": GameState.completed_challenges.size(), "target": 8}
	return {"current": 0, "target": 1}

func get_category_data() -> Dictionary:
	## Returns the category display names and order from achievements.json.
	var path := "res://data/achievements.json"
	if not FileAccess.file_exists(path):
		return {"categories": {}, "category_order": []}
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"categories": {}, "category_order": []}
	return {
		"categories": parsed.get("categories", {}),
		"category_order": parsed.get("category_order", []),
	}

# ── Achievement Check Logic ──────────────────────────────────────────────────

func check_after_encounter() -> void:
	# first_blood: first encounter completed
	if not is_unlocked("first_blood") and GameState.run_encounters_cleared >= 1:
		unlock("first_blood")

	# no_damage_encounter: 0 damage taken this encounter
	if not is_unlocked("no_damage_encounter"):
		if GameState.encounter_damage_taken == 0 and GameState.run_encounters_cleared >= 1:
			unlock("no_damage_encounter")

	# poise_master: 50 lifetime poise breaks
	if not is_unlocked("poise_master") and GameState.lifetime_poise_breaks >= 50:
		unlock("poise_master")

	# kill_count_100 / kill_count_500
	if not is_unlocked("kill_count_100") and GameState.lifetime_kills >= 100:
		unlock("kill_count_100")
	if not is_unlocked("kill_count_500") and GameState.lifetime_kills >= 500:
		unlock("kill_count_500")

func check_after_extraction() -> void:
	# first_extraction
	if not is_unlocked("first_extraction") and GameState.total_extractions >= 1:
		unlock("first_extraction")

	# ten_runs
	if not is_unlocked("ten_runs") and GameState.total_runs >= 10:
		unlock("ten_runs")

	# modifier_stacker: 5+ active modifiers
	if not is_unlocked("modifier_stacker") and GameState.run_active_modifiers.size() >= 5:
		unlock("modifier_stacker")

func check_after_death() -> void:
	# first_death
	if not is_unlocked("first_death") and GameState.total_deaths >= 1:
		unlock("first_death")

	# ten_runs (can also trigger on death)
	if not is_unlocked("ten_runs") and GameState.total_runs >= 10:
		unlock("ten_runs")

func check_after_artifact() -> void:
	# first_artifact
	if not is_unlocked("first_artifact") and GameState.artifact_retrievals >= 1:
		unlock("first_artifact")

	# warden_survivor: retrieve artifact (implies beating Warden without dying this run)
	if not is_unlocked("warden_survivor"):
		unlock("warden_survivor")

	# five_artifacts
	if not is_unlocked("five_artifacts") and GameState.artifact_retrievals >= 5:
		unlock("five_artifacts")

	# cursed_silver_artifact: artifact while cursed_silver active
	if not is_unlocked("cursed_silver_artifact") and GameState.has_modifier("cursed_silver"):
		unlock("cursed_silver_artifact")

	# death_pact_win: artifact while death_pact active
	if not is_unlocked("death_pact_win") and GameState.has_modifier("death_pact"):
		unlock("death_pact_win")

	# modifier_stacker: 5+ active modifiers
	if not is_unlocked("modifier_stacker") and GameState.run_active_modifiers.size() >= 5:
		unlock("modifier_stacker")

	# Challenge achievements (checked after challenge completion is recorded)
	_check_challenge_achievements()

	# ten_runs (can also trigger on artifact)
	if not is_unlocked("ten_runs") and GameState.total_runs >= 10:
		unlock("ten_runs")

func check_after_run_start(ring_id: String) -> void:
	# first_mid: started a run in mid ring
	if not is_unlocked("first_mid") and ring_id == "mid":
		unlock("first_mid")

func check_after_shrine_purchase() -> void:
	# unlock_all_shrines: all 12 permanent unlocks purchased
	if not is_unlocked("unlock_all_shrines"):
		var all_unlocks := DataStore.get_permanent_unlocks()
		if all_unlocks.size() > 0 and GameState.permanent_unlocks.size() >= all_unlocks.size():
			unlock("unlock_all_shrines")

	# itinerant_legacy: purchased itinerant_legacy
	if not is_unlocked("itinerant_legacy") and GameState.has_permanent_unlock("itinerant_legacy"):
		unlock("itinerant_legacy")

func check_after_lore_collection() -> void:
	# read_all_lore: 5 fragments collected in current run
	if not is_unlocked("read_all_lore") and GameState.current_run_fragments.size() >= 5:
		unlock("read_all_lore")

func _check_challenge_achievements() -> void:
	# challenge_complete: any challenge completed
	if not is_unlocked("challenge_complete") and GameState.completed_challenges.size() >= 1:
		unlock("challenge_complete")

	# all_challenges: all 8 challenges completed
	if not is_unlocked("all_challenges") and GameState.completed_challenges.size() >= 8:
		unlock("all_challenges")

# ── Signal Handlers ──────────────────────────────────────────────────────────

func _on_encounter_completed(_xp: int, _loot: int) -> void:
	check_after_encounter()

func _on_extracted(_total_xp: int, _total_loot: int) -> void:
	check_after_extraction()

func _on_player_died() -> void:
	check_after_death()

func _on_artifact_retrieved() -> void:
	check_after_artifact()

func _on_fragment_collected(_fragment_id: String) -> void:
	check_after_lore_collection()

func _on_run_started(seed: int) -> void:
	# Check ring-based achievements after run starts
	check_after_run_start(GameState.current_ring)

	# modifier_stacker: check at run start (modifiers are selected before run)
	if not is_unlocked("modifier_stacker") and GameState.run_active_modifiers.size() >= 5:
		unlock("modifier_stacker")
