## M17 Test: Warden boss intro monologue validation (M17 T7)
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var file := FileAccess.open("res://data/narrative.json", FileAccess.READ)
	if file == null:
		printerr("FAIL: could not open narrative.json")
		quit(1)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		printerr("FAIL: JSON parse error in narrative.json")
		quit(1)
		return

	var data: Dictionary = json.get_data()
	var warden: Dictionary = data.get("warden_intro", {})
	var lines: Array = warden.get("lines", [])

	# ── Has at least 4 sequential lines ──────────────────────────────────────
	if lines.size() >= 4:
		print("PASS: warden_intro has %d lines (>= 4)" % lines.size())
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro should have >= 4 lines, got %d" % lines.size())
		checks_failed += 1

	# ── First line is "..." (beats of silence before monologue) ──────────────
	if lines.size() > 0 and str(lines[0]) == "...":
		print("PASS: warden_intro first line is '...'")
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro first line should be '...', got '%s'" % (str(lines[0]) if lines.size() > 0 else "(empty)"))
		checks_failed += 1

	# ── No empty lines ────────────────────────────────────────────────────────
	var empty_found := false
	for line in lines:
		if str(line).strip_edges() == "":
			empty_found = true
			printerr("FAIL: empty line found in warden_intro")
			checks_failed += 1
			break
	if not empty_found:
		print("PASS: no empty lines in warden_intro")
		checks_passed += 1

	# ── Contains "purpose" and "three hundred" (tone anchors) ────────────────
	var full_text := " ".join(PackedStringArray(lines))
	if "purpose" in full_text.to_lower():
		print("PASS: warden_intro contains 'purpose' (tone anchor)")
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro should contain the word 'purpose'")
		checks_failed += 1

	if "three hundred" in full_text.to_lower():
		print("PASS: warden_intro contains 'three hundred' (lore anchor)")
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro should mention 'three hundred years'")
		checks_failed += 1

	# ── Last narrative action: "It moves." ────────────────────────────────────
	if lines.size() > 0 and str(lines[-1]).strip_edges().to_lower().begins_with("it moves"):
		print("PASS: warden_intro ends with 'It moves.' action beat")
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro should end with 'It moves.' (got '%s')" % str(lines[-1] if lines.size() > 0 else ""))
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 warden intro test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 warden intro test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
