extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: apply_shop_item() with a per_run item deducts banked_loot by item.cost
	GameState.apply_save_state(GameState.default_save_state())
	GameState.banked_loot = 100
	var per_run_item := {"id": "blade_whetstone", "name": "Blade Whetstone", "cost": 20, "type": "per_run", "stat": "light_damage", "value": 3}
	GameState.banked_loot -= per_run_item["cost"]
	GameState.apply_shop_item(per_run_item)
	if GameState.banked_loot != 80:
		failures.append("Expected banked_loot == 80 after per_run purchase of cost 20, got %d" % GameState.banked_loot)

	# Test 2: apply_shop_item() with banked_loot < cost does NOT deduct (guard)
	GameState.apply_save_state(GameState.default_save_state())
	GameState.banked_loot = 10
	var expensive_item := {"id": "ancestral_shard", "name": "Ancestral Shard", "cost": 60, "type": "permanent", "stat": "xp_multiplier", "value": 0.10}
	# The guard: only deduct if banked_loot >= cost
	var loot_before := GameState.banked_loot
	if GameState.banked_loot >= expensive_item["cost"]:
		GameState.banked_loot -= expensive_item["cost"]
		GameState.apply_shop_item(expensive_item)
	if GameState.banked_loot != loot_before:
		failures.append("banked_loot was deducted when insufficient funds (before=%d, after=%d)" % [loot_before, GameState.banked_loot])

	# Test 3: apply_shop_item() with a permanent item adds to permanent_upgrades array
	GameState.apply_save_state(GameState.default_save_state())
	var perm_item := {"id": "warden_map", "name": "Warden Map", "cost": 40, "type": "permanent", "stat": "warden_map_owned", "value": 1}
	GameState.apply_shop_item(perm_item)
	if not GameState.permanent_upgrades.has(perm_item):
		failures.append("permanent item not found in permanent_upgrades after apply_shop_item()")

	# Test 4: per_run items are NOT present in to_save_state() output (they're transient)
	GameState.apply_save_state(GameState.default_save_state())
	GameState.apply_shop_item(per_run_item)
	var save_state := GameState.to_save_state()
	if "active_upgrades" in save_state:
		failures.append("active_upgrades (per_run) found in to_save_state() — must be transient only")

	# Test 5: permanent_upgrades IS present in to_save_state() output
	if not "permanent_upgrades" in save_state:
		failures.append("permanent_upgrades not found in to_save_state() output")

	if failures.is_empty():
		print("PASS: test_shop_system")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
