## M22 Test: Economy balance — verify silver yields vs upgrade prices
## Inner ring yield >= cheapest upgrade; outer ring yield >= 2x most expensive
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _initialize() -> void:
	var passed := 0
	var failed := 0

	var vdata: Variant = _load_json("res://data/vendor_upgrades.json")
	var rdata: Variant = _load_json("res://data/rings.json")
	var tdata: Variant = _load_json("res://data/encounter_templates.json")

	if vdata == null or rdata == null or tdata == null:
		printerr("FAIL: could not load required JSON files")
		quit(1)
		return

	var upgrades: Array = vdata.get("vendor_upgrades", [])
	var rings: Array = rdata.get("rings", [])
	var templates: Array = tdata.get("templates", [])

	# Find cheapest and most expensive upgrade prices
	var cheapest := 999999
	var most_expensive := 0
	for upg in upgrades:
		var cost := int(upg.get("cost", 0))
		if cost < cheapest:
			cheapest = cost
		if cost > most_expensive:
			most_expensive = cost

	if cheapest > 0 and most_expensive > 0:
		print("PASS: cheapest upgrade = %d, most expensive = %d" % [cheapest, most_expensive])
		passed += 1
	else:
		printerr("FAIL: invalid upgrade prices (cheapest=%d, expensive=%d)" % [cheapest, most_expensive])
		failed += 1

	# Calculate minimum silver yield per ring (using smallest encounter template enemy count)
	# Reward formula: base_loot = 12 * enemy_count * loot_multiplier per encounter
	var ring_yields: Dictionary = {}  # ring_id -> minimum total silver for full clear
	for ring in rings:
		var ring_id := str(ring.get("id", ""))
		if not bool(ring.get("combat_enabled", false)):
			continue
		var loot_mult := float(ring.get("loot_multiplier", 1.0))
		var contract_target := int(ring.get("contract_target", 3))

		# Find minimum enemy count for this ring's templates
		var min_enemies := 99
		for tmpl in templates:
			if str(tmpl.get("ring", "")) == ring_id:
				var enemy_count := int(tmpl.get("enemy_ids", []).size())
				if enemy_count < min_enemies:
					min_enemies = enemy_count
		if min_enemies == 99:
			min_enemies = 1  # fallback

		var per_encounter := int(round(12 * min_enemies * loot_mult))
		var total := per_encounter * contract_target
		ring_yields[ring_id] = total
		print("PASS: %s minimum yield = %d silver (%d encounters x %d per)" % [ring_id, total, contract_target, per_encounter])
		passed += 1

	# Inner ring yield >= cheapest upgrade
	var inner_yield: int = int(ring_yields.get("inner", 0))
	if inner_yield >= cheapest:
		print("PASS: inner ring yield (%d) >= cheapest upgrade (%d)" % [inner_yield, cheapest])
		passed += 1
	else:
		printerr("FAIL: inner ring yield (%d) < cheapest upgrade (%d)" % [inner_yield, cheapest])
		failed += 1

	# Mid ring yield >= most expensive (1 major OR 2 minor)
	var mid_yield: int = int(ring_yields.get("mid", 0))
	if mid_yield >= most_expensive:
		print("PASS: mid ring yield (%d) >= most expensive upgrade (%d)" % [mid_yield, most_expensive])
		passed += 1
	else:
		printerr("FAIL: mid ring yield (%d) < most expensive upgrade (%d)" % [mid_yield, most_expensive])
		failed += 1

	# Outer ring yield >= 2x most expensive
	var outer_yield: int = int(ring_yields.get("outer", 0))
	if outer_yield >= 2 * most_expensive:
		print("PASS: outer ring yield (%d) >= 2x most expensive (%d)" % [outer_yield, 2 * most_expensive])
		passed += 1
	else:
		printerr("FAIL: outer ring yield (%d) < 2x most expensive (%d)" % [outer_yield, 2 * most_expensive])
		failed += 1

	# Scarcity check: inner ring yield should NOT afford 2 major upgrades
	if inner_yield < 2 * most_expensive:
		print("PASS: inner ring yield (%d) < 2x expensive (%d) — scarcity maintained" % [inner_yield, 2 * most_expensive])
		passed += 1
	else:
		printerr("FAIL: inner ring too generous (%d >= %d)" % [inner_yield, 2 * most_expensive])
		failed += 1

	if failed == 0:
		print("PASS: M22 economy balance test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M22 economy balance test (%d failed)" % failed)
		quit(1)
