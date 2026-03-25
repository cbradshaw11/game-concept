## M17 Test: NarrativeManager loads narrative.json and exposes data (M17 T8)
extends SceneTree

const NarrativeManagerScript = preload("res://autoload/narrative_manager.gd")

func _initialize() -> void:
	var nm := NarrativeManagerScript.new()
	nm.name = "NarrativeManager"
	# Inject a minimal GameState stub so _get_entry_text doesn't crash
	var gs_stub := _make_game_state_stub()
	root.add_child(gs_stub)
	root.add_child(nm)
	nm._ready()

	var checks_passed := 0
	var checks_failed := 0

	# ── is_loaded returns true after a valid JSON file ────────────────────────
	if nm.is_loaded():
		print("PASS: NarrativeManager reports loaded after _ready()")
		checks_passed += 1
	else:
		printerr("FAIL: NarrativeManager.is_loaded() returned false — check narrative.json path")
		checks_failed += 1

	# ── get_prologue returns Array with 3 beats ───────────────────────────────
	var prologue := nm.get_prologue()
	if typeof(prologue) == TYPE_ARRAY and prologue.size() == 3:
		print("PASS: get_prologue() returns 3 beats")
		checks_passed += 1
	else:
		printerr("FAIL: get_prologue() should return Array of 3 beats, got %s size %d" % [
			typeof(prologue), prologue.size() if typeof(prologue) == TYPE_ARRAY else -1
		])
		checks_failed += 1

	# ── Each prologue beat has id, beat (int), type, lines (Array) ────────────
	for beat in prologue:
		var beat_id := str(beat.get("id", ""))
		if beat_id == "":
			printerr("FAIL: prologue beat missing 'id' field")
			checks_failed += 1
			continue
		if typeof(beat.get("beat")) != TYPE_FLOAT and typeof(beat.get("beat")) != TYPE_INT:
			printerr("FAIL: prologue beat '%s' missing numeric 'beat' field" % beat_id)
			checks_failed += 1
			continue
		var beat_lines: Array = beat.get("lines", [])
		if typeof(beat_lines) == TYPE_ARRAY and beat_lines.size() >= 1:
			print("PASS: prologue beat '%s' has %d lines" % [beat_id, beat_lines.size()])
			checks_passed += 1
		else:
			printerr("FAIL: prologue beat '%s' should have at least 1 line" % beat_id)
			checks_failed += 1

	# ── Prologue beat 2 has choices Array ────────────────────────────────────
	var beat2: Dictionary = {}
	for beat in prologue:
		if int(beat.get("beat", 0)) == 2:
			beat2 = beat
	if not beat2.is_empty():
		var choices: Array = beat2.get("choices", [])
		if choices.size() == 3:
			print("PASS: prologue beat 2 has 3 dialogue choices")
			checks_passed += 1
		else:
			printerr("FAIL: prologue beat 2 should have 3 choices, got %d" % choices.size())
			checks_failed += 1
	else:
		printerr("FAIL: could not find prologue beat 2")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 narrative manager load test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 narrative manager load test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)

func _make_game_state_stub() -> Node:
	var stub := Node.new()
	stub.name = "GameState"
	# Expose has_extracted_from as a method stub via script
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
