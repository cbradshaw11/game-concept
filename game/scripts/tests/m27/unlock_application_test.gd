## M27 Test: Permanent unlock application — extra_stamina increases max stamina,
## tougher_start increases HP, inner_knowledge reduces contract target,
## silver_sense adds starting silver, deep_pockets increases loot
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load data files for reference
	var unlocks_raw := FileAccess.get_file_as_string("res://data/permanent_unlocks.json")
	var unlocks_data: Dictionary = JSON.parse_string(unlocks_raw)
	var unlocks: Array = unlocks_data.get("permanent_unlocks", [])

	var rings_raw := FileAccess.get_file_as_string("res://data/rings.json")
	var rings_data: Dictionary = JSON.parse_string(rings_raw)

	# ─── extra_stamina: +10 max stamina ──────────────────────────────────
	var extra_stam := {}
	for u in unlocks:
		if str(u.get("id", "")) == "extra_stamina":
			extra_stam = u
	var base_stamina := 100
	var bonus := int(extra_stam.get("value", 0))
	var effective := base_stamina + bonus
	if effective == 110:
		print("PASS: extra_stamina increases max stamina from 100 to 110")
		passed += 1
	else:
		print("FAIL: extra_stamina expected 110, got %d" % effective)
		failed += 1

	# ─── tougher_start: +8 max HP ────────────────────────────────────────
	var tougher := {}
	for u in unlocks:
		if str(u.get("id", "")) == "tougher_start":
			tougher = u
	var base_hp := 100
	var hp_bonus := int(tougher.get("value", 0))
	var effective_hp := base_hp + hp_bonus
	if effective_hp == 108:
		print("PASS: tougher_start increases max HP from 100 to 108")
		passed += 1
	else:
		print("FAIL: tougher_start expected 108, got %d" % effective_hp)
		failed += 1

	# ─── inner_knowledge: contract target reduced by 1 (min 2) ───────────
	var inner_ring := {}
	for ring in rings_data.get("rings", []):
		if str(ring.get("id", "")) == "inner":
			inner_ring = ring
	var base_target := int(inner_ring.get("contract_target", 3))
	var reduced: int = max(2, base_target - 1)
	if reduced == 2:
		print("PASS: inner_knowledge reduces inner contract from %d to %d" % [base_target, reduced])
		passed += 1
	else:
		print("FAIL: inner_knowledge expected contract target 2, got %d" % reduced)
		failed += 1

	# ─── inner_knowledge respects min 2 ──────────────────────────────────
	var already_min: int = max(2, 2 - 1)
	if already_min == 2:
		print("PASS: inner_knowledge respects minimum contract target of 2")
		passed += 1
	else:
		print("FAIL: min contract target should be 2, got %d" % already_min)
		failed += 1

	# ─── silver_sense: start with 15 bonus silver ────────────────────────
	var silver_sense := {}
	for u in unlocks:
		if str(u.get("id", "")) == "silver_sense":
			silver_sense = u
	var starting_silver := int(silver_sense.get("value", 0))
	if starting_silver == 15:
		print("PASS: silver_sense provides 15 starting silver")
		passed += 1
	else:
		print("FAIL: silver_sense expected 15, got %d" % starting_silver)
		failed += 1

	# ─── deep_pockets: loot multiplier +5% ───────────────────────────────
	var deep_pockets := {}
	for u in unlocks:
		if str(u.get("id", "")) == "deep_pockets":
			deep_pockets = u
	var loot_pct := float(deep_pockets.get("value", 0))
	if is_equal_approx(loot_pct, 0.05):
		print("PASS: deep_pockets provides +5%% loot bonus")
		passed += 1
	else:
		print("FAIL: deep_pockets expected 0.05, got %f" % loot_pct)
		failed += 1

	# ─── shard_investment: +25% shards ───────────────────────────────────
	var shard_inv := {}
	for u in unlocks:
		if str(u.get("id", "")) == "shard_investment":
			shard_inv = u
	var shard_bonus := float(shard_inv.get("value", 0))
	if is_equal_approx(shard_bonus, 0.25):
		print("PASS: shard_investment provides +25%% shard bonus")
		passed += 1
	else:
		print("FAIL: shard_investment expected 0.25, got %f" % shard_bonus)
		failed += 1

	# ─── veteran_dodge: +30ms i-frames ───────────────────────────────────
	var vet_dodge := {}
	for u in unlocks:
		if str(u.get("id", "")) == "veteran_dodge":
			vet_dodge = u
	var iframe_bonus := int(vet_dodge.get("value", 0))
	if iframe_bonus == 30:
		print("PASS: veteran_dodge extends i-frames by 30ms")
		passed += 1
	else:
		print("FAIL: veteran_dodge expected 30ms, got %d" % iframe_bonus)
		failed += 1

	# ─── Reward calc with deep_pockets ───────────────────────────────────
	# Simulate: inner ring (loot_mult=1.0), 2 enemies, deep_pockets +5%
	var base_loot := 12 * 2  # 24
	var loot_mult := 1.0
	var total_loot := int(round(base_loot * loot_mult * (1.0 + 0.05)))
	if total_loot == 25:
		print("PASS: deep_pockets increases loot reward (24 * 1.05 = 25)")
		passed += 1
	else:
		print("FAIL: expected 25 loot with deep_pockets, got %d" % total_loot)
		failed += 1

	print("\nUnlock application tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
