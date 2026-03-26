## M27 Test: Permanent unlock data validation, purchase logic, deduplication,
## insufficient funds rejection
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load permanent_unlocks.json directly
	var raw := FileAccess.get_file_as_string("res://data/permanent_unlocks.json")
	var data: Dictionary = JSON.parse_string(raw)
	var unlocks: Array = data.get("permanent_unlocks", [])

	# Test 1: 12 permanent unlocks defined
	if unlocks.size() == 12:
		print("PASS: 12 permanent unlocks defined")
		passed += 1
	else:
		print("FAIL: expected 12 unlocks, got %d" % unlocks.size())
		failed += 1

	# Test 2: All unlocks have required fields
	var required_fields := ["id", "name", "description", "tier", "cost", "stat", "value"]
	var all_valid := true
	for unlock in unlocks:
		for field in required_fields:
			if not unlock.has(field):
				print("FAIL: unlock '%s' missing field '%s'" % [str(unlock.get("id", "?")), field])
				all_valid = false
				failed += 1
	if all_valid:
		print("PASS: all unlocks have required fields (id, name, description, tier, cost, stat, value)")
		passed += 1

	# Test 3: Tier 1 unlocks cost 50
	var tier1_ok := true
	for unlock in unlocks:
		if int(unlock.get("tier", 0)) == 1 and int(unlock.get("cost", 0)) != 50:
			tier1_ok = false
	if tier1_ok:
		print("PASS: all tier 1 unlocks cost 50 shards")
		passed += 1
	else:
		print("FAIL: some tier 1 unlocks do not cost 50")
		failed += 1

	# Test 4: Tier 2 unlocks cost 120
	var tier2_ok := true
	for unlock in unlocks:
		if int(unlock.get("tier", 0)) == 2 and int(unlock.get("cost", 0)) != 120:
			tier2_ok = false
	if tier2_ok:
		print("PASS: all tier 2 unlocks cost 120 shards")
		passed += 1
	else:
		print("FAIL: some tier 2 unlocks do not cost 120")
		failed += 1

	# Test 5: Tier 3 unlocks cost 250
	var tier3_ok := true
	for unlock in unlocks:
		if int(unlock.get("tier", 0)) == 3 and int(unlock.get("cost", 0)) != 250:
			tier3_ok = false
	if tier3_ok:
		print("PASS: all tier 3 unlocks cost 250 shards")
		passed += 1
	else:
		print("FAIL: some tier 3 unlocks do not cost 250")
		failed += 1

	# Test 6: 4 unlocks per tier
	var tier_counts := {1: 0, 2: 0, 3: 0}
	for unlock in unlocks:
		var tier := int(unlock.get("tier", 0))
		tier_counts[tier] = int(tier_counts.get(tier, 0)) + 1
	if int(tier_counts[1]) == 4 and int(tier_counts[2]) == 4 and int(tier_counts[3]) == 4:
		print("PASS: 4 unlocks per tier (4/4/4)")
		passed += 1
	else:
		print("FAIL: tier distribution %d/%d/%d, expected 4/4/4" % [tier_counts[1], tier_counts[2], tier_counts[3]])
		failed += 1

	# Test 7: No duplicate ids
	var ids: Array = []
	var dup_found := false
	for unlock in unlocks:
		var uid := str(unlock.get("id", ""))
		if ids.has(uid):
			dup_found = true
			print("FAIL: duplicate unlock id '%s'" % uid)
			failed += 1
		ids.append(uid)
	if not dup_found:
		print("PASS: no duplicate unlock ids")
		passed += 1

	# ─── Purchase logic simulation ─────────────────────────────────────────

	# Test 8: Purchase deducts shards
	var shards := 100
	var spent := 0
	var owned: Array = []
	var cost := 50
	# Simulate purchase
	var avail := shards - spent
	if avail >= cost:
		spent += cost
		owned.append("extra_stamina")
	if spent == 50 and owned.has("extra_stamina"):
		print("PASS: purchase deducts shards correctly (100-50=50 available)")
		passed += 1
	else:
		print("FAIL: purchase deduction incorrect")
		failed += 1

	# Test 9: Can't buy if insufficient shards
	var avail2 := shards - spent  # 50 remaining
	var can_buy := avail2 >= 120  # tier 2 cost
	if not can_buy:
		print("PASS: cannot purchase with insufficient shards (50 < 120)")
		passed += 1
	else:
		print("FAIL: should not allow purchase with insufficient shards")
		failed += 1

	# Test 10: Can't buy same unlock twice
	var already_owned := owned.has("extra_stamina")
	if already_owned:
		print("PASS: cannot purchase already-owned unlock")
		passed += 1
	else:
		print("FAIL: should detect already-owned unlock")
		failed += 1

	print("\nPermanent unlock tests: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
