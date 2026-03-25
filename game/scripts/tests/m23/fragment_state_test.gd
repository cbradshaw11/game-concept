## M23 Test: Fragment state persistence — save/load, migration guard
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# T1: GameState script loads and has collected_fragments field
	var gs_script := load("res://autoload/game_state.gd")
	if gs_script == null:
		printerr("FAIL: could not load game_state.gd")
		quit(1)
		return

	var gs := gs_script.new()
	# Stub dependencies to avoid errors
	gs.name = "GameState"

	if typeof(gs.collected_fragments) == TYPE_ARRAY:
		print("PASS: collected_fragments is Array")
		passed += 1
	else:
		printerr("FAIL: collected_fragments is not Array (type=%d)" % typeof(gs.collected_fragments))
		failed += 1

	# T2: Default is empty
	if gs.collected_fragments.is_empty():
		print("PASS: collected_fragments defaults to empty")
		passed += 1
	else:
		printerr("FAIL: collected_fragments not empty by default")
		failed += 1

	# T3: default_save_state includes collected_fragments
	var defaults := gs.default_save_state()
	if defaults.has("collected_fragments"):
		print("PASS: default_save_state has collected_fragments key")
		passed += 1
	else:
		printerr("FAIL: default_save_state missing collected_fragments")
		failed += 1

	# T4: to_save_state serializes collected_fragments
	gs.collected_fragments = ["fragment_001", "fragment_003"]
	var saved := gs.to_save_state()
	var saved_frags: Array = saved.get("collected_fragments", [])
	if saved_frags.size() == 2 and str(saved_frags[0]) == "fragment_001":
		print("PASS: to_save_state includes collected fragments")
		passed += 1
	else:
		printerr("FAIL: to_save_state fragments mismatch (got %s)" % str(saved_frags))
		failed += 1

	# T5: apply_save_state restores collected_fragments
	var gs2 := gs_script.new()
	gs2.name = "GameState2"
	gs2.apply_save_state(saved)
	if gs2.collected_fragments.size() == 2 and str(gs2.collected_fragments[1]) == "fragment_003":
		print("PASS: apply_save_state restores collected fragments")
		passed += 1
	else:
		printerr("FAIL: apply_save_state did not restore fragments (got %s)" % str(gs2.collected_fragments))
		failed += 1

	# T6: v9 migration guard — old save without collected_fragments
	var old_save := {"banked_xp": 100, "banked_loot": 50}
	var gs3 := gs_script.new()
	gs3.name = "GameState3"
	gs3.apply_save_state(old_save)
	if gs3.collected_fragments.is_empty():
		print("PASS: migration guard — missing collected_fragments defaults to empty")
		passed += 1
	else:
		printerr("FAIL: migration guard did not default to empty array")
		failed += 1

	# T7: current_run_fragments field exists and defaults to empty
	if typeof(gs.current_run_fragments) == TYPE_ARRAY:
		print("PASS: current_run_fragments is Array")
		passed += 1
	else:
		printerr("FAIL: current_run_fragments is not Array")
		failed += 1

	# T8: has_fragment works
	gs.collected_fragments = ["fragment_002"]
	if gs.has_fragment("fragment_002") and not gs.has_fragment("fragment_999"):
		print("PASS: has_fragment returns correct results")
		passed += 1
	else:
		printerr("FAIL: has_fragment returned wrong result")
		failed += 1

	# Cleanup
	gs.free()
	gs2.free()
	gs3.free()

	if failed == 0:
		print("PASS: M23 fragment state test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M23 fragment state test (%d failed)" % failed)
		quit(1)
