## M17 Test: narrative.json structure validation (M17 T1-T7 data completeness)
extends SceneTree

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── Load and parse narrative.json directly ────────────────────────────────
	var file := FileAccess.open("res://data/narrative.json", FileAccess.READ)
	if file == null:
		printerr("FAIL: could not open res://data/narrative.json")
		quit(1)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		printerr("FAIL: JSON parse error in narrative.json (line %d): %s" % [
			json.get_error_line(), json.get_error_message()
		])
		quit(1)
		return

	var data: Dictionary = json.get_data()

	# ── Top-level keys present ────────────────────────────────────────────────
	var required_keys := ["prologue", "ring_entry", "npc_dialogue", "death_flavor",
		"extraction_flavor", "lore_fragments", "warden_intro"]
	for key in required_keys:
		if data.has(key):
			print("PASS: narrative.json has top-level key '%s'" % key)
			checks_passed += 1
		else:
			printerr("FAIL: narrative.json missing top-level key '%s'" % key)
			checks_failed += 1

	# ── ring_entry covers all rings ───────────────────────────────────────────
	var ring_entry: Dictionary = data.get("ring_entry", {})
	for ring_id in ["sanctuary", "inner", "mid", "outer"]:
		if ring_entry.has(ring_id):
			print("PASS: ring_entry has '%s'" % ring_id)
			checks_passed += 1
		else:
			printerr("FAIL: ring_entry missing '%s'" % ring_id)
			checks_failed += 1

	# ── sanctuary.return has at least 3 lines ────────────────────────────────
	var sanctuary_return: Array = ring_entry.get("sanctuary", {}).get("return", [])
	if sanctuary_return.size() >= 3:
		print("PASS: sanctuary.return has %d lines (>= 3)" % sanctuary_return.size())
		checks_passed += 1
	else:
		printerr("FAIL: sanctuary.return should have >= 3 lines, got %d" % sanctuary_return.size())
		checks_failed += 1

	# ── Each ring has 'first' entry text ─────────────────────────────────────
	for ring_id in ["inner", "mid", "outer"]:
		var ring_data: Dictionary = ring_entry.get(ring_id, {})
		var first_lines: Array = ring_data.get("first", [])
		if first_lines.size() >= 1:
			print("PASS: ring_entry.%s.first has %d line(s)" % [ring_id, first_lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: ring_entry.%s.first should have >= 1 line, got %d" % [
				ring_id, first_lines.size()
			])
			checks_failed += 1

	# ── death_flavor covers inner, mid, outer ────────────────────────────────
	var death_flavor: Dictionary = data.get("death_flavor", {})
	for ring_id in ["inner", "mid", "outer"]:
		var lines: Array = death_flavor.get(ring_id, [])
		if lines.size() >= 3:
			print("PASS: death_flavor.%s has %d lines (>= 3)" % [ring_id, lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: death_flavor.%s should have >= 3 lines, got %d" % [
				ring_id, lines.size()
			])
			checks_failed += 1

	# ── extraction_flavor covers inner, mid, outer ───────────────────────────
	var extraction_flavor: Dictionary = data.get("extraction_flavor", {})
	for ring_id in ["inner", "mid", "outer"]:
		var lines: Array = extraction_flavor.get(ring_id, [])
		if lines.size() >= 2:
			print("PASS: extraction_flavor.%s has %d lines (>= 2)" % [ring_id, lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: extraction_flavor.%s should have >= 2 lines, got %d" % [
				ring_id, lines.size()
			])
			checks_failed += 1

	# ── extraction_flavor has 'artifact' key ─────────────────────────────────
	var artifact_lines: Array = extraction_flavor.get("artifact", [])
	if artifact_lines.size() >= 1:
		print("PASS: extraction_flavor.artifact has %d line(s)" % artifact_lines.size())
		checks_passed += 1
	else:
		printerr("FAIL: extraction_flavor.artifact should have >= 1 line")
		checks_failed += 1

	# ── npc_dialogue has genn_vendor ─────────────────────────────────────────
	var npc_dialogue: Dictionary = data.get("npc_dialogue", {})
	var genn: Dictionary = npc_dialogue.get("genn_vendor", {})
	if not genn.is_empty():
		print("PASS: npc_dialogue.genn_vendor present")
		checks_passed += 1
	else:
		printerr("FAIL: npc_dialogue.genn_vendor missing")
		checks_failed += 1

	# ── genn_vendor has required pools ───────────────────────────────────────
	for pool in ["greeting", "after_first_death", "on_purchase", "on_browse_no_purchase"]:
		var pool_lines: Array = genn.get(pool, [])
		if pool_lines.size() >= 1:
			print("PASS: genn_vendor.%s has %d line(s)" % [pool, pool_lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: genn_vendor.%s should have >= 1 line" % pool)
			checks_failed += 1

	# ── lore_fragments has 5 entries with required fields ────────────────────
	var fragments: Array = data.get("lore_fragments", [])
	if fragments.size() >= 5:
		print("PASS: lore_fragments has %d entries (>= 5)" % fragments.size())
		checks_passed += 1
	else:
		printerr("FAIL: lore_fragments should have >= 5 entries, got %d" % fragments.size())
		checks_failed += 1

	var fragment_fields := ["id", "title", "author", "ring", "text"]
	for fragment in fragments:
		for field in fragment_fields:
			if fragment.has(field) and str(fragment.get(field, "")).strip_edges() != "":
				checks_passed += 1
			else:
				printerr("FAIL: lore fragment '%s' missing or empty field '%s'" % [
					str(fragment.get("id", "?")), field
				])
				checks_failed += 1

	# ── warden_intro has at least 4 lines ────────────────────────────────────
	var warden: Dictionary = data.get("warden_intro", {})
	var warden_lines: Array = warden.get("lines", [])
	if warden_lines.size() >= 4:
		print("PASS: warden_intro has %d lines (>= 4)" % warden_lines.size())
		checks_passed += 1
	else:
		printerr("FAIL: warden_intro.lines should have >= 4 entries, got %d" % warden_lines.size())
		checks_failed += 1

	# ── No empty strings in any narrative pool ────────────────────────────────
	var empty_found := false
	for key in data:
		_check_no_empty_strings(data[key], key, checks_passed, checks_failed, empty_found)
	if not empty_found:
		print("PASS: no empty strings found in top-level narrative pools (checked recursively)")
		checks_passed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 narrative JSON structure test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 narrative JSON structure test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)

func _check_no_empty_strings(value: Variant, path: String, passed: int, failed: int, found: bool) -> void:
	match typeof(value):
		TYPE_STRING:
			if str(value).strip_edges() == "":
				printerr("FAIL: empty string at '%s'" % path)
				found = true
		TYPE_ARRAY:
			var i := 0
			for item in value:
				_check_no_empty_strings(item, "%s[%d]" % [path, i], passed, failed, found)
				i += 1
		TYPE_DICTIONARY:
			for k in value:
				_check_no_empty_strings(value[k], "%s.%s" % [path, str(k)], passed, failed, found)
