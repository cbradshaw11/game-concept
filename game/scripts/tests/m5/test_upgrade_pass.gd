extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Test 1: upgrades.json has >= 6 upgrades
	var f = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if f == null:
		failures.append("Could not open res://data/upgrades.json")
	else:
		var upgrades_data = JSON.parse_string(f.get_as_text())
		if upgrades_data.get("upgrades", []).size() < 6:
			failures.append("upgrades.json has fewer than 6 upgrades, got %d" % upgrades_data.get("upgrades", []).size())

	# Test 2: apply_upgrade increases max_health by 20
	var harness := Node.new()
	get_root().add_child(harness)
	GameState.selected_weapon_id = "blade_iron"
	var player := preload("res://scripts/core/player_controller.gd").new()
	harness.add_child(player)
	var before_health := player.max_health
	var upgrade := {"stat": "max_health", "modifier_type": "add", "value": 20}
	player.apply_upgrade(upgrade)
	if player.max_health != before_health + 20:
		failures.append("apply_upgrade did not increase max_health by 20 (before=%d, after=%d)" % [before_health, player.max_health])

	# Test 3: start_run resets active_upgrades
	GameState.active_upgrades.append({"id": "test"})
	GameState.start_run(1, "inner")
	if not GameState.active_upgrades.is_empty():
		failures.append("start_run did not clear active_upgrades")

	# Test 4: active_upgrades not in save state
	var save := GameState.to_save_state()
	if "active_upgrades" in save:
		failures.append("active_upgrades found in to_save_state() — must be per-run only")

	if failures.is_empty():
		print("PASS: test_upgrade_pass")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
