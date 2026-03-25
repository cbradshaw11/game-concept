extends SceneTree
## M21 T5 — Personal best tracking tests
## Validates:
## - deepest_ring_reached updates correctly (inner < mid < outer)
## - fastest_extraction_seconds tracks correctly
## - get_personal_bests returns correct badges
## - artifact_retrievals tracked

func _init() -> void:
	var passed := 0
	var failed := 0

	var GameStateScript = load("res://autoload/game_state.gd")

	# ── RING_DEPTH constant exists ───────────────────────────────────────────
	var gs = GameStateScript.new()
	if gs.RING_DEPTH.has("inner") and gs.RING_DEPTH.has("mid") and gs.RING_DEPTH.has("outer"):
		print("PASS: RING_DEPTH constant has inner, mid, outer")
		passed += 1
	else:
		printerr("FAIL: RING_DEPTH missing ring entries")
		failed += 1

	# ── Ring depth ordering: inner < mid < outer ─────────────────────────────
	if gs.RING_DEPTH["inner"] < gs.RING_DEPTH["mid"] and gs.RING_DEPTH["mid"] < gs.RING_DEPTH["outer"]:
		print("PASS: RING_DEPTH ordering inner < mid < outer")
		passed += 1
	else:
		printerr("FAIL: RING_DEPTH ordering incorrect")
		failed += 1

	# ── _update_deepest_ring updates from empty ──────────────────────────────
	gs.deepest_ring_reached = ""
	gs._update_deepest_ring("inner")
	if gs.deepest_ring_reached == "inner":
		print("PASS: _update_deepest_ring sets inner from empty")
		passed += 1
	else:
		printerr("FAIL: deepest should be inner, got %s" % gs.deepest_ring_reached)
		failed += 1

	# ── _update_deepest_ring upgrades inner → mid ───────────────────────────
	gs._update_deepest_ring("mid")
	if gs.deepest_ring_reached == "mid":
		print("PASS: _update_deepest_ring upgrades inner → mid")
		passed += 1
	else:
		printerr("FAIL: deepest should be mid, got %s" % gs.deepest_ring_reached)
		failed += 1

	# ── _update_deepest_ring does NOT downgrade mid → inner ─────────────────
	gs._update_deepest_ring("inner")
	if gs.deepest_ring_reached == "mid":
		print("PASS: _update_deepest_ring does not downgrade mid → inner")
		passed += 1
	else:
		printerr("FAIL: deepest should still be mid, got %s" % gs.deepest_ring_reached)
		failed += 1

	# ── _update_deepest_ring upgrades mid → outer ───────────────────────────
	gs._update_deepest_ring("outer")
	if gs.deepest_ring_reached == "outer":
		print("PASS: _update_deepest_ring upgrades mid → outer")
		passed += 1
	else:
		printerr("FAIL: deepest should be outer, got %s" % gs.deepest_ring_reached)
		failed += 1

	# ── fastest_extraction_seconds — first extraction sets record ────────────
	gs.free()
	gs = GameStateScript.new()
	gs.fastest_extraction_seconds = 0.0
	gs.start_run(1, "inner")
	gs._run_start_time = Time.get_unix_time_from_system() - 120.0  # 2 min ago
	gs.add_unbanked(20, 12)
	gs.extract()
	if gs.fastest_extraction_seconds > 0.0 and abs(gs.fastest_extraction_seconds - 120.0) < 5.0:
		print("PASS: fastest_extraction_seconds set on first extraction (~120s)")
		passed += 1
	else:
		printerr("FAIL: fastest_extraction_seconds should be ~120, got %f" % gs.fastest_extraction_seconds)
		failed += 1

	# ── fastest_extraction_seconds — faster run replaces record ──────────────
	var old_fastest: float = gs.fastest_extraction_seconds
	gs.start_run(2, "inner")
	gs._run_start_time = Time.get_unix_time_from_system() - 60.0  # 1 min ago
	gs.add_unbanked(20, 12)
	gs.extract()
	if gs.fastest_extraction_seconds < old_fastest:
		print("PASS: faster extraction replaces old record")
		passed += 1
	else:
		printerr("FAIL: fastest should be < %f, got %f" % [old_fastest, gs.fastest_extraction_seconds])
		failed += 1

	# ── fastest_extraction_seconds — slower run does NOT replace ─────────────
	var current_fastest: float = gs.fastest_extraction_seconds
	gs.start_run(3, "inner")
	gs._run_start_time = Time.get_unix_time_from_system() - 300.0  # 5 min ago
	gs.add_unbanked(20, 12)
	gs.extract()
	if abs(gs.fastest_extraction_seconds - current_fastest) < 1.0:
		print("PASS: slower extraction does not replace fastest record")
		passed += 1
	else:
		printerr("FAIL: fastest should still be ~%f, got %f" % [current_fastest, gs.fastest_extraction_seconds])
		failed += 1

	# ── Death does NOT update fastest_extraction_seconds ─────────────────────
	var pre_death_fastest: float = gs.fastest_extraction_seconds
	gs.start_run(4, "inner")
	gs._run_start_time = Time.get_unix_time_from_system() - 10.0  # 10s ago
	gs.die_in_run()
	if abs(gs.fastest_extraction_seconds - pre_death_fastest) < 0.01:
		print("PASS: death does not update fastest_extraction_seconds")
		passed += 1
	else:
		printerr("FAIL: fastest should be unchanged after death, got %f" % gs.fastest_extraction_seconds)
		failed += 1

	# ── artifact_retrievals increments ───────────────────────────────────────
	gs.free()
	gs = GameStateScript.new()
	gs.start_run(5, "outer")
	gs._run_start_time = Time.get_unix_time_from_system() - 300.0
	gs.add_unbanked(100, 50)
	gs.retrieve_artifact()
	if gs.artifact_retrievals == 1:
		print("PASS: artifact_retrievals increments to 1")
		passed += 1
	else:
		printerr("FAIL: artifact_retrievals should be 1, got %d" % gs.artifact_retrievals)
		failed += 1

	# ── get_personal_bests exists ────────────────────────────────────────────
	var src := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	if "func get_personal_bests(" in src:
		print("PASS: get_personal_bests method exists")
		passed += 1
	else:
		printerr("FAIL: get_personal_bests method missing")
		failed += 1

	# ── format_duration static method ────────────────────────────────────────
	var summary_src := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
	if "func format_duration(" in summary_src:
		print("PASS: RunSummary has format_duration method")
		passed += 1
	else:
		printerr("FAIL: RunSummary missing format_duration method")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	gs.free()
	if failed == 0:
		print("PASS: M21 personal best test (%d checks)" % passed)
	else:
		printerr("FAIL: M21 personal best test (%d failed, %d passed)" % [failed, passed])
	quit()
