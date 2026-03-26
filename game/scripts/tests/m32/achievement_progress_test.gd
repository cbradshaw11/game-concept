extends SceneTree
## M32 — Achievement progress and trigger validation
## Verifies: count-based thresholds, trigger hookup, stat tracking code

func _initialize() -> void:
	# --- Test 1: AchievementManager has correct progress thresholds ---
	var am_source := FileAccess.get_file_as_string("res://autoload/achievement_manager.gd")

	# kill_count_100 target is 100
	if am_source.find('"kill_count_100"') != -1 and am_source.find('"target": 100') != -1:
		print("PASS: kill_count_100 has target of 100")
	else:
		printerr("FAIL: kill_count_100 target of 100 not found in achievement_manager.gd")

	# kill_count_500 target is 500
	if am_source.find('"kill_count_500"') != -1 and am_source.find('"target": 500') != -1:
		print("PASS: kill_count_500 has target of 500")
	else:
		printerr("FAIL: kill_count_500 target of 500 not found")

	# poise_master target is 50
	if am_source.find('"poise_master"') != -1 and am_source.find('"target": 50') != -1:
		print("PASS: poise_master has target of 50")
	else:
		printerr("FAIL: poise_master target of 50 not found")

	# --- Test 2: GameState tracks lifetime_kills in record_enemy_killed ---
	var gs_source := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	if gs_source.find("lifetime_kills += 1") != -1:
		print("PASS: record_enemy_killed increments lifetime_kills")
	else:
		printerr("FAIL: lifetime_kills not incremented in record_enemy_killed")

	# --- Test 3: GameState tracks lifetime_poise_breaks in record_poise_break ---
	if gs_source.find("lifetime_poise_breaks += 1") != -1:
		print("PASS: record_poise_break increments lifetime_poise_breaks")
	else:
		printerr("FAIL: lifetime_poise_breaks not incremented in record_poise_break")

	# --- Test 4: combat_arena calls record_poise_break ---
	var arena_source := FileAccess.get_file_as_string("res://scenes/combat/combat_arena.gd")
	var poise_break_calls := 0
	var search_pos := 0
	while true:
		var found := arena_source.find("record_poise_break()", search_pos)
		if found == -1:
			break
		poise_break_calls += 1
		search_pos = found + 1
	if poise_break_calls >= 2:
		print("PASS: combat_arena calls record_poise_break at %d locations" % poise_break_calls)
	else:
		printerr("FAIL: combat_arena should call record_poise_break at 2+ locations, found %d" % poise_break_calls)

	# --- Test 5: AchievementManager connects to all required signals ---
	var required_signals := [
		"encounter_completed",
		"extracted",
		"player_died",
		"artifact_retrieved_signal",
		"fragment_collected",
		"run_started",
	]
	var all_connected := true
	for sig in required_signals:
		if am_source.find(sig) == -1:
			printerr("FAIL: AchievementManager missing signal connection for '%s'" % sig)
			all_connected = false
	if all_connected:
		print("PASS: AchievementManager connects to all 6 required GameState signals")

	# --- Test 6: encounter_damage_taken tracking ---
	if gs_source.find("encounter_damage_taken += amount") != -1:
		print("PASS: record_damage_taken increments encounter_damage_taken")
	else:
		printerr("FAIL: encounter_damage_taken not incremented in record_damage_taken")

	# --- Test 7: encounter_damage_taken resets in encounter flow ---
	if gs_source.find("encounter_damage_taken = 0") != -1:
		print("PASS: encounter_damage_taken resets in game flow")
	else:
		printerr("FAIL: encounter_damage_taken reset not found")

	# --- Test 8: record_challenge_completed deduplicates ---
	if gs_source.find("not completed_challenges.has(challenge_id)") != -1:
		print("PASS: record_challenge_completed has deduplication guard")
	else:
		printerr("FAIL: record_challenge_completed missing deduplication guard")

	# --- Test 9: FlowUI has achievement toast handler ---
	var flow_source := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if flow_source.find("_show_achievement_toast") != -1:
		print("PASS: FlowUI has achievement toast handler")
	else:
		printerr("FAIL: FlowUI missing achievement toast handler")

	# --- Test 10: FlowUI has achievement gallery ---
	if flow_source.find("_show_achievements") != -1 and flow_source.find("AchievementPanel") != -1:
		print("PASS: FlowUI has achievement gallery panel")
	else:
		printerr("FAIL: FlowUI missing achievement gallery")

	quit(0)
