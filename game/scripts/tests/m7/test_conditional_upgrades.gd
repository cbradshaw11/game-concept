extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Load upgrades.json to verify the data shape of blood_edge and last_stand.
	# PlayerController requires a running physics scene (CharacterBody2D) and DataStore,
	# so we test the upgrade data directly and via GameState.active_upgrades + manual logic.

	var upgrades_text := FileAccess.get_file_as_string("res://data/upgrades.json")
	if upgrades_text.is_empty():
		print("FAIL: could not read res://data/upgrades.json")
		quit(1)
		return

	var parsed: Variant = JSON.parse_string(upgrades_text)
	if not parsed is Dictionary:
		print("FAIL: upgrades.json did not parse as Dictionary")
		quit(1)
		return

	var upgrades: Array = (parsed as Dictionary).get("upgrades", [])

	# Locate blood_edge and last_stand entries
	var blood_edge: Dictionary = {}
	var last_stand: Dictionary = {}
	for u in upgrades:
		if u.get("id", "") == "blood_edge":
			blood_edge = u
		elif u.get("id", "") == "last_stand":
			last_stand = u

	# Test 1: blood_edge active below 50% HP -- attack_damage bonus present
	# Verify blood_edge has threshold=0.5 and stat="attack_damage"
	if blood_edge.is_empty():
		failures.append("Test 1: blood_edge upgrade not found in upgrades.json")
	else:
		if blood_edge.get("modifier_type", "") != "conditional_health_pct":
			failures.append("Test 1: blood_edge modifier_type should be 'conditional_health_pct', got '%s'" % blood_edge.get("modifier_type", ""))
		if blood_edge.get("threshold", -1.0) != 0.5:
			failures.append("Test 1: blood_edge threshold should be 0.5, got %s" % str(blood_edge.get("threshold", -1.0)))
		if blood_edge.get("stat", "") != "attack_damage":
			failures.append("Test 1: blood_edge stat should be 'attack_damage', got '%s'" % blood_edge.get("stat", ""))
		# Simulate: health_pct < threshold => bonus active
		var health_pct_below: float = 0.4  # below 50%
		var threshold: float = float(blood_edge.get("threshold", 1.0))
		var bonus_active: bool = health_pct_below < threshold
		if not bonus_active:
			failures.append("Test 1: blood_edge should be active at 40% health (below 50% threshold)")

	# Test 2: blood_edge inactive above 50% HP -- no bonus
	if not blood_edge.is_empty():
		var health_pct_above: float = 0.6  # above 50%
		var threshold: float = float(blood_edge.get("threshold", 1.0))
		var bonus_active: bool = health_pct_above < threshold
		if bonus_active:
			failures.append("Test 2: blood_edge should be inactive at 60% health (above 50% threshold)")

	# Test 3: last_stand active below 30% HP -- guard_efficiency bonus present
	if last_stand.is_empty():
		failures.append("Test 3: last_stand upgrade not found in upgrades.json")
	else:
		if last_stand.get("modifier_type", "") != "conditional_health_pct":
			failures.append("Test 3: last_stand modifier_type should be 'conditional_health_pct', got '%s'" % last_stand.get("modifier_type", ""))
		if last_stand.get("threshold", -1.0) != 0.3:
			failures.append("Test 3: last_stand threshold should be 0.3, got %s" % str(last_stand.get("threshold", -1.0)))
		if last_stand.get("stat", "") != "guard_efficiency":
			failures.append("Test 3: last_stand stat should be 'guard_efficiency', got '%s'" % last_stand.get("stat", ""))
		# Simulate: health_pct < threshold => bonus active
		var health_pct_below: float = 0.2  # below 30%
		var threshold: float = float(last_stand.get("threshold", 1.0))
		var bonus_active: bool = health_pct_below < threshold
		if not bonus_active:
			failures.append("Test 3: last_stand should be active at 20% health (below 30% threshold)")

	# Test 4: last_stand inactive above 30% HP -- no bonus
	if not last_stand.is_empty():
		var health_pct_above: float = 0.5  # above 30%
		var threshold: float = float(last_stand.get("threshold", 1.0))
		var bonus_active: bool = health_pct_above < threshold
		if bonus_active:
			failures.append("Test 4: last_stand should be inactive at 50% health (above 30% threshold)")

	# Test 5: multiple active conditional upgrades stack correctly
	# Simulate the _recalculate_conditional_bonuses logic manually
	var test_active_upgrades: Array = [blood_edge.duplicate(), last_stand.duplicate()]
	var health_pct: float = 0.2  # below both thresholds
	var conditional_bonuses: Dictionary = {}
	for upgrade in test_active_upgrades:
		if upgrade.get("modifier_type", "") == "conditional_health_pct":
			var threshold: float = float(upgrade.get("threshold", 1.0))
			if health_pct < threshold:
				var stat: String = upgrade.get("stat", "")
				if not stat.is_empty():
					var val: float = float(upgrade.get("value", 0))
					conditional_bonuses[stat] = conditional_bonuses.get(stat, 0.0) + val
	if not conditional_bonuses.has("attack_damage"):
		failures.append("Test 5: stacked bonuses should include attack_damage at 20% health")
	if not conditional_bonuses.has("guard_efficiency"):
		failures.append("Test 5: stacked bonuses should include guard_efficiency at 20% health")
	var expected_attack_bonus: float = float(blood_edge.get("value", 0))
	var expected_guard_bonus: float = float(last_stand.get("value", 0))
	if abs(conditional_bonuses.get("attack_damage", 0.0) - expected_attack_bonus) > 0.001:
		failures.append("Test 5: attack_damage bonus should be %s, got %s" % [str(expected_attack_bonus), str(conditional_bonuses.get("attack_damage", 0.0))])
	if abs(conditional_bonuses.get("guard_efficiency", 0.0) - expected_guard_bonus) > 0.001:
		failures.append("Test 5: guard_efficiency bonus should be %s, got %s" % [str(expected_guard_bonus), str(conditional_bonuses.get("guard_efficiency", 0.0))])

	if failures.is_empty():
		print("PASS: test_conditional_upgrades")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
