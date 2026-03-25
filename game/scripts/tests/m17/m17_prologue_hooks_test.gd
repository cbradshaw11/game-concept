## M17 Test: Prologue sequence hooks into main.gd startup flow (M17 T9)
## Verifies that:
## - main.gd defines _has_seen_prologue() and _mark_prologue_seen()
## - flow_ui.gd defines show_prologue() and show_narrative_text()
## - NarrativeManager.get_prologue() returns the expected 3 beats
extends SceneTree

const NarrativeManagerScript = preload("res://autoload/narrative_manager.gd")

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── main.gd has prologue helper methods ───────────────────────────────────
	var main_script := load("res://scripts/main.gd")
	if main_script == null:
		printerr("FAIL: could not load res://scripts/main.gd")
		quit(1)
		return

	# We check by instantiating (SceneTree context) — method existence test
	# We do this by inspecting source text directly
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_src := ""
	if main_file != null:
		main_src = main_file.get_as_text()
		main_file.close()

	for method_name in ["_has_seen_prologue", "_mark_prologue_seen", "get_vendor_greeting", "get_vendor_purchase_line"]:
		if method_name in main_src:
			print("PASS: main.gd defines '%s'" % method_name)
			checks_passed += 1
		else:
			printerr("FAIL: main.gd missing method '%s'" % method_name)
			checks_failed += 1

	# ── main.gd calls NarrativeManager.get_prologue() in _ready ──────────────
	if "NarrativeManager.get_prologue" in main_src:
		print("PASS: main.gd calls NarrativeManager.get_prologue() in startup flow")
		checks_passed += 1
	else:
		printerr("FAIL: main.gd should call NarrativeManager.get_prologue() in _ready")
		checks_failed += 1

	# ── main.gd calls NarrativeManager.get_ring_text for ring entry ──────────
	if "NarrativeManager.get_ring_text" in main_src:
		print("PASS: main.gd calls NarrativeManager.get_ring_text() for ring entry")
		checks_passed += 1
	else:
		printerr("FAIL: main.gd should call NarrativeManager.get_ring_text() in _begin_run")
		checks_failed += 1

	# ── flow_ui.gd has show_prologue and show_narrative_text ─────────────────
	var flow_file := FileAccess.open("res://scripts/ui/flow_ui.gd", FileAccess.READ)
	var flow_src := ""
	if flow_file != null:
		flow_src = flow_file.get_as_text()
		flow_file.close()

	for method_name in ["show_prologue", "show_narrative_text"]:
		if method_name in flow_src:
			print("PASS: flow_ui.gd defines '%s'" % method_name)
			checks_passed += 1
		else:
			printerr("FAIL: flow_ui.gd missing method '%s'" % method_name)
			checks_failed += 1

	# ── NarrativeManager autoload registered in project.godot ────────────────
	var proj_file := FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_src := ""
	if proj_file != null:
		proj_src = proj_file.get_as_text()
		proj_file.close()

	if "NarrativeManager" in proj_src:
		print("PASS: NarrativeManager registered in project.godot autoloads")
		checks_passed += 1
	else:
		printerr("FAIL: NarrativeManager not found in project.godot autoloads")
		checks_failed += 1

	# ── NarrativeManager loads data and returns 3-beat prologue ──────────────
	var gs_stub := _make_game_state_stub()
	root.add_child(gs_stub)
	var nm := NarrativeManagerScript.new()
	nm.name = "NarrativeManager"
	root.add_child(nm)
	nm._ready()

	var prologue := nm.get_prologue()
	if typeof(prologue) == TYPE_ARRAY and prologue.size() == 3:
		print("PASS: NarrativeManager.get_prologue() returns 3 beats")
		checks_passed += 1
	else:
		printerr("FAIL: NarrativeManager.get_prologue() should return 3 beats")
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M17 prologue hooks test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M17 prologue hooks test (%d failed, %d passed)" % [
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
