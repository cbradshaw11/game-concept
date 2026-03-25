## M23 Test: Fragment UI — pickup modal data, archive count, run summary line
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _initialize() -> void:
	var passed := 0
	var failed := 0

	var ndata: Variant = _load_json("res://data/narrative.json")
	if ndata == null:
		printerr("FAIL: could not load narrative.json")
		quit(1)
		return

	var fragments: Array = ndata.get("lore_fragments", [])

	# T1: Each fragment has title and text suitable for display
	var display_ok := true
	for f in fragments:
		var title := str(f.get("title", ""))
		var text := str(f.get("text", ""))
		if title.length() < 5:
			display_ok = false
			printerr("FAIL: fragment %s title too short" % str(f.get("id", "?")))
			failed += 1
		if text.length() < 50:
			display_ok = false
			printerr("FAIL: fragment %s text too short (<50 chars)" % str(f.get("id", "?")))
			failed += 1
	if display_ok:
		print("PASS: all fragments have display-ready title and text")
		passed += 1

	# T2: Fragment IDs follow expected naming convention
	var ids_ok := true
	for f in fragments:
		var fid := str(f.get("id", ""))
		if not fid.begins_with("fragment_"):
			ids_ok = false
			printerr("FAIL: fragment id '%s' does not start with 'fragment_'" % fid)
			failed += 1
	if ids_ok:
		print("PASS: all fragment IDs follow naming convention")
		passed += 1

	# T3: Verify NarrativeManager API loads fragments (script-level check)
	var nm_script := load("res://autoload/narrative_manager.gd")
	if nm_script != null:
		print("PASS: narrative_manager.gd loads successfully")
		passed += 1
	else:
		printerr("FAIL: could not load narrative_manager.gd")
		failed += 1

	# T4: RunSummary script loads and has FragmentLabel in build
	var rs_script := load("res://scripts/ui/run_summary.gd")
	if rs_script != null:
		var source := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
		if source.find("FragmentLabel") != -1:
			print("PASS: run_summary.gd contains FragmentLabel node")
			passed += 1
		else:
			printerr("FAIL: run_summary.gd missing FragmentLabel")
			failed += 1
	else:
		printerr("FAIL: could not load run_summary.gd")
		failed += 1

	# T5: FlowUI script has fragment pickup and recovered notes methods
	var fui_source := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if fui_source.find("show_fragment_pickup") != -1:
		print("PASS: flow_ui.gd has show_fragment_pickup method")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd missing show_fragment_pickup")
		failed += 1

	if fui_source.find("_show_recovered_notes") != -1:
		print("PASS: flow_ui.gd has _show_recovered_notes method")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd missing _show_recovered_notes")
		failed += 1

	if fui_source.find("RecoveredNotesButton") != -1:
		print("PASS: flow_ui.gd has RecoveredNotesButton setup")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd missing RecoveredNotesButton")
		failed += 1

	# T6: GameState has fragment_collected signal
	var gs_source := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	if gs_source.find("signal fragment_collected") != -1:
		print("PASS: game_state.gd has fragment_collected signal")
		passed += 1
	else:
		printerr("FAIL: game_state.gd missing fragment_collected signal")
		failed += 1

	# T7: main.gd has fragment drop wiring
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if main_source.find("roll_fragment_drop") != -1:
		print("PASS: main.gd wires fragment drop after encounter")
		passed += 1
	else:
		printerr("FAIL: main.gd missing fragment drop wiring")
		failed += 1

	# T8: Run summary includes "Notes Recovered" text
	var rs_source := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
	if rs_source.find("Notes Recovered") != -1:
		print("PASS: run_summary.gd shows 'Notes Recovered' line")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing Notes Recovered line")
		failed += 1

	if failed == 0:
		print("PASS: M23 fragment UI test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M23 fragment UI test (%d failed)" % failed)
		quit(1)
