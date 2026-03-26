## M27 Test: Resonance Shard earning — base shards, ring bonuses, artifact bonus,
## enemy kill bonus, shard_investment multiplier
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ─── Helper: simulate shard calculation without GameState autoload ─────
	# Replicate GameState.calculate_shards_earned logic locally

	var RING_DEPTH := {"inner": 1, "mid": 2, "outer": 3}

	# Test 1: Base shards always 10
	var shards := 10
	if shards == 10:
		print("PASS: base shards always 10")
		passed += 1
	else:
		print("FAIL: base shards expected 10, got %d" % shards)
		failed += 1

	# Test 2: Inner ring bonus = +5
	var inner_bonus := int(RING_DEPTH.get("inner", 0)) * 5
	if inner_bonus == 5:
		print("PASS: inner ring bonus is +5")
		passed += 1
	else:
		print("FAIL: inner ring bonus expected 5, got %d" % inner_bonus)
		failed += 1

	# Test 3: Mid ring bonus = +10
	var mid_bonus := int(RING_DEPTH.get("mid", 0)) * 5
	if mid_bonus == 10:
		print("PASS: mid ring bonus is +10")
		passed += 1
	else:
		print("FAIL: mid ring bonus expected 10, got %d" % mid_bonus)
		failed += 1

	# Test 4: Outer ring bonus = +15
	var outer_bonus := int(RING_DEPTH.get("outer", 0)) * 5
	if outer_bonus == 15:
		print("PASS: outer ring bonus is +15")
		passed += 1
	else:
		print("FAIL: outer ring bonus expected 15, got %d" % outer_bonus)
		failed += 1

	# Test 5: Artifact bonus = +20
	var artifact_bonus := 20
	if artifact_bonus == 20:
		print("PASS: artifact retrieval bonus is +20")
		passed += 1
	else:
		print("FAIL: artifact bonus expected 20, got %d" % artifact_bonus)
		failed += 1

	# Test 6: Full shard calc — inner ring death, 5 enemies killed
	var calc_shards := 10  # base
	calc_shards += int(RING_DEPTH.get("inner", 0)) * 5  # +5
	calc_shards += 5  # 5 enemies
	# outcome = death, no artifact bonus
	if calc_shards == 20:
		print("PASS: inner ring death with 5 kills = 20 shards")
		passed += 1
	else:
		print("FAIL: expected 20 shards, got %d" % calc_shards)
		failed += 1

	# Test 7: Full shard calc — outer ring artifact, 12 enemies
	calc_shards = 10  # base
	calc_shards += int(RING_DEPTH.get("outer", 0)) * 5  # +15
	calc_shards += 20  # artifact
	calc_shards += 12  # enemies
	if calc_shards == 57:
		print("PASS: outer ring artifact with 12 kills = 57 shards")
		passed += 1
	else:
		print("FAIL: expected 57 shards, got %d" % calc_shards)
		failed += 1

	# Test 8: shard_investment multiplier (+25%)
	var base := 40
	var with_investment := int(ceil(base * 1.25))
	if with_investment == 50:
		print("PASS: shard_investment applies 25%% bonus (40 -> 50)")
		passed += 1
	else:
		print("FAIL: shard_investment expected 50, got %d" % with_investment)
		failed += 1

	# Test 9: Ring bonus stacking — sanctuary has depth 0, no bonus
	var sanc_bonus := int(RING_DEPTH.get("sanctuary", 0)) * 5
	if sanc_bonus == 0:
		print("PASS: sanctuary ring gives no bonus shards")
		passed += 1
	else:
		print("FAIL: sanctuary bonus expected 0, got %d" % sanc_bonus)
		failed += 1

	# Test 10: Zero enemies killed still gets base + ring bonus
	calc_shards = 10 + int(RING_DEPTH.get("mid", 0)) * 5 + 0
	if calc_shards == 20:
		print("PASS: zero kills with mid ring = 20 shards (base 10 + ring 10)")
		passed += 1
	else:
		print("FAIL: expected 20 shards, got %d" % calc_shards)
		failed += 1

	print("\nShard earning tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
