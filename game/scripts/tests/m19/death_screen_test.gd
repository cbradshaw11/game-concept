## M19 Test: Death screen delay and flavor text validation.
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── T1: Death delay constant >= 0.8s ────────────────────────────────────
	# main.gd DEATH_SCREEN_DELAY — load and check
	var main_script := load("res://scripts/main.gd") as GDScript
	if main_script == null:
		printerr("FAIL: could not load main.gd")
		checks_failed += 1
	else:
		var delay_val: Variant = main_script.get("DEATH_SCREEN_DELAY")
		if delay_val != null and float(delay_val) >= 0.8:
			print("PASS: DEATH_SCREEN_DELAY is %.1f (>= 0.8)" % float(delay_val))
			checks_passed += 1
		else:
			printerr("FAIL: DEATH_SCREEN_DELAY should be >= 0.8, got %s" % str(delay_val))
			checks_failed += 1

	# ── T2: DEATH_FLAVOR has entries for 'inner' ring ───────────────────────
	var flow_ui_script := load("res://scripts/ui/flow_ui.gd") as GDScript
	if flow_ui_script == null:
		printerr("FAIL: could not load flow_ui.gd")
		checks_failed += 1
	else:
		var death_flavor: Variant = flow_ui_script.get("DEATH_FLAVOR")
		if death_flavor != null and typeof(death_flavor) == TYPE_DICTIONARY:
			var df: Dictionary = death_flavor
			# T2: inner ring flavor exists and non-empty
			if df.has("inner") and (df["inner"] as Array).size() > 0:
				print("PASS: DEATH_FLAVOR has inner ring (%d lines)" % (df["inner"] as Array).size())
				checks_passed += 1
			else:
				printerr("FAIL: DEATH_FLAVOR missing or empty 'inner'")
				checks_failed += 1

			# T3: mid ring flavor exists
			if df.has("mid") and (df["mid"] as Array).size() > 0:
				print("PASS: DEATH_FLAVOR has mid ring (%d lines)" % (df["mid"] as Array).size())
				checks_passed += 1
			else:
				printerr("FAIL: DEATH_FLAVOR missing or empty 'mid'")
				checks_failed += 1

			# T4: outer ring flavor exists
			if df.has("outer") and (df["outer"] as Array).size() > 0:
				print("PASS: DEATH_FLAVOR has outer ring (%d lines)" % (df["outer"] as Array).size())
				checks_passed += 1
			else:
				printerr("FAIL: DEATH_FLAVOR missing or empty 'outer'")
				checks_failed += 1
		else:
			printerr("FAIL: could not read DEATH_FLAVOR from flow_ui.gd")
			checks_failed += 3

	# ── T5: NarrativeManager death flavor text is available ─────────────────
	# Load narrative.json directly for headless test
	var file := FileAccess.open("res://data/narrative.json", FileAccess.READ)
	if file == null:
		printerr("FAIL: could not open narrative.json")
		checks_failed += 4
	else:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		file.close()
		if err != OK:
			printerr("FAIL: narrative.json parse error")
			checks_failed += 4
		else:
			var data: Dictionary = json.get_data()
			var death_flavor: Dictionary = data.get("death_flavor", {})

			# T5: inner death flavor from narrative
			var inner_lines: Array = death_flavor.get("inner", [])
			if inner_lines.size() > 0:
				print("PASS: narrative death_flavor has inner (%d lines)" % inner_lines.size())
				checks_passed += 1
			else:
				printerr("FAIL: narrative death_flavor missing inner")
				checks_failed += 1

			# T6: mid death flavor from narrative
			var mid_lines: Array = death_flavor.get("mid", [])
			if mid_lines.size() > 0:
				print("PASS: narrative death_flavor has mid (%d lines)" % mid_lines.size())
				checks_passed += 1
			else:
				printerr("FAIL: narrative death_flavor missing mid")
				checks_failed += 1

			# T7: outer death flavor from narrative
			var outer_lines: Array = death_flavor.get("outer", [])
			if outer_lines.size() > 0:
				print("PASS: narrative death_flavor has outer (%d lines)" % outer_lines.size())
				checks_passed += 1
			else:
				printerr("FAIL: narrative death_flavor missing outer")
				checks_failed += 1

			# T8: All death flavor lines are non-empty strings
			var all_valid := true
			for ring_key in ["inner", "mid", "outer"]:
				var lines: Array = death_flavor.get(ring_key, [])
				for line in lines:
					if str(line).strip_edges() == "":
						all_valid = false
						break
			if all_valid:
				print("PASS: all death flavor lines are non-empty")
				checks_passed += 1
			else:
				printerr("FAIL: found empty death flavor line")
				checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M19 death screen test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M19 death screen test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
