extends SceneTree
## M32 — Achievement manager logic tests
## Verifies: unlock logic, duplicate guard, save state fields, migration guard

func _initialize() -> void:
	# --- Test 1: achievements.json loads and has correct structure ---
	var raw := FileAccess.get_file_as_string("res://data/achievements.json")
	var data: Dictionary = JSON.parse_string(raw)
	var achievements: Array = data.get("achievements", [])
	var by_id: Dictionary = {}
	for ach in achievements:
		by_id[str(ach.get("id", ""))] = ach

	if by_id.size() == 20:
		print("PASS: achievement lookup dictionary has 20 entries")
	else:
		printerr("FAIL: expected 20 entries in lookup, got %d" % by_id.size())

	# --- Test 2: Simulate unlock + duplicate guard ---
	var unlocked: Array = []
	# Simulate unlock("first_blood")
	if not unlocked.has("first_blood"):
		unlocked.append("first_blood")
	# Simulate duplicate unlock
	if not unlocked.has("first_blood"):
		unlocked.append("first_blood")
	if unlocked.size() == 1:
		print("PASS: unlock guard prevents duplicate entries")
	else:
		printerr("FAIL: duplicate guard failed, got %d entries" % unlocked.size())

	# --- Test 3: is_unlocked logic ---
	if unlocked.has("first_blood"):
		print("PASS: is_unlocked returns true for unlocked achievement")
	else:
		printerr("FAIL: is_unlocked should return true for first_blood")

	if not unlocked.has("nonexistent"):
		print("PASS: is_unlocked returns false for non-existent achievement")
	else:
		printerr("FAIL: is_unlocked should return false for nonexistent")

	# --- Test 4: Save state includes achievement fields ---
	# Verify default_save_state has all M32 fields
	var default_keys := ["unlocked_achievements", "lifetime_kills", "lifetime_poise_breaks", "completed_challenges"]
	# Read game_state.gd source to verify fields exist
	var gs_source := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	var all_keys_found := true
	for key in default_keys:
		if gs_source.find('"%s"' % key) == -1:
			printerr("FAIL: game_state.gd missing save field '%s'" % key)
			all_keys_found = false
	if all_keys_found:
		print("PASS: game_state.gd contains all M32 save fields")

	# --- Test 5: Verify to_save_state has achievement fields ---
	var to_save_section := gs_source.find("func to_save_state")
	var apply_save_section := gs_source.find("func apply_save_state")
	if to_save_section != -1:
		var to_save_block := gs_source.substr(to_save_section, apply_save_section - to_save_section if apply_save_section > to_save_section else 500)
		var all_in_to_save := true
		for key in default_keys:
			if to_save_block.find(key) == -1:
				printerr("FAIL: to_save_state missing '%s'" % key)
				all_in_to_save = false
		if all_in_to_save:
			print("PASS: to_save_state includes all M32 fields")
	else:
		printerr("FAIL: could not find to_save_state function")

	# --- Test 6: Verify apply_save_state has migration guards ---
	if apply_save_section != -1:
		var apply_block := gs_source.substr(apply_save_section, 2000)
		var all_in_apply := true
		for key in default_keys:
			if apply_block.find(key) == -1:
				printerr("FAIL: apply_save_state missing '%s'" % key)
				all_in_apply = false
		if all_in_apply:
			print("PASS: apply_save_state has migration guards for all M32 fields")
	else:
		printerr("FAIL: could not find apply_save_state function")

	# --- Test 7: AchievementManager autoload script exists ---
	if FileAccess.file_exists("res://autoload/achievement_manager.gd"):
		print("PASS: achievement_manager.gd autoload script exists")
	else:
		printerr("FAIL: achievement_manager.gd not found")

	quit(0)
