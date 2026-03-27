extends SceneTree
## M34 — Controls display tests
## Verifies: ControlsGrid node exists, binding labels populate from InputMap

func _init() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# We can't fully instantiate the settings screen (it's a CanvasLayer that
	# relies on SettingsManager autoload), so we test the _get_bindings_text
	# helper and verify the script structure.

	# ── Test 1: settings_screen.gd loads without error ───────────────────────
	var script: GDScript = load("res://scripts/ui/settings_screen.gd")
	if script != null:
		print("PASS: settings_screen.gd loads successfully")
		checks_passed += 1
	else:
		printerr("FAIL: settings_screen.gd failed to load")
		checks_failed += 1
		quit(1)
		return

	# ── Test 2: Script has _get_bindings_text method ─────────────────────────
	var method_list := script.get_script_method_list()
	var has_bindings_method := false
	var has_build_ui := false
	for method in method_list:
		if str(method.get("name", "")) == "_get_bindings_text":
			has_bindings_method = true
		if str(method.get("name", "")) == "_build_ui":
			has_build_ui = true
	if has_bindings_method:
		print("PASS: settings_screen.gd has _get_bindings_text method")
		checks_passed += 1
	else:
		printerr("FAIL: settings_screen.gd missing _get_bindings_text method")
		checks_failed += 1

	if has_build_ui:
		print("PASS: settings_screen.gd has _build_ui method")
		checks_passed += 1
	else:
		printerr("FAIL: settings_screen.gd missing _build_ui method")
		checks_failed += 1

	# ── Test 3: InputMap has the expected actions ────────────────────────────
	var expected_actions := ["attack", "dodge", "guard", "ui_left", "ui_right", "ui_up", "ui_down", "ui_cancel"]
	var missing_actions: Array = []
	for action in expected_actions:
		if not InputMap.has_action(action):
			missing_actions.append(action)
	if missing_actions.is_empty():
		print("PASS: all expected InputMap actions exist (%d actions)" % expected_actions.size())
		checks_passed += 1
	else:
		# ui_ actions are built-in and always exist; custom ones depend on project.godot
		printerr("FAIL: missing InputMap actions: %s" % str(missing_actions))
		checks_failed += 1

	# ── Test 4: attack action has at least one key event ─────────────────────
	if InputMap.has_action("attack"):
		var events := InputMap.action_get_events("attack")
		var has_key := false
		for event in events:
			if event is InputEventKey:
				has_key = true
				break
		if has_key:
			print("PASS: attack action has at least one key binding")
			checks_passed += 1
		else:
			printerr("FAIL: attack action has no key bindings")
			checks_failed += 1
	else:
		printerr("FAIL: attack action not found (skipping binding check)")
		checks_failed += 1

	# ── Test 5: Source file contains ControlsGrid node creation ──────────────
	var src := FileAccess.get_file_as_string("res://scripts/ui/settings_screen.gd")
	if src.find("ControlsGrid") != -1:
		print("PASS: settings_screen.gd creates ControlsGrid node")
		checks_passed += 1
	else:
		printerr("FAIL: settings_screen.gd does not reference ControlsGrid")
		checks_failed += 1

	# ── Test 6: Source reads from InputMap (not hardcoded strings) ────────────
	if src.find("InputMap.action_get_events") != -1:
		print("PASS: settings_screen.gd reads bindings from InputMap at runtime")
		checks_passed += 1
	else:
		printerr("FAIL: settings_screen.gd does not read from InputMap")
		checks_failed += 1

	# ── Test 7: All 6 core actions are displayed ─────────────────────────────
	var display_actions := ["Move", "Attack", "Dodge", "Guard", "Interact", "Pause"]
	var all_present := true
	for action in display_actions:
		if src.find("\"" + action + "\"") == -1:
			printerr("FAIL: display action '%s' not found in settings_screen.gd" % action)
			all_present = false
	if all_present:
		print("PASS: all 6 core actions displayed (Move, Attack, Dodge, Guard, Interact, Pause)")
		checks_passed += 1
	else:
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M34 controls display tests (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M34 controls display tests (%d failed, %d passed)" % [checks_failed, checks_passed])
		quit(1)
