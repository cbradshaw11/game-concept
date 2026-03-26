extends SceneTree

func _initialize() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		# Fallback: instantiate GameState directly for headless test context
		var GSScript = load("res://autoload/game_state.gd")
		gs = GSScript.new()
		root.add_child(gs)

	gs.telemetry.clear()
	gs.set_telemetry_enabled(true)

	gs.start_run(2222, "inner")
	gs.add_unbanked(5, 2)
	gs.extract()

	var events: Array = gs.telemetry.events
	if events.size() != 3:
		_fail("expected 3 events for start->encounter->extract")
		return

	if str(events[0].get("event", "")) != "run_started":
		_fail("first event should be run_started")
		return
	if str(events[1].get("event", "")) != "encounter_completed":
		_fail("second event should be encounter_completed")
		return
	if str(events[2].get("event", "")) != "extracted":
		_fail("third event should be extracted")
		return

	for event in events:
		if int(event.get("seed", 0)) != 2222:
			_fail("events should include the active seed")
			return
		if str(event.get("ring", "")) == "":
			_fail("events should include the active ring")
			return

	gs.telemetry.clear()
	gs.set_telemetry_enabled(false)
	gs.start_run(3333, "outer")
	gs.die_in_run()
	if not gs.telemetry.events.is_empty():
		_fail("telemetry should not record when disabled")
		return

	gs.set_telemetry_enabled(true)
	print("PASS: telemetry lifecycle and toggle test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
