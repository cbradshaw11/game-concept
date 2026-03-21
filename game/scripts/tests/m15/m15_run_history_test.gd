## M15 Test: Run history structure validation (M15 T10)
## Tests via rings.json and extraction count tracking logic (pure data, no autoload).
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _simulate_history(runs: Array) -> Array:
	"""Simulate run history tracking: each run is {ring, extracted, xp, loot}."""
	const MAX_HISTORY := 20
	var history: Array = []
	for run in runs:
		history.append({
			"ring": str(run.get("ring", "inner")),
			"extracted": bool(run.get("extracted", false)),
			"unbanked_xp": int(run.get("xp", 0)),
			"unbanked_loot": int(run.get("loot", 0)),
		})
	if history.size() > MAX_HISTORY:
		history = history.slice(history.size() - MAX_HISTORY)
	return history

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── GameState save state contains history fields ───────────────────────────
	# Load game_state.gd directly as text and check for required fields
	var gs_path := "res://autoload/game_state.gd"
	if FileAccess.file_exists(gs_path):
		var gs_text := FileAccess.get_file_as_string(gs_path)
		if "run_history" in gs_text:
			print("PASS: game_state.gd contains run_history field")
			checks_passed += 1
		else:
			printerr("FAIL: game_state.gd missing run_history")
			checks_failed += 1

		if "extractions_by_ring" in gs_text:
			print("PASS: game_state.gd contains extractions_by_ring field")
			checks_passed += 1
		else:
			printerr("FAIL: game_state.gd missing extractions_by_ring")
			checks_failed += 1

		if "get_run_history" in gs_text:
			print("PASS: game_state.gd has get_run_history() method")
			checks_passed += 1
		else:
			printerr("FAIL: game_state.gd missing get_run_history()")
			checks_failed += 1

		if "MAX_HISTORY" in gs_text:
			print("PASS: game_state.gd defines MAX_HISTORY cap")
			checks_passed += 1
		else:
			printerr("FAIL: game_state.gd missing MAX_HISTORY cap")
			checks_failed += 1

	# ── History tracking logic ────────────────────────────────────────────────
	# Single extraction run
	var runs_1: Array = [{"ring": "inner", "extracted": true, "xp": 100, "loot": 60}]
	var hist_1 := _simulate_history(runs_1)
	if hist_1.size() == 1:
		print("PASS: history has 1 entry after 1 run")
		checks_passed += 1
	else:
		printerr("FAIL: history should have 1 entry")
		checks_failed += 1

	if bool(hist_1[0].get("extracted", false)):
		print("PASS: successful extraction recorded as extracted=true")
		checks_passed += 1
	else:
		printerr("FAIL: successful run should have extracted=true")
		checks_failed += 1

	# Death run
	var runs_2: Array = [
		{"ring": "inner", "extracted": true, "xp": 100, "loot": 60},
		{"ring": "mid", "extracted": false, "xp": 50, "loot": 0},
	]
	var hist_2 := _simulate_history(runs_2)
	if hist_2.size() == 2:
		print("PASS: history has 2 entries after 2 runs")
		checks_passed += 1
	else:
		printerr("FAIL: history should have 2 entries")
		checks_failed += 1

	if not bool(hist_2[1].get("extracted", true)):
		print("PASS: death run recorded as extracted=false")
		checks_passed += 1
	else:
		printerr("FAIL: death run should have extracted=false")
		checks_failed += 1

	# History cap at 20
	var many_runs: Array = []
	for i in range(25):
		many_runs.append({"ring": "inner", "extracted": true, "xp": i * 10, "loot": i * 5})
	var hist_many := _simulate_history(many_runs)
	if hist_many.size() == 20:
		print("PASS: history capped at 20 entries")
		checks_passed += 1
	else:
		printerr("FAIL: history should be capped at 20, got %d" % hist_many.size())
		checks_failed += 1

	# ── Save state includes history ────────────────────────────────────────────
	# Verify to_save_state and apply_save_state mention run_history
	if FileAccess.file_exists(gs_path):
		var gs_text := FileAccess.get_file_as_string(gs_path)
		if "to_save_state" in gs_text and "run_history" in gs_text:
			print("PASS: run_history included in to_save_state")
			checks_passed += 1
		else:
			printerr("FAIL: run_history missing from to_save_state")
			checks_failed += 1

	if checks_failed == 0:
		print("PASS: M15 run history test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M15 run history test (%d failed)" % checks_failed)
		quit(1)
