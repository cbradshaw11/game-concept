## M17 Test: NarrativeManager API — get_ring_text, get_npc_line, get_lore_fragment,
## get_warden_intro, get_prologue (M17 T8 API surface)
extends SceneTree

const NarrativeManagerScript = preload("res://autoload/narrative_manager.gd")

func _initialize() -> void:
	# Inject GameState stub
	var gs_stub := _make_game_state_stub()
	root.add_child(gs_stub)

	var nm := NarrativeManagerScript.new()
	nm.name = "NarrativeManager"
	root.add_child(nm)
	nm._ready()

	var checks_passed := 0
	var checks_failed := 0

	# ── get_ring_text — entry ─────────────────────────────────────────────────
	for ring_id in ["inner", "mid", "outer", "sanctuary"]:
		var text := nm.get_ring_text(ring_id, "entry")
		if typeof(text) == TYPE_STRING and text.length() > 0:
			print("PASS: get_ring_text('%s', 'entry') returns non-empty string" % ring_id)
			checks_passed += 1
		else:
			printerr("FAIL: get_ring_text('%s', 'entry') returned empty/invalid" % ring_id)
			checks_failed += 1

	# ── get_ring_text — death ─────────────────────────────────────────────────
	for ring_id in ["inner", "mid", "outer"]:
		var text := nm.get_ring_text(ring_id, "death")
		if typeof(text) == TYPE_STRING and text.length() > 0:
			print("PASS: get_ring_text('%s', 'death') returns non-empty string" % ring_id)
			checks_passed += 1
		else:
			printerr("FAIL: get_ring_text('%s', 'death') returned empty/invalid" % ring_id)
			checks_failed += 1

	# ── get_ring_text — extraction ────────────────────────────────────────────
	for ring_id in ["inner", "mid", "outer"]:
		var text := nm.get_ring_text(ring_id, "extraction")
		if typeof(text) == TYPE_STRING and text.length() > 0:
			print("PASS: get_ring_text('%s', 'extraction') returns non-empty string" % ring_id)
			checks_passed += 1
		else:
			printerr("FAIL: get_ring_text('%s', 'extraction') returned empty/invalid" % ring_id)
			checks_failed += 1

	# ── get_ring_text — unknown event type returns "" ─────────────────────────
	var unknown_text := nm.get_ring_text("inner", "totally_fake_event")
	if unknown_text == "":
		print("PASS: get_ring_text returns '' for unknown event_type")
		checks_passed += 1
	else:
		printerr("FAIL: get_ring_text should return '' for unknown event_type")
		checks_failed += 1

	# ── get_npc_line — genn_vendor ────────────────────────────────────────────
	var genn_line := nm.get_npc_line("genn_vendor")
	if typeof(genn_line) == TYPE_STRING and genn_line.length() > 0:
		print("PASS: get_npc_line('genn_vendor') returns non-empty string")
		checks_passed += 1
	else:
		printerr("FAIL: get_npc_line('genn_vendor') returned empty/invalid")
		checks_failed += 1

	# ── get_npc_line — unknown NPC returns "" ────────────────────────────────
	var unknown_npc := nm.get_npc_line("doesnt_exist_npc")
	if unknown_npc == "":
		print("PASS: get_npc_line returns '' for unknown NPC")
		checks_passed += 1
	else:
		printerr("FAIL: get_npc_line should return '' for unknown NPC")
		checks_failed += 1

	# ── get_genn_vendor_reaction — purchase ───────────────────────────────────
	var purchase_line := nm.get_genn_vendor_reaction("purchase")
	if typeof(purchase_line) == TYPE_STRING and purchase_line.length() > 0:
		print("PASS: get_genn_vendor_reaction('purchase') returns non-empty string")
		checks_passed += 1
	else:
		printerr("FAIL: get_genn_vendor_reaction('purchase') returned empty/invalid")
		checks_failed += 1

	# ── get_genn_vendor_reaction — browse ─────────────────────────────────────
	var browse_line := nm.get_genn_vendor_reaction("browse")
	if typeof(browse_line) == TYPE_STRING and browse_line.length() > 0:
		print("PASS: get_genn_vendor_reaction('browse') returns non-empty string")
		checks_passed += 1
	else:
		printerr("FAIL: get_genn_vendor_reaction('browse') returned empty/invalid")
		checks_failed += 1

	# ── get_lore_fragment — by id ─────────────────────────────────────────────
	var frag := nm.get_lore_fragment("fragment_001")
	if typeof(frag) == TYPE_DICTIONARY and not frag.is_empty():
		print("PASS: get_lore_fragment('fragment_001') returns non-empty Dict")
		checks_passed += 1
	else:
		printerr("FAIL: get_lore_fragment('fragment_001') returned empty/invalid")
		checks_failed += 1

	# ── get_lore_fragment — random (id == "") ─────────────────────────────────
	var rand_frag := nm.get_lore_fragment("")
	if typeof(rand_frag) == TYPE_DICTIONARY and not rand_frag.is_empty():
		print("PASS: get_lore_fragment('') returns a random fragment")
		checks_passed += 1
	else:
		printerr("FAIL: get_lore_fragment('') should return a random fragment")
		checks_failed += 1

	# ── get_lore_fragment — unknown id returns {} ─────────────────────────────
	var missing_frag := nm.get_lore_fragment("no_such_id_xyz")
	if typeof(missing_frag) == TYPE_DICTIONARY and missing_frag.is_empty():
		print("PASS: get_lore_fragment returns {} for unknown id")
		checks_passed += 1
	else:
		printerr("FAIL: get_lore_fragment should return {} for unknown id")
		checks_failed += 1

	# ── get_all_lore_fragment_ids ─────────────────────────────────────────────
	var ids := nm.get_all_lore_fragment_ids()
	if typeof(ids) == TYPE_ARRAY and ids.size() >= 5 and "fragment_001" in ids:
		print("PASS: get_all_lore_fragment_ids returns >= 5 IDs including 'fragment_001'")
		checks_passed += 1
	else:
		printerr("FAIL: get_all_lore_fragment_ids returned unexpected result: %s" % str(ids))
		checks_failed += 1

	# ── get_warden_intro ──────────────────────────────────────────────────────
	var warden := nm.get_warden_intro()
	if typeof(warden) == TYPE_ARRAY and warden.size() >= 4:
		print("PASS: get_warden_intro() returns >= 4 lines")
		checks_passed += 1
	else:
		printerr("FAIL: get_warden_intro() should return Array with >= 4 lines, got %s" % str(warden))
		checks_failed += 1

	# ── get_prologue ──────────────────────────────────────────────────────────
	var prologue := nm.get_prologue()
	if typeof(prologue) == TYPE_ARRAY and prologue.size() == 3:
		print("PASS: get_prologue() returns 3 beats")
		checks_passed += 1
	else:
		printerr("FAIL: get_prologue() should return Array of 3 beats")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 narrative API test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 narrative API test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)

func _make_game_state_stub() -> Node:
	var stub := Node.new()
	stub.name = "GameState"
	var script := GDScript.new()
	script.source_code = """
extends Node
var run_history: Array = []
var active_seed: int = 0
func has_extracted_from(_ring_id: String) -> bool:
	return false
"""
	stub.set_script(script)
	return stub
