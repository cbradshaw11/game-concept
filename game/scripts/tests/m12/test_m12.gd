extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- Test 1: run_history uses GameState.total_runs (structural check) ---
	var run_history_src := FileAccess.get_file_as_string("res://scripts/ui/run_history.gd")
	if run_history_src.is_empty():
		failures.append("Test 1a: could not read run_history.gd")
	else:
		if "GameState.total_runs" not in run_history_src:
			failures.append("Test 1b: run_history.gd does not reference GameState.total_runs")
		# total_runs should NOT be assigned from history.size()
		# Look for any pattern like: total_runs = history.size() or total_runs=history.size()
		if "total_runs = history.size()" in run_history_src:
			failures.append("Test 1c: run_history.gd assigns total_runs from history.size() -- should use GameState.total_runs")

	# --- Test 2: Story modal has pause guard ---
	var flow_ui_src := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if flow_ui_src.is_empty():
		failures.append("Test 2a: could not read flow_ui.gd")
	else:
		var pause_func_idx: int = flow_ui_src.find("func _handle_pause_input")
		if pause_func_idx == -1:
			failures.append("Test 2b: flow_ui.gd missing func _handle_pause_input")
		else:
			var pause_region: String = flow_ui_src.substr(pause_func_idx, 300)
			if "is_instance_valid(_story_modal)" not in pause_region:
				failures.append("Test 2c: _handle_pause_input does not contain is_instance_valid(_story_modal) guard")

	# --- Test 3: Story modal has custom_minimum_size ---
	if flow_ui_src.is_empty():
		failures.append("Test 3a: flow_ui.gd not available (skipping)")
	else:
		if "custom_minimum_size = Vector2(400.0, 200.0)" not in flow_ui_src:
			failures.append("Test 3b: flow_ui.gd missing custom_minimum_size = Vector2(400.0, 200.0) on story modal")

	# --- Test 4: on_dismiss.call() is inside the is_instance_valid guard ---
	# Verify that on_dismiss.call() appears after _story_modal = null inside the guard block.
	# We check that the line preceding on_dismiss.call() (skipping blanks) contains _story_modal = null.
	if flow_ui_src.is_empty():
		failures.append("Test 4a: flow_ui.gd not available (skipping)")
	else:
		var dismiss_call_idx: int = flow_ui_src.find("on_dismiss.call()")
		if dismiss_call_idx == -1:
			failures.append("Test 4b: flow_ui.gd missing on_dismiss.call()")
		else:
			# The text before on_dismiss.call() should contain _story_modal = null (inside the guard)
			var before_dismiss: String = flow_ui_src.substr(0, dismiss_call_idx)
			var last_null_assign: int = before_dismiss.rfind("_story_modal = null")
			if last_null_assign == -1:
				failures.append("Test 4c: on_dismiss.call() does not appear after _story_modal = null -- may be outside the guard")
			else:
				# Confirm nothing outside the guard pattern appears between _story_modal = null and on_dismiss.call()
				var between: String = flow_ui_src.substr(last_null_assign, dismiss_call_idx - last_null_assign)
				# Between should be short (just whitespace/newline + on_dismiss.call())
				var trimmed: String = between.replace("_story_modal = null", "").strip_edges()
				# trimmed should be empty or just on_dismiss.call() approach
				if "func " in trimmed:
					failures.append("Test 4d: on_dismiss.call() appears outside the is_instance_valid(_story_modal) guard block")

	# --- Test 5: Story modal has ScrollContainer ---
	if flow_ui_src.is_empty():
		failures.append("Test 5a: flow_ui.gd not available (skipping)")
	else:
		if "ScrollContainer.new()" not in flow_ui_src:
			failures.append("Test 5b: flow_ui.gd missing ScrollContainer.new() for story modal height cap")

	# --- Test 6: enemy_controller orphaned ATTACK state fixed ---
	var enemy_ctrl_src := FileAccess.get_file_as_string("res://scripts/core/enemy_controller.gd")
	if enemy_ctrl_src.is_empty():
		failures.append("Test 6a: could not read enemy_controller.gd")
	else:
		# The old buggy pattern set state to ATTACK in the else branch of attack range
		# After the fix the else branch should set state to CHASE
		# Look for else: followed by state = EnemyState.ATTACK in the attack range block
		# We check that this problematic pattern does NOT exist
		if "else:\n\t\tstate = EnemyState.ATTACK" in enemy_ctrl_src:
			failures.append("Test 6b: enemy_controller.gd still contains orphaned ATTACK state in else branch")
		# Positive check: CHASE should appear in that branch area
		if "state = EnemyState.CHASE" not in enemy_ctrl_src:
			failures.append("Test 6c: enemy_controller.gd missing state = EnemyState.CHASE in attack range block")

	# --- Test 7: guard_counter closure has is_instance_valid guard ---
	var arena_src := FileAccess.get_file_as_string("res://scenes/combat/combat_arena.gd")
	if arena_src.is_empty():
		failures.append("Test 7a: could not read combat_arena.gd")
	else:
		if "is_instance_valid(pc) and pc.guarding" not in arena_src:
			failures.append("Test 7b: combat_arena.gd guard_counter profile missing is_instance_valid(pc) and pc.guarding")

	# --- Test 8: Warden Phase 3 cooldown is 0.5 ---
	if enemy_ctrl_src.is_empty():
		failures.append("Test 8a: enemy_controller.gd not available (skipping)")
	else:
		# Find the phase 3 block and verify attack_cooldown = 0.5 appears there
		var phase3_idx: int = enemy_ctrl_src.find("_current_phase == 3")
		if phase3_idx == -1:
			failures.append("Test 8b: enemy_controller.gd missing _current_phase == 3 block")
		else:
			var phase3_region: String = enemy_ctrl_src.substr(phase3_idx, 200)
			if "attack_cooldown = 0.5" not in phase3_region:
				failures.append("Test 8c: enemy_controller.gd phase 3 block does not set attack_cooldown = 0.5")

	# --- Test 9: Ring music architecture wired ---
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	if main_src.is_empty():
		failures.append("Test 9a: could not read main.gd")
	else:
		if "music_combat_inner" not in main_src:
			failures.append("Test 9b: main.gd missing music_combat_inner track reference")
		if "music_combat_mid" not in main_src:
			failures.append("Test 9c: main.gd missing music_combat_mid track reference")
		if "music_combat_outer" not in main_src:
			failures.append("Test 9d: main.gd missing music_combat_outer track reference")
		if "_play_music_from_path" not in main_src:
			failures.append("Test 9e: main.gd missing _play_music_from_path function")

	# --- Test 10: Music transition uses _stop_music ---
	if main_src.is_empty():
		failures.append("Test 10a: main.gd not available (skipping)")
	else:
		# The new architecture uses _stop_music in _on_start_run_pressed
		var start_run_idx: int = main_src.find("func _on_start_run_pressed")
		if start_run_idx == -1:
			failures.append("Test 10b: main.gd missing func _on_start_run_pressed")
		else:
			var start_run_region: String = main_src.substr(start_run_idx, 600)
			if "_stop_music" not in start_run_region:
				failures.append("Test 10c: _on_start_run_pressed does not call _stop_music")
		# Old inline pattern should not exist anywhere in the file
		if "_music_player.stream = _combat_stream" in main_src:
			failures.append("Test 10d: main.gd still contains old inline _music_player.stream = _combat_stream pattern")

	# --- Test 11: run_number uses total_runs ---
	var game_state_src := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	if game_state_src.is_empty():
		failures.append("Test 11a: could not read game_state.gd")
	else:
		if '"run_number": total_runs + 1' not in game_state_src:
			failures.append("Test 11b: game_state.gd run_number not set from total_runs + 1")
		if '"run_number": run_history.size() + 1' in game_state_src:
			failures.append("Test 11c: game_state.gd run_number still uses run_history.size() + 1 (should use total_runs + 1)")

	# --- Test 12: M12 adversarial log exists with fixes marked ---
	var adv_log := FileAccess.get_file_as_string("res://../../design/adversarial-log.md")
	if adv_log.is_empty():
		# Try alternate path from project root
		adv_log = FileAccess.get_file_as_string("res://../design/adversarial-log.md")
	if adv_log.is_empty():
		# Try OS path
		var f := FileAccess.open("/Users/connerbradshaw/Dev/game-concept/design/adversarial-log.md", FileAccess.READ)
		if f != null:
			adv_log = f.get_as_text()
			f.close()
	if adv_log.is_empty():
		failures.append("Test 12a: design/adversarial-log.md not found or empty")
	else:
		if "[FIXED]" not in adv_log:
			failures.append("Test 12b: adversarial-log.md exists but contains no [FIXED] markers -- adversarial pass may not be complete")

	# --- Finalize ---
	if failures.is_empty():
		print("PASS: test_m12")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
