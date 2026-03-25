extends SceneTree
## M21 T5 — Run stats tracking tests
## Validates:
## - current_run_stats resets on start_run
## - Stats increment correctly (enemies_killed, damage_dealt, damage_taken, silver)
## - Lifetime stats persist across save/load
## - total_runs / total_extractions / total_deaths increment on run end

func _init() -> void:
	var passed := 0
	var failed := 0

	var GameStateScript = load("res://autoload/game_state.gd")
	var gs = GameStateScript.new()

	# ── current_run_stats resets on start_run ────────────────────────────────
	gs.current_run_stats = {"enemies_killed": 5}
	gs.start_run(42, "inner")
	if int(gs.current_run_stats.get("enemies_killed", -1)) == 0:
		print("PASS: current_run_stats.enemies_killed resets to 0 on start_run")
		passed += 1
	else:
		printerr("FAIL: current_run_stats.enemies_killed should reset to 0, got %d" % int(gs.current_run_stats.get("enemies_killed", -1)))
		failed += 1

	if gs.current_run_stats.has("rings_cleared"):
		print("PASS: current_run_stats has rings_cleared array after start_run")
		passed += 1
	else:
		printerr("FAIL: current_run_stats missing rings_cleared after start_run")
		failed += 1

	if gs._run_start_time > 0.0:
		print("PASS: _run_start_time set on start_run")
		passed += 1
	else:
		printerr("FAIL: _run_start_time should be > 0 after start_run")
		failed += 1

	# ── record_enemy_killed increments ───────────────────────────────────────
	gs.record_enemy_killed()
	gs.record_enemy_killed()
	if int(gs.current_run_stats.get("enemies_killed", 0)) == 2:
		print("PASS: record_enemy_killed increments correctly")
		passed += 1
	else:
		printerr("FAIL: enemies_killed should be 2, got %d" % int(gs.current_run_stats.get("enemies_killed", 0)))
		failed += 1

	# ── record_damage_dealt increments ───────────────────────────────────────
	gs.record_damage_dealt(40)
	gs.record_damage_dealt(25)
	if int(gs.current_run_stats.get("damage_dealt", 0)) == 65:
		print("PASS: record_damage_dealt tracks cumulative damage")
		passed += 1
	else:
		printerr("FAIL: damage_dealt should be 65, got %d" % int(gs.current_run_stats.get("damage_dealt", 0)))
		failed += 1

	# ── record_damage_taken increments ───────────────────────────────────────
	gs.record_damage_taken(10)
	gs.record_damage_taken(8)
	if int(gs.current_run_stats.get("damage_taken", 0)) == 18:
		print("PASS: record_damage_taken tracks cumulative damage")
		passed += 1
	else:
		printerr("FAIL: damage_taken should be 18, got %d" % int(gs.current_run_stats.get("damage_taken", 0)))
		failed += 1

	# ── silver_earned tracked via add_unbanked ───────────────────────────────
	gs.add_unbanked(20, 12)
	if int(gs.current_run_stats.get("silver_earned", 0)) == 12:
		print("PASS: silver_earned tracked in add_unbanked")
		passed += 1
	else:
		printerr("FAIL: silver_earned should be 12, got %d" % int(gs.current_run_stats.get("silver_earned", 0)))
		failed += 1

	# ── record_silver_spent ──────────────────────────────────────────────────
	gs.record_silver_spent(5)
	if int(gs.current_run_stats.get("silver_spent", 0)) == 5:
		print("PASS: record_silver_spent tracks silver")
		passed += 1
	else:
		printerr("FAIL: silver_spent should be 5, got %d" % int(gs.current_run_stats.get("silver_spent", 0)))
		failed += 1

	# ── total_runs increments on extraction ──────────────────────────────────
	var prev_runs: int = gs.total_runs
	gs.extract()
	if gs.total_runs == prev_runs + 1:
		print("PASS: total_runs increments on extraction")
		passed += 1
	else:
		printerr("FAIL: total_runs should be %d, got %d" % [prev_runs + 1, gs.total_runs])
		failed += 1

	# ── total_extractions increments ─────────────────────────────────────────
	if gs.total_extractions == 1:
		print("PASS: total_extractions increments on extraction")
		passed += 1
	else:
		printerr("FAIL: total_extractions should be 1, got %d" % gs.total_extractions)
		failed += 1

	# ── total_deaths increments on die_in_run ────────────────────────────────
	gs.start_run(99, "mid")
	gs.add_unbanked(10, 5)
	gs.die_in_run()
	if gs.total_deaths == 1:
		print("PASS: total_deaths increments on die_in_run")
		passed += 1
	else:
		printerr("FAIL: total_deaths should be 1, got %d" % gs.total_deaths)
		failed += 1

	if gs.total_runs == prev_runs + 2:
		print("PASS: total_runs increments on death too")
		passed += 1
	else:
		printerr("FAIL: total_runs should be %d after death, got %d" % [prev_runs + 2, gs.total_runs])
		failed += 1

	# ── Save/load round-trip preserves lifetime stats ────────────────────────
	gs.total_runs = 10
	gs.total_extractions = 7
	gs.total_deaths = 3
	gs.deepest_ring_reached = "outer"
	gs.artifact_retrievals = 2
	gs.fastest_extraction_seconds = 45.5

	var state: Dictionary = gs.to_save_state()
	var gs2 = GameStateScript.new()
	gs2.apply_save_state(state)

	if gs2.total_runs == 10 and gs2.total_extractions == 7 and gs2.total_deaths == 3:
		print("PASS: lifetime run/extraction/death counts persist across save/load")
		passed += 1
	else:
		printerr("FAIL: lifetime counts not preserved: runs=%d ext=%d deaths=%d" % [gs2.total_runs, gs2.total_extractions, gs2.total_deaths])
		failed += 1

	if gs2.deepest_ring_reached == "outer" and gs2.artifact_retrievals == 2:
		print("PASS: deepest_ring_reached and artifact_retrievals persist")
		passed += 1
	else:
		printerr("FAIL: deepest_ring=%s artifacts=%d" % [gs2.deepest_ring_reached, gs2.artifact_retrievals])
		failed += 1

	if abs(gs2.fastest_extraction_seconds - 45.5) < 0.01:
		print("PASS: fastest_extraction_seconds persists across save/load")
		passed += 1
	else:
		printerr("FAIL: fastest_extraction_seconds should be 45.5, got %f" % gs2.fastest_extraction_seconds)
		failed += 1

	# ── v8 migration guard — missing fields default safely ───────────────────
	var gs3 = GameStateScript.new()
	gs3.apply_save_state({"banked_xp": 100})  # v7 save with no M21 fields
	if gs3.total_runs == 0 and gs3.deepest_ring_reached == "" and gs3.fastest_extraction_seconds == 0.0:
		print("PASS: v8 migration guard defaults M21 fields correctly")
		passed += 1
	else:
		printerr("FAIL: v8 migration guard not working")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	gs.free()
	gs2.free()
	gs3.free()
	if failed == 0:
		print("PASS: M21 run stats test (%d checks)" % passed)
	else:
		printerr("FAIL: M21 run stats test (%d failed, %d passed)" % [failed, passed])
	quit()
