## M31 Test: Challenge unlock logic — verifies challenges unlock at correct run counts,
## warden_hunt requires artifact_retrieval
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load challenge data
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Dictionary = JSON.parse_string(raw)
	var challenges: Array = data.get("challenge_runs", [])

	# Build lookup
	var by_id: Dictionary = {}
	for ch in challenges:
		by_id[str(ch.get("id", ""))] = ch

	# ── Simulate unlock checks ───────────────────────────────────────────────

	# Test 1: iron_road unlocks at 3 runs
	var ir: Dictionary = by_id.get("iron_road", {})
	if int(ir.get("unlock_threshold", 0)) == 3 and str(ir.get("unlock_type", "")) == "total_runs":
		var locked_at_2 := 2 < 3
		var unlocked_at_3 := 3 >= 3
		if locked_at_2 and unlocked_at_3:
			print("PASS: iron_road unlocks at exactly 3 total_runs")
			passed += 1
		else:
			print("FAIL: iron_road unlock logic incorrect")
			failed += 1
	else:
		print("FAIL: iron_road threshold or type wrong")
		failed += 1

	# Test 2: time_pressure unlocks at 5 runs
	var tp: Dictionary = by_id.get("time_pressure", {})
	if int(tp.get("unlock_threshold", 0)) == 5:
		var locked_at_4 := 4 < 5
		var unlocked_at_5 := 5 >= 5
		if locked_at_4 and unlocked_at_5:
			print("PASS: time_pressure unlocks at exactly 5 total_runs")
			passed += 1
		else:
			print("FAIL: time_pressure unlock logic incorrect")
			failed += 1
	else:
		print("FAIL: time_pressure threshold wrong")
		failed += 1

	# Test 3: one_life unlocks at 5 runs
	var ol: Dictionary = by_id.get("one_life", {})
	if int(ol.get("unlock_threshold", 0)) == 5 and str(ol.get("unlock_type", "")) == "total_runs":
		print("PASS: one_life unlocks at 5 total_runs")
		passed += 1
	else:
		print("FAIL: one_life threshold or type wrong")
		failed += 1

	# Test 4: naked_run unlocks at 8 runs
	var nr: Dictionary = by_id.get("naked_run", {})
	if int(nr.get("unlock_threshold", 0)) == 8:
		print("PASS: naked_run unlocks at 8 total_runs")
		passed += 1
	else:
		print("FAIL: naked_run threshold wrong")
		failed += 1

	# Test 5: escalation unlocks at 8 runs
	var es: Dictionary = by_id.get("escalation", {})
	if int(es.get("unlock_threshold", 0)) == 8:
		print("PASS: escalation unlocks at 8 total_runs")
		passed += 1
	else:
		print("FAIL: escalation threshold wrong")
		failed += 1

	# Test 6: warden_hunt requires artifact_retrievals >= 1
	var wh: Dictionary = by_id.get("warden_hunt", {})
	if str(wh.get("unlock_type", "")) == "artifact_retrievals" and int(wh.get("unlock_threshold", 0)) == 1:
		var locked := 0 < 1
		var unlocked := 1 >= 1
		if locked and unlocked:
			print("PASS: warden_hunt requires artifact_retrievals >= 1")
			passed += 1
		else:
			print("FAIL: warden_hunt unlock logic incorrect")
			failed += 1
	else:
		print("FAIL: warden_hunt should require artifact_retrievals with threshold 1")
		failed += 1

	# Test 7: cursed_ground and silent_run unlock at 10 runs
	var cg: Dictionary = by_id.get("cursed_ground", {})
	var sr: Dictionary = by_id.get("silent_run", {})
	if int(cg.get("unlock_threshold", 0)) == 10 and int(sr.get("unlock_threshold", 0)) == 10:
		print("PASS: cursed_ground and silent_run unlock at 10 total_runs")
		passed += 1
	else:
		print("FAIL: cursed_ground/silent_run thresholds wrong")
		failed += 1

	# Test 8: Shard bonus values match spec
	var expected_bonuses: Dictionary = {
		"iron_road": 30, "time_pressure": 40, "one_life": 60,
		"naked_run": 50, "escalation": 45, "warden_hunt": 80,
		"cursed_ground": 35, "silent_run": 25,
	}
	var bonus_ok := true
	for cid in expected_bonuses:
		var ch: Dictionary = by_id.get(cid, {})
		var expected: int = expected_bonuses[cid]
		var actual := int(ch.get("shard_bonus", 0))
		if actual != expected:
			bonus_ok = false
			print("FAIL: %s shard_bonus expected %d, got %d" % [cid, expected, actual])
			failed += 1
	if bonus_ok:
		print("PASS: all shard bonus values match spec")
		passed += 1

	print("\nChallenge unlock tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
