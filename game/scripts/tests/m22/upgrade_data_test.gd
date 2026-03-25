## M22 Test: Verify upgrade data — names, descriptions, categories, prices
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
	if vdata == null or typeof(vdata) != TYPE_DICTIONARY:
		printerr("FAIL: vendor_upgrades.json missing or invalid")
		quit(1)
		return

	var upgrades: Array = vdata.get("vendor_upgrades", [])

	# At least 4 upgrades
	if upgrades.size() >= 4:
		print("PASS: vendor_upgrades has >= 4 entries (%d)" % upgrades.size())
		passed += 1
	else:
		printerr("FAIL: vendor_upgrades needs >= 4 entries, got %d" % upgrades.size())
		failed += 1

	var valid_categories := ["combat", "survival", "mobility"]

	for upg in upgrades:
		var upg_id := str(upg.get("id", "?"))

		# name field exists and is not the id
		var upg_name := str(upg.get("name", ""))
		if upg_name != "" and upg_name != upg_id:
			print("PASS: %s has descriptive name '%s'" % [upg_id, upg_name])
			passed += 1
		else:
			printerr("FAIL: %s name is missing or matches id" % upg_id)
			failed += 1

		# description field exists and is > 10 chars (not just "+20 max HP")
		var desc := str(upg.get("description", ""))
		if desc.length() > 10:
			print("PASS: %s has description (%d chars)" % [upg_id, desc.length()])
			passed += 1
		else:
			printerr("FAIL: %s description too short or missing ('%s')" % [upg_id, desc])
			failed += 1

		# category field exists and is valid
		var cat := str(upg.get("category", ""))
		if cat in valid_categories:
			print("PASS: %s has valid category '%s'" % [upg_id, cat])
			passed += 1
		else:
			printerr("FAIL: %s has invalid/missing category '%s'" % [upg_id, cat])
			failed += 1

		# price > 0
		var cost := int(upg.get("cost", 0))
		if cost > 0:
			print("PASS: %s price is %d (> 0)" % [upg_id, cost])
			passed += 1
		else:
			printerr("FAIL: %s price must be > 0, got %d" % [upg_id, cost])
			failed += 1

		# required mechanical fields
		if upg.has("stat") and upg.has("bonus_per_level") and upg.has("max_level"):
			print("PASS: %s has stat/bonus/max_level fields" % upg_id)
			passed += 1
		else:
			printerr("FAIL: %s missing mechanical fields" % upg_id)
			failed += 1

	# Verify at least 2 categories are represented
	var seen_cats: Array = []
	for upg in upgrades:
		var cat := str(upg.get("category", ""))
		if cat != "" and cat not in seen_cats:
			seen_cats.append(cat)
	if seen_cats.size() >= 2:
		print("PASS: upgrades span %d categories (%s)" % [seen_cats.size(), ", ".join(PackedStringArray(seen_cats))])
		passed += 1
	else:
		printerr("FAIL: upgrades need >= 2 categories, got %d" % seen_cats.size())
		failed += 1

	if failed == 0:
		print("PASS: M22 upgrade data test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M22 upgrade data test (%d failed)" % failed)
		quit(1)
