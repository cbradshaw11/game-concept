extends SceneTree

func _initialize() -> void:
	GameState.telemetry.clear()
	GameState.set_telemetry_enabled(true)

	GameState.start_run(2222, "inner")
	GameState.add_unbanked(5, 2)
	GameState.extract()

	var events := GameState.telemetry.events
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

	GameState.telemetry.clear()
	GameState.set_telemetry_enabled(false)
	GameState.start_run(3333, "outer")
	GameState.die_in_run()
	if not GameState.telemetry.events.is_empty():
		_fail("telemetry should not record when disabled")
		return

	GameState.set_telemetry_enabled(true)
	print("PASS: telemetry lifecycle and toggle test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
