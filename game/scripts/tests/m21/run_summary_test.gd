extends SceneTree
## M21 T5 — Run summary scene tests
## Validates:
## - Scene and script files exist
## - RunSummary class has expected structure
## - Header text correct for each outcome type
## - FlowUI wires run summary on extracted/died

func _init() -> void:
	var passed := 0
	var failed := 0

	# ── Scene file exists ────────────────────────────────────────────────────
	if FileAccess.file_exists("res://scenes/ui/run_summary.tscn"):
		print("PASS: run_summary.tscn exists")
		passed += 1
	else:
		printerr("FAIL: run_summary.tscn missing")
		failed += 1

	# ── Script file exists ───────────────────────────────────────────────────
	if FileAccess.file_exists("res://scripts/ui/run_summary.gd"):
		print("PASS: run_summary.gd exists")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing")
		failed += 1

	# ── Script has populate method ───────────────────────────────────────────
	var src := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")

	if "func populate(" in src:
		print("PASS: run_summary.gd has populate method")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing populate method")
		failed += 1

	# ── Header text for death ────────────────────────────────────────────────
	if '"RUN COMPLETE"' in src:
		print("PASS: run_summary.gd has RUN COMPLETE header for death")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing RUN COMPLETE header")
		failed += 1

	# ── Header text for extraction ───────────────────────────────────────────
	if '"EXTRACTED"' in src:
		print("PASS: run_summary.gd has EXTRACTED header")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing EXTRACTED header")
		failed += 1

	# ── Header text for artifact ─────────────────────────────────────────────
	if '"ARTIFACT RETRIEVED"' in src:
		print("PASS: run_summary.gd has ARTIFACT RETRIEVED header")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing ARTIFACT RETRIEVED header")
		failed += 1

	# ── Has return_to_sanctuary signal ───────────────────────────────────────
	if "signal return_to_sanctuary" in src:
		print("PASS: run_summary.gd has return_to_sanctuary signal")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing return_to_sanctuary signal")
		failed += 1

	# ── Has return_to_title signal ───────────────────────────────────────────
	if "signal return_to_title" in src:
		print("PASS: run_summary.gd has return_to_title signal")
		passed += 1
	else:
		printerr("FAIL: run_summary.gd missing return_to_title signal")
		failed += 1

	# ── FlowUI routes to run summary ────────────────────────────────────────
	var flow_src := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")

	if "_show_run_summary" in flow_src:
		print("PASS: flow_ui.gd has _show_run_summary method")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd missing _show_run_summary method")
		failed += 1

	if "RunSummaryScene" in flow_src:
		print("PASS: flow_ui.gd preloads RunSummaryScene")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd missing RunSummaryScene preload")
		failed += 1

	# ── on_extracted routes to run summary ──────────────────────────────────
	if '_show_run_summary("extraction")' in flow_src:
		print("PASS: on_extracted routes to run summary with extraction outcome")
		passed += 1
	else:
		printerr("FAIL: on_extracted should call _show_run_summary('extraction')")
		failed += 1

	# ── on_died routes to run summary ───────────────────────────────────────
	if '_show_run_summary("death")' in flow_src:
		print("PASS: on_died routes to run summary with death outcome")
		passed += 1
	else:
		printerr("FAIL: on_died should call _show_run_summary('death')")
		failed += 1

	# ── show_artifact_victory routes to run summary ─────────────────────────
	if '_show_run_summary("artifact")' in flow_src:
		print("PASS: show_artifact_victory routes to run summary")
		passed += 1
	else:
		printerr("FAIL: show_artifact_victory should call _show_run_summary('artifact')")
		failed += 1

	# ── Stats display includes key fields ───────────────────────────────────
	if "Enemies killed" in src and "Damage dealt" in src and "Damage taken" in src:
		print("PASS: run_summary displays enemies killed, damage dealt, damage taken")
		passed += 1
	else:
		printerr("FAIL: run_summary missing combat stats display")
		failed += 1

	if "Silver earned" in src and "Run duration" in src and "XP banked" in src:
		print("PASS: run_summary displays silver, duration, XP")
		passed += 1
	else:
		printerr("FAIL: run_summary missing silver/duration/XP display")
		failed += 1

	# ── All-time stats section ──────────────────────────────────────────────
	if "ALL-TIME STATS" in src and "Total runs" in src:
		print("PASS: run_summary has all-time stats section")
		passed += 1
	else:
		printerr("FAIL: run_summary missing all-time stats section")
		failed += 1

	# ── return_to_title_pressed signal in flow_ui ───────────────────────────
	if "signal return_to_title_pressed" in flow_src:
		print("PASS: flow_ui has return_to_title_pressed signal")
		passed += 1
	else:
		printerr("FAIL: flow_ui missing return_to_title_pressed signal")
		failed += 1

	# ── main.gd handles return to title ─────────────────────────────────────
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	if "_on_return_to_title" in main_src:
		print("PASS: main.gd has _on_return_to_title handler")
		passed += 1
	else:
		printerr("FAIL: main.gd missing _on_return_to_title handler")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if failed == 0:
		print("PASS: M21 run summary test (%d checks)" % passed)
	else:
		printerr("FAIL: M21 run summary test (%d failed, %d passed)" % [failed, passed])
	quit()
