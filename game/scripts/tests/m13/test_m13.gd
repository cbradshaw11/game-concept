extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# --- Test 1: shop item per_run pool size >= 7 ---
	var shop_raw := FileAccess.get_file_as_string("res://data/shop_items.json")
	if shop_raw.is_empty():
		failures.append("Test 1: could not read shop_items.json")
	else:
		var shop_data = JSON.parse_string(shop_raw)
		if shop_data == null or not shop_data.has("items"):
			failures.append("Test 1: shop_items.json missing 'items' key")
		else:
			var per_run_count := 0
			for item in shop_data["items"]:
				if item.get("type", "") == "per_run":
					per_run_count += 1
			if per_run_count < 7:
				failures.append("Test 1: per_run pool size is " + str(per_run_count) + ", expected >= 7")
			else:
				print("PASS: Test 1 - per_run pool size is " + str(per_run_count))

	# --- Test 2: new shop item stat names are valid known stats ---
	if shop_raw.is_empty():
		failures.append("Test 2: shop_items.json not available (skipping)")
	else:
		var shop_data2 = JSON.parse_string(shop_raw)
		var items: Array = shop_data2["items"]

		var dodge_salve_stat := ""
		var poise_splint_stat := ""
		var swift_tincture_stat := ""
		var loot_compass_stat := ""

		for item in items:
			match item.get("id", ""):
				"dodge_salve":
					dodge_salve_stat = item.get("stat", "")
				"poise_splint":
					poise_splint_stat = item.get("stat", "")
				"swift_tincture":
					swift_tincture_stat = item.get("stat", "")
				"loot_compass":
					loot_compass_stat = item.get("stat", "")

		var t2_ok := true
		if dodge_salve_stat != "dodge_stamina_cost":
			failures.append("Test 2a: dodge_salve stat is '" + dodge_salve_stat + "', expected 'dodge_stamina_cost'")
			t2_ok = false
		if poise_splint_stat != "max_poise":
			failures.append("Test 2b: poise_splint stat is '" + poise_splint_stat + "', expected 'max_poise'")
			t2_ok = false
		if swift_tincture_stat != "stamina_regen_rate":
			failures.append("Test 2c: swift_tincture stat is '" + swift_tincture_stat + "', expected 'stamina_regen_rate'")
			t2_ok = false
		if loot_compass_stat != "loot_per_encounter":
			failures.append("Test 2d: loot_compass stat is '" + loot_compass_stat + "', expected 'loot_per_encounter'")
			t2_ok = false
		if t2_ok:
			print("PASS: Test 2 - all new shop item stat names are valid")

	# --- Test 3: swift_tincture has modifier_type "multiply" ---
	if shop_raw.is_empty():
		failures.append("Test 3: shop_items.json not available (skipping)")
	else:
		var shop_data3 = JSON.parse_string(shop_raw)
		var swift_mod := ""
		for item in shop_data3["items"]:
			if item.get("id", "") == "swift_tincture":
				swift_mod = item.get("modifier_type", "")
				break
		if swift_mod != "multiply":
			failures.append("Test 3: swift_tincture modifier_type is '" + swift_mod + "', expected 'multiply'")
		else:
			print("PASS: Test 3 - swift_tincture has modifier_type 'multiply'")

	# --- Test 4: upgrade pool size >= 21 ---
	var upgrades_raw := FileAccess.get_file_as_string("res://data/upgrades.json")
	if upgrades_raw.is_empty():
		failures.append("Test 4: could not read upgrades.json")
	else:
		var upgrades_data = JSON.parse_string(upgrades_raw)
		if upgrades_data == null or not upgrades_data.has("upgrades"):
			failures.append("Test 4: upgrades.json missing 'upgrades' key")
		else:
			var upgrade_count: int = upgrades_data["upgrades"].size()
			if upgrade_count < 21:
				failures.append("Test 4: upgrade pool size is " + str(upgrade_count) + ", expected >= 21")
			else:
				print("PASS: Test 4 - upgrade pool size is " + str(upgrade_count))

	# --- Test 5: all rings have death_flavor field ---
	var rings_raw := FileAccess.get_file_as_string("res://data/rings.json")
	if rings_raw.is_empty():
		failures.append("Test 5: could not read rings.json")
	else:
		var rings_data = JSON.parse_string(rings_raw)
		if rings_data == null or not rings_data.has("rings"):
			failures.append("Test 5: rings.json missing 'rings' key")
		else:
			var missing_flavor: Array[String] = []
			for ring in rings_data["rings"]:
				if not ring.has("death_flavor"):
					missing_flavor.append(ring.get("id", "unknown"))
			if missing_flavor.size() > 0:
				failures.append("Test 5: rings missing death_flavor: " + ", ".join(missing_flavor))
			else:
				print("PASS: Test 5 - all rings have death_flavor field")

	# --- Test 6: outer ring has solo warden_herald template ---
	var templates_raw := FileAccess.get_file_as_string("res://data/encounter_templates.json")
	if templates_raw.is_empty():
		failures.append("Test 6: could not read encounter_templates.json")
	else:
		var templates_data = JSON.parse_string(templates_raw)
		if templates_data == null or not templates_data.has("templates"):
			failures.append("Test 6: encounter_templates.json missing 'templates' key")
		else:
			var found_solo_herald := false
			for tpl in templates_data["templates"]:
				if tpl.get("ring", "") == "outer":
					var eids: Array = tpl.get("enemy_ids", [])
					if eids.size() == 1 and eids[0] == "warden_herald":
						found_solo_herald = true
						break
			if not found_solo_herald:
				failures.append("Test 6: no outer ring template found with enemy_ids == [\"warden_herald\"]")
			else:
				print("PASS: Test 6 - outer ring has solo warden_herald template")

	# --- Test 7: void_sniper uses sniper_volley profile ---
	var enemies_raw := FileAccess.get_file_as_string("res://data/enemies.json")
	if enemies_raw.is_empty():
		failures.append("Test 7: could not read enemies.json")
	else:
		var enemies_data = JSON.parse_string(enemies_raw)
		if enemies_data == null or not enemies_data.has("enemies"):
			failures.append("Test 7: enemies.json missing 'enemies' key")
		else:
			var void_sniper_profile := ""
			for enemy in enemies_data["enemies"]:
				if enemy.get("id", "") == "void_sniper":
					void_sniper_profile = enemy.get("behavior_profile", "")
					break
			if void_sniper_profile != "sniper_volley":
				failures.append("Test 7: void_sniper behavior_profile is '" + void_sniper_profile + "', expected 'sniper_volley'")
			else:
				print("PASS: Test 7 - void_sniper uses sniper_volley profile")

	# --- Test 8: no per_run loot item uses "loot_per_encounter_bonus" stat ---
	if shop_raw.is_empty():
		failures.append("Test 8: shop_items.json not available (skipping)")
	else:
		var shop_data8 = JSON.parse_string(shop_raw)
		var bad_stat_items: Array[String] = []
		for item in shop_data8["items"]:
			if item.get("type", "") == "per_run":
				var s: String = item.get("stat", "")
				if s == "loot_per_encounter_bonus":
					bad_stat_items.append(item.get("id", "unknown"))
		if bad_stat_items.size() > 0:
			failures.append("Test 8: per_run items use 'loot_per_encounter_bonus' stat (should be 'loot_per_encounter'): " + ", ".join(bad_stat_items))
		else:
			print("PASS: Test 8 - no per_run item uses loot_per_encounter_bonus stat")

	# --- Finalize ---
	if failures.is_empty():
		print("PASS: test_m13")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
