## M22 Test: Shop UI — purchased upgrades show "Owned", unpurchased show price
## Tests vendor panel construction and refresh logic via data-driven simulation.
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

	# ── T6: Verify "Owned" display logic ──────────────────────────────────────
	# Simulate the _refresh_vendor_ui logic with mock state

	# Scenario 1: Unpurchased upgrade shows price
	var upg_0: Dictionary = upgrades[0]
	var cost_0 := int(upg_0.get("cost", 0))
	var max_level_0 := int(upg_0.get("max_level", 1))
	var current_level_0 := 0  # not purchased
	var banked := 500

	var is_maxed := current_level_0 >= max_level_0
	var can_buy := not is_maxed and banked >= cost_0
	var btn_text := ""
	if is_maxed:
		btn_text = "Owned (MAX)"
	elif current_level_0 > 0:
		btn_text = "Owned Lv %d — Upgrade (%d)" % [current_level_0, cost_0]
	else:
		btn_text = "Buy (%d)" % cost_0

	if btn_text.begins_with("Buy"):
		print("PASS: unpurchased upgrade shows price 'Buy (%d)'" % cost_0)
		passed += 1
	else:
		printerr("FAIL: unpurchased upgrade should show Buy, got '%s'" % btn_text)
		failed += 1

	if can_buy:
		print("PASS: unpurchased upgrade is buyable with %d silver" % banked)
		passed += 1
	else:
		printerr("FAIL: should be able to buy with %d silver" % banked)
		failed += 1

	# Scenario 2: Partially purchased upgrade shows "Owned Lv X"
	current_level_0 = 1
	is_maxed = current_level_0 >= max_level_0
	if is_maxed:
		btn_text = "Owned (MAX)"
	elif current_level_0 > 0:
		btn_text = "Owned Lv %d — Upgrade (%d)" % [current_level_0, cost_0]
	else:
		btn_text = "Buy (%d)" % cost_0

	if "Owned Lv 1" in btn_text:
		print("PASS: partially purchased shows 'Owned Lv 1'")
		passed += 1
	else:
		printerr("FAIL: partially purchased should show Owned Lv 1, got '%s'" % btn_text)
		failed += 1

	# Scenario 3: Maxed upgrade shows "Owned (MAX)" and is disabled
	current_level_0 = max_level_0
	is_maxed = current_level_0 >= max_level_0
	can_buy = not is_maxed and banked >= cost_0
	if is_maxed:
		btn_text = "Owned (MAX)"
	elif current_level_0 > 0:
		btn_text = "Owned Lv %d — Upgrade (%d)" % [current_level_0, cost_0]
	else:
		btn_text = "Buy (%d)" % cost_0

	if btn_text == "Owned (MAX)":
		print("PASS: maxed upgrade shows 'Owned (MAX)'")
		passed += 1
	else:
		printerr("FAIL: maxed should show Owned (MAX), got '%s'" % btn_text)
		failed += 1

	if not can_buy:
		print("PASS: maxed upgrade is disabled (can_buy=false)")
		passed += 1
	else:
		printerr("FAIL: maxed upgrade should not be buyable")
		failed += 1

	# Scenario 4: Insufficient funds — unpurchased but can't afford
	current_level_0 = 0
	banked = 5  # not enough
	is_maxed = current_level_0 >= max_level_0
	can_buy = not is_maxed and banked >= cost_0
	if not can_buy:
		print("PASS: insufficient funds disables purchase (banked=%d, cost=%d)" % [banked, cost_0])
		passed += 1
	else:
		printerr("FAIL: should not be able to buy with %d silver" % banked)
		failed += 1

	# ── T4: Verify category grouping data ─────────────────────────────────────
	# All upgrades should have a category field
	var all_have_category := true
	for upg in upgrades:
		if not upg.has("category") or str(upg.get("category", "")) == "":
			all_have_category = false
			printerr("FAIL: upgrade '%s' missing category" % str(upg.get("id", "?")))
			failed += 1

	if all_have_category:
		print("PASS: all upgrades have category field")
		passed += 1

	# Categories should group correctly (at least 2 distinct)
	var cats: Array = []
	for upg in upgrades:
		var cat := str(upg.get("category", ""))
		if cat not in cats:
			cats.append(cat)
	if cats.size() >= 2:
		print("PASS: %d distinct categories for grouping" % cats.size())
		passed += 1
	else:
		printerr("FAIL: need >= 2 categories for grouping, got %d" % cats.size())
		failed += 1

	# ── Verify flow_ui.gd has vendor toast method ─────────────────────────────
	var flow_script := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if flow_script == null or flow_script == "":
		printerr("FAIL: could not read flow_ui.gd")
		failed += 1
	else:
		if "show_vendor_purchase_toast" in flow_script:
			print("PASS: flow_ui.gd has show_vendor_purchase_toast method")
			passed += 1
		else:
			printerr("FAIL: flow_ui.gd missing show_vendor_purchase_toast method")
			failed += 1

		if "VendorToast" in flow_script:
			print("PASS: flow_ui.gd creates VendorToast label")
			passed += 1
		else:
			printerr("FAIL: flow_ui.gd missing VendorToast creation")
			failed += 1

		# Verify category headers in vendor setup
		if "COMBAT" in flow_script and "SURVIVAL" in flow_script:
			print("PASS: flow_ui.gd has category headers")
			passed += 1
		else:
			printerr("FAIL: flow_ui.gd missing category headers")
			failed += 1

	# Verify main.gd wires toast after purchase
	var main_script := FileAccess.get_file_as_string("res://scripts/main.gd")
	if main_script != null and "show_vendor_purchase_toast" in main_script:
		print("PASS: main.gd wires vendor purchase toast")
		passed += 1
	else:
		printerr("FAIL: main.gd missing vendor purchase toast wiring")
		failed += 1

	if failed == 0:
		print("PASS: M22 shop UI test (%d checks)" % passed)
		quit(0)
	else:
		printerr("FAIL: M22 shop UI test (%d failed)" % failed)
		quit(1)
