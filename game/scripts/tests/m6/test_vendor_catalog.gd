extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var f := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if f == null:
		failures.append("Could not open res://data/shop_items.json")
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
		return

	var catalog = JSON.parse_string(f.get_as_text())
	f.close()
	var items: Array = catalog.get("items", [])

	# Test 1: shop_items.json has >= 6 items
	if items.size() < 6:
		failures.append("shop_items.json has fewer than 6 items, got %d" % items.size())

	# Test 2: Every item has all required fields: id, name, cost, type, description
	var required_fields := ["id", "name", "cost", "type", "description"]
	for item in items:
		for field in required_fields:
			if not item.has(field):
				failures.append("Item missing required field '%s': %s" % [field, str(item.get("id", "<unknown>"))])

	# Test 3: All "per_run" items have a "stat" field
	for item in items:
		if item.get("type", "") == "per_run" and not item.has("stat"):
			failures.append("per_run item '%s' is missing 'stat' field" % str(item.get("id", "<unknown>")))

	# Test 4: All "permanent" items have a "stat" field
	for item in items:
		if item.get("type", "") == "permanent" and not item.has("stat"):
			failures.append("permanent item '%s' is missing 'stat' field" % str(item.get("id", "<unknown>")))

	# Test 5: No two items share the same id
	var seen_ids: Array = []
	for item in items:
		var item_id: String = str(item.get("id", ""))
		if item_id in seen_ids:
			failures.append("Duplicate item id found: '%s'" % item_id)
		else:
			seen_ids.append(item_id)

	if failures.is_empty():
		print("PASS: test_vendor_catalog")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
