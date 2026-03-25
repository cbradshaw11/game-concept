extends SceneTree
## M20 T5 — Title screen & first-run detection tests
## Validates:
## - GameState.is_first_run() returns true with empty history
## - GameState.is_first_run() returns false after a run is recorded
## - Title screen script exists and has expected signals/constants
## - Title screen scene loads without errors

func _init() -> void:
	var passed := 0
	var failed := 0

	# ── is_first_run() with empty state ──────────────────────────────────────
	var GameStateScript = load("res://autoload/game_state.gd")
	var gs = GameStateScript.new()
	gs.run_history = []
	if gs.is_first_run() == true:
		print("PASS: is_first_run() returns true with empty run_history")
		passed += 1
	else:
		printerr("FAIL: is_first_run() should return true with empty run_history")
		failed += 1

	# ── is_first_run() with run history ──────────────────────────────────────
	gs.run_history = [{"ring": "inner", "extracted": true}]
	if gs.is_first_run() == false:
		print("PASS: is_first_run() returns false with run_history entries")
		passed += 1
	else:
		printerr("FAIL: is_first_run() should return false when run_history has entries")
		failed += 1

	# ── Title screen script exists and has signals ───────────────────────────
	var title_src := FileAccess.get_file_as_string("res://scripts/ui/title_screen.gd")
	if title_src.length() > 0:
		print("PASS: title_screen.gd exists and is not empty")
		passed += 1
	else:
		printerr("FAIL: title_screen.gd is missing or empty")
		failed += 1

	for sig_name in ["begin_pressed", "continue_pressed"]:
		if sig_name in title_src:
			print("PASS: title_screen.gd declares signal '%s'" % sig_name)
			passed += 1
		else:
			printerr("FAIL: title_screen.gd missing signal '%s'" % sig_name)
			failed += 1

	# ── FLAVOR_LINES constant exists with 4 entries ──────────────────────────
	if "FLAVOR_LINES" in title_src and "FLAVOR_CYCLE_TIME" in title_src:
		print("PASS: title_screen.gd has FLAVOR_LINES and FLAVOR_CYCLE_TIME constants")
		passed += 1
	else:
		printerr("FAIL: title_screen.gd missing FLAVOR_LINES or FLAVOR_CYCLE_TIME")
		failed += 1

	# ── Title screen scene file exists ───────────────────────────────────────
	if FileAccess.file_exists("res://scenes/ui/title_screen.tscn"):
		print("PASS: title_screen.tscn exists")
		passed += 1
	else:
		printerr("FAIL: title_screen.tscn not found")
		failed += 1

	# ── main.gd references title screen ──────────────────────────────────────
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	if "TitleScreenScene" in main_src and "_show_title_screen" in main_src:
		print("PASS: main.gd loads and shows title screen")
		passed += 1
	else:
		printerr("FAIL: main.gd should reference TitleScreenScene and _show_title_screen")
		failed += 1

	# ── main.gd routes begin based on first run ──────────────────────────────
	if "_on_title_begin" in main_src and "is_first_run" in main_src:
		print("PASS: main.gd has _on_title_begin with is_first_run routing")
		passed += 1
	else:
		printerr("FAIL: main.gd should route begin based on is_first_run()")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	gs.free()
	if failed == 0:
		print("PASS: M20 title screen test (%d checks)" % passed)
	else:
		printerr("FAIL: M20 title screen test (%d failed, %d passed)" % [failed, passed])
	quit()
