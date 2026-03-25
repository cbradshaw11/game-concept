## M17 Test: Lore fragment content validation — all 5 fragments, ring coverage,
## no empty text fields (M17 T6)
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
	var fragments: Array = data.get("lore_fragments", [])

	# ── All 5 canonical fragment IDs present ─────────────────────────────────
	var expected_ids := ["fragment_001", "fragment_002", "fragment_003", "fragment_004", "fragment_005"]
	var found_ids: Array = []
	for frag in fragments:
		found_ids.append(str(frag.get("id", "")))

	for fid in expected_ids:
		if fid in found_ids:
			print("PASS: lore fragment '%s' present" % fid)
			checks_passed += 1
		else:
			printerr("FAIL: lore fragment '%s' missing" % fid)
			checks_failed += 1

	# ── Ring coverage: inner, mid, outer, sanctuary each appear at least once ──
	var ring_counts: Dictionary = {"inner": 0, "mid": 0, "outer": 0, "sanctuary": 0}
	for frag in fragments:
		var ring := str(frag.get("ring", ""))
		if ring_counts.has(ring):
			ring_counts[ring] += 1

	for ring_id in ring_counts:
		if ring_counts[ring_id] >= 1:
			print("PASS: ring '%s' represented in lore fragments" % ring_id)
			checks_passed += 1
		else:
			printerr("FAIL: ring '%s' has no lore fragments" % ring_id)
			checks_failed += 1

	# ── Each fragment: text is non-empty and > 50 chars ──────────────────────
	for frag in fragments:
		var fid := str(frag.get("id", "?"))
		var text := str(frag.get("text", ""))
		if text.strip_edges().length() > 50:
			print("PASS: fragment '%s' text has %d chars (> 50)" % [fid, text.length()])
			checks_passed += 1
		else:
			printerr("FAIL: fragment '%s' text too short (%d chars)" % [fid, text.length()])
			checks_failed += 1

	# ── Each fragment: title and author are non-empty ────────────────────────
	for frag in fragments:
		var fid := str(frag.get("id", "?"))
		var title := str(frag.get("title", "")).strip_edges()
		var author := str(frag.get("author", "")).strip_edges()
		if title.length() > 0 and author.length() > 0:
			print("PASS: fragment '%s' has title and author" % fid)
			checks_passed += 1
		else:
			printerr("FAIL: fragment '%s' missing title or author (title='%s' author='%s')" % [
				fid, title, author
			])
			checks_failed += 1

	# ── Fragment 005 is Genn's note in the sanctuary ─────────────────────────
	var frag005: Dictionary = {}
	for frag in fragments:
		if str(frag.get("id", "")) == "fragment_005":
			frag005 = frag
	if frag005.get("ring", "") == "sanctuary" and frag005.get("author", "") == "Genn":
		print("PASS: fragment_005 is Genn's sanctuary note")
		checks_passed += 1
	else:
		printerr("FAIL: fragment_005 should be ring=sanctuary, author=Genn")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 lore fragments test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 lore fragments test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
