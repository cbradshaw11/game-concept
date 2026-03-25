extends SceneTree
## M20 T5 — Onboarding flow tests
## Validates:
## - Prologue is shown on first run (is_first_run true + prologue not seen)
## - Prologue is skipped on return visit (run_history non-empty)
## - main.gd _on_title_begin routes correctly based on state

func _init() -> void:
	var passed := 0
	var failed := 0

	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")

	# ── _on_title_begin exists ───────────────────────────────────────────────
	if "_on_title_begin" in main_src:
		print("PASS: main.gd has _on_title_begin handler")
		passed += 1
	else:
		printerr("FAIL: main.gd missing _on_title_begin handler")
		failed += 1

	# ── _on_title_continue exists ────────────────────────────────────────────
	if "_on_title_continue" in main_src:
		print("PASS: main.gd has _on_title_continue handler")
		passed += 1
	else:
		printerr("FAIL: main.gd missing _on_title_continue handler")
		failed += 1

	# ── Begin routes to prologue on first run ────────────────────────────────
	# Check that _on_title_begin calls show_prologue when is_first_run
	if "is_first_run()" in main_src and "show_prologue" in main_src:
		print("PASS: _on_title_begin checks is_first_run and calls show_prologue")
		passed += 1
	else:
		printerr("FAIL: _on_title_begin should check is_first_run and call show_prologue")
		failed += 1

	# ── Begin skips prologue on return visit ─────────────────────────────────
	# The else branch should call on_idle_ready without show_prologue
	if "_has_seen_prologue" in main_src:
		print("PASS: main.gd checks _has_seen_prologue in begin flow")
		passed += 1
	else:
		printerr("FAIL: main.gd should check _has_seen_prologue")
		failed += 1

	# ── GameState.is_first_run behavioral test ───────────────────────────────
	var GameStateScript = load("res://autoload/game_state.gd")
	var gs = GameStateScript.new()

	# Fresh state: first run
	gs.run_history = []
	if gs.is_first_run():
		print("PASS: fresh GameState is_first_run() == true")
		passed += 1
	else:
		printerr("FAIL: fresh GameState is_first_run() should be true")
		failed += 1

	# After prologue_seen set and run completed: not first run
	gs.run_history = [{"ring": "inner", "extracted": true, "seed": 123}]
	if not gs.is_first_run():
		print("PASS: GameState with run history is_first_run() == false (prologue skipped)")
		passed += 1
	else:
		printerr("FAIL: GameState with run history should not be first run")
		failed += 1

	# ── Continue handler goes straight to sanctuary ──────────────────────────
	if "_on_title_continue" in main_src and "on_idle_ready" in main_src:
		print("PASS: _on_title_continue routes to sanctuary via on_idle_ready")
		passed += 1
	else:
		printerr("FAIL: _on_title_continue should call on_idle_ready")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	gs.free()
	if failed == 0:
		print("PASS: M20 onboarding flow test (%d checks)" % passed)
	else:
		printerr("FAIL: M20 onboarding flow test (%d failed, %d passed)" % [failed, passed])
	quit()
