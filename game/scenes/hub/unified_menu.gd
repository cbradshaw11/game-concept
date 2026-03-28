extends CanvasLayer

signal menu_closed

var at_home: bool = false
var default_tab: int = 0  # 0 = Shop, 1 = Inventory & Bank

# Top-level tab buttons
var shop_tab_btn: Button
var inv_tab_btn: Button
var active_tab: int = 0

# Containers
var tab_content: VBoxContainer  # swapped content area

# ── Shop state ──
var shop_left_vbox: VBoxContainer
var shop_right_vbox: VBoxContainer
var shop_scroll: ScrollContainer
var shop_item_list: VBoxContainer
var shop_carried_label: Label
var shop_category: String = "weapon"
var shop_weapon_btn: Button
var shop_potion_btn: Button
var shop_armor_btn: Button
var shop_confirm_row_parent: Node = null
var shop_locked_label: Label
var shop_content: HBoxContainer
var sell_equipped_vbox: VBoxContainer
var sell_bank_vbox: VBoxContainer
var sell_potions_vbox: VBoxContainer
var sell_scroll: ScrollContainer

# ── Inventory & Bank state ──
var inv_content: HBoxContainer
var bank_vbox: VBoxContainer
var equip_vbox: HBoxContainer
var stats_vbox: VBoxContainer
var slots_vbox: VBoxContainer
var potions_vbox: VBoxContainer
var content_vbox: VBoxContainer
var equip_filter: String = "all"
var filter_buttons: Dictionary = {}
var potions_sep_node: HSeparator
var pot_title_node: Label
var stats_sep_node: HSeparator
var st_title_node: Label
var items_vbox: VBoxContainer
var bank_controls: VBoxContainer
var bank_locked_label: Label
var withdraw_active: bool = false
var withdraw_input_text: String = ""
var withdraw_input_label: Label
var withdraw_row: HBoxContainer
var bank_label: Label
var carried_label: Label
var confirm_discard_row: Node = null

func _ready() -> void:
	_build_ui()
	_switch_tab(default_tab)
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.inventory_changed.connect(_refresh)
		inv.bank_changed.connect(_refresh)

func _build_ui() -> void:
	# Dimmed backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_panel := PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(1100, 580)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.16, 1.0)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.35, 0.5, 1.0)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	main_panel.add_theme_stylebox_override("panel", style)
	center.add_child(main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	main_panel.add_child(root_vbox)

	# ── Top tab bar ──
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 20)
	root_vbox.add_child(tab_row)

	shop_tab_btn = Button.new()
	shop_tab_btn.text = "Shop"
	shop_tab_btn.custom_minimum_size = Vector2(160, 34)
	shop_tab_btn.pressed.connect(func(): _switch_tab(0))
	tab_row.add_child(shop_tab_btn)

	inv_tab_btn = Button.new()
	inv_tab_btn.text = "Inventory & Bank"
	inv_tab_btn.custom_minimum_size = Vector2(160, 34)
	inv_tab_btn.pressed.connect(func(): _switch_tab(1))
	tab_row.add_child(inv_tab_btn)

	var top_sep := HSeparator.new()
	root_vbox.add_child(top_sep)

	# ── Tab content area ──
	tab_content = VBoxContainer.new()
	tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(tab_content)

	# ── Close hint ──
	var bottom_sep := HSeparator.new()
	root_vbox.add_child(bottom_sep)

	var hint := Label.new()
	hint.text = "Press ESC / I / E to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(hint)

	# Build both tab contents (only one visible at a time)
	_build_shop_tab()
	_build_inv_tab()

# ══════════════════════════════════════════════════════════
# TAB SWITCHING
# ══════════════════════════════════════════════════════════

func _switch_tab(idx: int) -> void:
	active_tab = idx
	var active_col := Color(1.0, 0.9, 0.5)
	var normal_col := Color(0.8, 0.8, 0.8)
	shop_tab_btn.add_theme_color_override("font_color", active_col if idx == 0 else normal_col)
	inv_tab_btn.add_theme_color_override("font_color", active_col if idx == 1 else normal_col)
	shop_content.visible = (idx == 0)
	shop_locked_label.visible = (idx == 0 and not at_home)
	if idx == 0:
		shop_content.visible = at_home
	inv_content.visible = (idx == 1)
	_refresh()

# ══════════════════════════════════════════════════════════
# SHOP TAB
# ══════════════════════════════════════════════════════════

func _build_shop_tab() -> void:
	# Locked message
	shop_locked_label = Label.new()
	shop_locked_label.text = "Return home to shop"
	shop_locked_label.add_theme_font_size_override("font_size", 16)
	shop_locked_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	shop_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_locked_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_locked_label.visible = false
	tab_content.add_child(shop_locked_label)

	# Two-column shop layout
	shop_content = HBoxContainer.new()
	shop_content.add_theme_constant_override("separation", 0)
	shop_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.visible = false
	tab_content.add_child(shop_content)

	# ── LEFT: Items for sale ──
	shop_left_vbox = VBoxContainer.new()
	shop_left_vbox.add_theme_constant_override("separation", 6)
	shop_left_vbox.custom_minimum_size = Vector2(560, 0)
	shop_left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(shop_left_vbox)

	var shop_title := Label.new()
	shop_title.text = "Items for Sale"
	shop_title.add_theme_font_size_override("font_size", 16)
	shop_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_left_vbox.add_child(shop_title)

	# Category tabs
	var cat_row := HBoxContainer.new()
	cat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cat_row.add_theme_constant_override("separation", 12)
	shop_left_vbox.add_child(cat_row)

	shop_weapon_btn = Button.new()
	shop_weapon_btn.text = "Weapons"
	shop_weapon_btn.custom_minimum_size = Vector2(100, 30)
	shop_weapon_btn.pressed.connect(func(): _show_shop_category("weapon"))
	cat_row.add_child(shop_weapon_btn)

	shop_potion_btn = Button.new()
	shop_potion_btn.text = "Potions"
	shop_potion_btn.custom_minimum_size = Vector2(100, 30)
	shop_potion_btn.pressed.connect(func(): _show_shop_category("potion"))
	cat_row.add_child(shop_potion_btn)

	shop_armor_btn = Button.new()
	shop_armor_btn.text = "Armor"
	shop_armor_btn.custom_minimum_size = Vector2(100, 30)
	shop_armor_btn.pressed.connect(func(): _show_shop_category("armor"))
	cat_row.add_child(shop_armor_btn)

	var cat_sep := HSeparator.new()
	shop_left_vbox.add_child(cat_sep)

	shop_scroll = ScrollContainer.new()
	shop_scroll.custom_minimum_size = Vector2(520, 340)
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_left_vbox.add_child(shop_scroll)

	shop_item_list = VBoxContainer.new()
	shop_item_list.add_theme_constant_override("separation", 6)
	shop_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.add_child(shop_item_list)

	# Gold footer
	shop_carried_label = Label.new()
	shop_carried_label.add_theme_font_size_override("font_size", 14)
	shop_carried_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	shop_left_vbox.add_child(shop_carried_label)

	# ── SEPARATOR ──
	var vsep := VSeparator.new()
	shop_content.add_child(vsep)

	# ── RIGHT: Sell Items ──
	shop_right_vbox = VBoxContainer.new()
	shop_right_vbox.add_theme_constant_override("separation", 6)
	shop_right_vbox.custom_minimum_size = Vector2(480, 0)
	shop_right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(shop_right_vbox)

	var sell_title := Label.new()
	sell_title.text = "Sell Items"
	sell_title.add_theme_font_size_override("font_size", 16)
	sell_title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	sell_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_right_vbox.add_child(sell_title)

	var sell_sep := HSeparator.new()
	shop_right_vbox.add_child(sell_sep)

	sell_scroll = ScrollContainer.new()
	sell_scroll.custom_minimum_size = Vector2(450, 400)
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_right_vbox.add_child(sell_scroll)

	var sell_inner := VBoxContainer.new()
	sell_inner.add_theme_constant_override("separation", 4)
	sell_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(sell_inner)

	# Equipped header
	var eq_hdr := Label.new()
	eq_hdr.text = "Equipped"
	eq_hdr.add_theme_font_size_override("font_size", 14)
	eq_hdr.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	sell_inner.add_child(eq_hdr)

	sell_equipped_vbox = VBoxContainer.new()
	sell_equipped_vbox.add_theme_constant_override("separation", 3)
	sell_inner.add_child(sell_equipped_vbox)

	var bank_hdr_sep := HSeparator.new()
	sell_inner.add_child(bank_hdr_sep)

	# Bank items header
	var bk_hdr := Label.new()
	bk_hdr.text = "Bank Items"
	bk_hdr.add_theme_font_size_override("font_size", 14)
	bk_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	sell_inner.add_child(bk_hdr)

	sell_bank_vbox = VBoxContainer.new()
	sell_bank_vbox.add_theme_constant_override("separation", 3)
	sell_inner.add_child(sell_bank_vbox)

	# Potions header + section
	var pot_hdr_sep := HSeparator.new()
	sell_inner.add_child(pot_hdr_sep)

	var pot_hdr := Label.new()
	pot_hdr.text = "Potions"
	pot_hdr.add_theme_font_size_override("font_size", 14)
	pot_hdr.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	sell_inner.add_child(pot_hdr)

	sell_potions_vbox = VBoxContainer.new()
	sell_potions_vbox.add_theme_constant_override("separation", 3)
	sell_inner.add_child(sell_potions_vbox)

func _show_shop_category(cat: String) -> void:
	shop_category = cat
	shop_confirm_row_parent = null
	_update_shop_tab_colors()
	_rebuild_shop_item_list()

func _update_shop_tab_colors() -> void:
	var active_col := Color(1.0, 0.9, 0.5)
	var normal_col := Color(0.8, 0.8, 0.8)
	shop_weapon_btn.add_theme_color_override("font_color", active_col if shop_category == "weapon" else normal_col)
	shop_potion_btn.add_theme_color_override("font_color", active_col if shop_category == "potion" else normal_col)
	shop_armor_btn.add_theme_color_override("font_color", active_col if shop_category == "armor" else normal_col)

func _rebuild_shop_item_list() -> void:
	for child in shop_item_list.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	var carried: int = int(inv.get("carried_gold")) if inv else 0
	shop_carried_label.text = "Carried: %dg" % carried

	var items: Array = _get_shop_items()

	if shop_category == "weapon":
		var melee_items: Array = items.filter(func(i): return i.get("slot") == "weapon_melee")
		var ranged_items: Array = items.filter(func(i): return i.get("slot") == "weapon_ranged")
		var magic_items: Array = items.filter(func(i): return i.get("slot") == "weapon_magic")
		if melee_items.size() > 0:
			_add_shop_sub_header("Melee")
			for item in melee_items:
				_add_shop_item_row(item, carried)
		if ranged_items.size() > 0:
			_add_shop_sub_header("Ranged")
			for item in ranged_items:
				_add_shop_item_row(item, carried)
		if magic_items.size() > 0:
			_add_shop_sub_header("Magic")
			for item in magic_items:
				_add_shop_item_row(item, carried)
	else:
		for item in items:
			_add_shop_item_row(item, carried)

func _add_shop_sub_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	shop_item_list.add_child(lbl)

func _add_shop_item_row(item: Dictionary, carried: int) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	shop_item_list.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.custom_minimum_size = Vector2(160, 0)
	hbox.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = _get_stat_summary(item)
	stat_lbl.add_theme_font_size_override("font_size", 12)
	stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	stat_lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(stat_lbl)

	var cost: int = int(item.get("cost", 0))
	var cost_lbl := Label.new()
	cost_lbl.text = "%dg" % cost
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	cost_lbl.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(cost_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 28)
	if carried < cost:
		buy_btn.disabled = true
		buy_btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		buy_btn.pressed.connect(func(): _buy_item(item))
	hbox.add_child(buy_btn)

func _show_buy_confirm(row: VBoxContainer, item: Dictionary) -> void:
	if shop_confirm_row_parent != null and is_instance_valid(shop_confirm_row_parent):
		var old: Node = shop_confirm_row_parent.get_node_or_null("ConfirmRow")
		if old:
			old.queue_free()
	shop_confirm_row_parent = row

	var confirm := HBoxContainer.new()
	confirm.name = "ConfirmRow"
	confirm.add_theme_constant_override("separation", 8)
	row.add_child(confirm)

	var lbl := Label.new()
	lbl.text = "Confirm?"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	confirm.add_child(lbl)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(50, 24)
	yes_btn.pressed.connect(func(): _buy_item(item))
	confirm.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(50, 24)
	no_btn.pressed.connect(func(): confirm.queue_free(); shop_confirm_row_parent = null)
	confirm.add_child(no_btn)

func _buy_item(item: Dictionary) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var cost: int = int(item.get("cost", 0))
	var carried: int = int(inv.get("carried_gold"))
	if carried < cost:
		return
	inv.carried_gold -= cost
	var bought_item: Dictionary = item.duplicate()
	if bought_item.get("category", "") == "potion":
		inv.add_potion(bought_item)
	else:
		inv.bank_items.append(bought_item)
		inv.bank_changed.emit()
	inv.inventory_changed.emit()
	shop_confirm_row_parent = null
	_rebuild_shop_item_list()
	_rebuild_sell_panel()

func _get_shop_items() -> Array:
	var data: Node = get_node_or_null("/root/DataStore")
	var all_items: Array = []
	if data and data.has_method("get") and data.get("shop_items") is Array:
		all_items = data.get("shop_items")
	else:
		var file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var result = json.data
				if result is Dictionary and result.has("shop_items"):
					all_items = result["shop_items"]
	return all_items.filter(func(i): return i.get("category", "") == shop_category)

# ── Sell panel ──

func _rebuild_sell_panel() -> void:
	for child in sell_equipped_vbox.get_children():
		child.queue_free()
	for child in sell_bank_vbox.get_children():
		child.queue_free()
	for child in sell_potions_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return

	# Equipped — grouped by weapon type then armor
	var equipped: Dictionary = inv.get("equipped")
	var sell_groups := [
		{"label": "⚔ Melee",   "color": Color(1.0, 0.5, 0.3), "slots": ["weapon_melee"]},
		{"label": "🏹 Ranged",  "color": Color(0.4, 0.9, 0.5), "slots": ["weapon_ranged"]},
		{"label": "✦ Magic",   "color": Color(0.6, 0.4, 1.0), "slots": ["weapon_magic"]},
		{"label": "Helmet",    "color": Color(0.75, 0.75, 1.0), "slots": ["helmet"]},
		{"label": "Chest",     "color": Color(0.75, 0.75, 1.0), "slots": ["breastplate"]},
		{"label": "Pants",     "color": Color(0.75, 0.75, 1.0), "slots": ["pants"]},
		{"label": "Shoes",     "color": Color(0.75, 0.75, 1.0), "slots": ["shoes"]},
		{"label": "Gauntlets", "color": Color(0.75, 0.75, 1.0), "slots": ["gauntlets"]},
	]
	var has_equipped := false
	for grp in sell_groups:
		var grp_items := []
		for slot in grp["slots"]:
			var item: Dictionary = equipped.get(slot, {})
			if not item.is_empty():
				grp_items.append({"item": item, "slot": slot})
		if grp_items.is_empty():
			continue
		has_equipped = true
		_add_sell_sub_header(sell_equipped_vbox, grp["label"], grp["color"])
		for entry in grp_items:
			_add_sell_row(sell_equipped_vbox, entry["item"], entry["slot"], true)

	if not has_equipped:
		var empty := Label.new()
		empty.text = "Nothing equipped"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sell_equipped_vbox.add_child(empty)

	# Bank items — grouped by weapon type then individual armor slots then other
	var bank_items_arr: Array = inv.get("bank_items")
	var bank_groups := {
		"weapon_melee": [], "weapon_ranged": [], "weapon_magic": [],
		"helmet": [], "breastplate": [], "pants": [], "shoes": [], "gauntlets": [],
		"other": []
	}
	for item in bank_items_arr:
		if item.get("category", "") == "potion":
			continue
		var s: String = item.get("slot", "")
		if bank_groups.has(s):
			bank_groups[s].append(item)
		else:
			bank_groups["other"].append(item)

	var bank_group_cfg := [
		{"key": "weapon_melee",   "label": "⚔ Melee",   "color": Color(1.0, 0.5, 0.3)},
		{"key": "weapon_ranged",  "label": "🏹 Ranged",  "color": Color(0.4, 0.9, 0.5)},
		{"key": "weapon_magic",   "label": "✦ Magic",   "color": Color(0.6, 0.4, 1.0)},
		{"key": "helmet",         "label": "Helmet",    "color": Color(0.75, 0.75, 1.0)},
		{"key": "breastplate",    "label": "Chest",     "color": Color(0.75, 0.75, 1.0)},
		{"key": "pants",          "label": "Pants",     "color": Color(0.75, 0.75, 1.0)},
		{"key": "shoes",          "label": "Shoes",     "color": Color(0.75, 0.75, 1.0)},
		{"key": "gauntlets",      "label": "Gauntlets", "color": Color(0.75, 0.75, 1.0)},
		{"key": "other",          "label": "Other",     "color": Color(0.8, 0.8, 0.8)},
	]
	var has_bank := false
	for cfg in bank_group_cfg:
		var grp_arr: Array = bank_groups[cfg["key"]]
		if grp_arr.is_empty():
			continue
		has_bank = true
		_add_sell_sub_header(sell_bank_vbox, cfg["label"], cfg["color"])
		for item in grp_arr:
			_add_sell_row(sell_bank_vbox, item, "", false)

	if not has_bank:
		var empty := Label.new()
		empty.text = "Nothing to sell yet"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sell_bank_vbox.add_child(empty)

	# Carried potions
	var potions: Array = inv.get_all_potions()
	if potions.size() == 0:
		var empty := Label.new()
		empty.text = "No potions carried"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sell_potions_vbox.add_child(empty)
	else:
		for stack in potions:
			var item: Dictionary = stack["item"]
			var count: int = stack["count"]
			var pid: String = stack["id"]
			var sell_price: int = int(floor(float(item.get("cost", 5)) * 0.65))
			if sell_price < 1:
				sell_price = 1

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 8)
			sell_potions_vbox.add_child(hbox)

			var name_lbl := Label.new()
			name_lbl.text = "%s x%d" % [item.get("name", "???"), count]
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.custom_minimum_size = Vector2(140, 0)
			hbox.add_child(name_lbl)

			var price_lbl := Label.new()
			price_lbl.text = "-> %dg" % sell_price
			price_lbl.add_theme_font_size_override("font_size", 12)
			price_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
			price_lbl.custom_minimum_size = Vector2(50, 0)
			hbox.add_child(price_lbl)

			var sell_btn := Button.new()
			sell_btn.text = "Sell"
			sell_btn.custom_minimum_size = Vector2(50, 24)
			var p := pid
			var sp := sell_price
			sell_btn.pressed.connect(func(): _sell_potion(p, sp))
			hbox.add_child(sell_btn)

func _sell_potion(potion_id: String, sell_price: int) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	# Decrement potion count (reuse use_potion to remove one from stack)
	if not inv.carried_potions.has(potion_id):
		return
	var stack: Dictionary = inv.carried_potions[potion_id]
	if stack["count"] <= 0:
		return
	stack["count"] -= 1
	if stack["count"] <= 0:
		inv.carried_potions.erase(potion_id)
	inv.carried_gold += sell_price
	inv.inventory_changed.emit()
	_rebuild_sell_panel()
	_rebuild_shop_item_list()

func _add_sell_sub_header(parent: VBoxContainer, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _add_sell_row(parent: VBoxContainer, item: Dictionary, slot: String, is_equipped: bool) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = _get_stat_summary(item)
	stat_lbl.add_theme_font_size_override("font_size", 11)
	stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	stat_lbl.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(stat_lbl)

	var sell_price: int = int(floor(float(item.get("cost", 5)) * 0.65))
	if sell_price < 1:
		sell_price = 1

	var price_lbl := Label.new()
	price_lbl.text = "-> %dg" % sell_price
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	price_lbl.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(price_lbl)

	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(50, 24)
	var item_ref := item
	var slot_ref := slot
	var eq_ref := is_equipped
	sell_btn.pressed.connect(func(): _sell_item(item_ref, slot_ref, eq_ref))
	hbox.add_child(sell_btn)

var _sell_confirm_row: Node = null

func _show_sell_confirm(row: VBoxContainer, item: Dictionary, slot: String, is_equipped: bool, sell_price: int) -> void:
	# Dismiss any existing confirm
	if _sell_confirm_row != null and is_instance_valid(_sell_confirm_row):
		var old := _sell_confirm_row.get_node_or_null("SellConfirm")
		if old:
			old.queue_free()
	_sell_confirm_row = row

	var confirm := HBoxContainer.new()
	confirm.name = "SellConfirm"
	confirm.add_theme_constant_override("separation", 8)
	row.add_child(confirm)

	var lbl := Label.new()
	lbl.text = "Sell %s for %dg?" % [item.get("name", "item"), sell_price]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	confirm.add_child(lbl)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(45, 22)
	yes_btn.pressed.connect(func(): _sell_item(item, slot, is_equipped))
	confirm.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(45, 22)
	no_btn.pressed.connect(func(): confirm.queue_free(); _sell_confirm_row = null)
	confirm.add_child(no_btn)

func _sell_item(item: Dictionary, slot: String, is_equipped: bool) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return

	var sell_price: int = int(floor(float(item.get("cost", 5)) * 0.65))
	if sell_price < 1:
		sell_price = 1

	if is_equipped:
		inv.call("unequip_item", slot)
		# Remove from bank_items (unequip puts it there)
		var bank_arr: Array = inv.get("bank_items")
		for i in range(bank_arr.size() - 1, -1, -1):
			if bank_arr[i].get("name", "") == item.get("name", "") and bank_arr[i].get("slot", "") == item.get("slot", ""):
				bank_arr.remove_at(i)
				break
		inv.carried_gold += sell_price
		inv.inventory_changed.emit()
	else:
		var bank_arr: Array = inv.get("bank_items")
		var idx := bank_arr.find(item)
		if idx >= 0:
			bank_arr.remove_at(idx)
		inv.bank_gold += sell_price
		inv.bank_changed.emit()

	_rebuild_sell_panel()
	_rebuild_shop_item_list()

# ══════════════════════════════════════════════════════════
# INVENTORY & BANK TAB
# ══════════════════════════════════════════════════════════

func _build_inv_tab() -> void:
	inv_content = HBoxContainer.new()
	inv_content.add_theme_constant_override("separation", 0)
	inv_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_content.visible = false
	tab_content.add_child(inv_content)

	# ── LEFT PANE: Bank ──
	bank_vbox = VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 6)
	bank_vbox.custom_minimum_size = Vector2(400, 0)
	bank_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_content.add_child(bank_vbox)

	var bank_title := Label.new()
	bank_title.text = "Bank"
	bank_title.add_theme_font_size_override("font_size", 16)
	bank_title.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	bank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_vbox.add_child(bank_title)

	bank_locked_label = Label.new()
	bank_locked_label.text = "Return home to access bank"
	bank_locked_label.add_theme_font_size_override("font_size", 14)
	bank_locked_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	bank_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_locked_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bank_vbox.add_child(bank_locked_label)

	bank_controls = VBoxContainer.new()
	bank_controls.add_theme_constant_override("separation", 6)
	bank_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_vbox.add_child(bank_controls)

	# Gold labels
	bank_label = Label.new()
	bank_label.add_theme_font_size_override("font_size", 15)
	bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_controls.add_child(bank_label)

	carried_label = Label.new()
	carried_label.add_theme_font_size_override("font_size", 14)
	carried_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carried_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	bank_controls.add_child(carried_label)

	# Button row: Deposit All + Withdraw
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	bank_controls.add_child(btn_row)

	var deposit_btn := Button.new()
	deposit_btn.text = "Deposit All"
	deposit_btn.custom_minimum_size = Vector2(120, 36)
	deposit_btn.pressed.connect(_on_deposit_all)
	btn_row.add_child(deposit_btn)

	var withdraw_btn := Button.new()
	withdraw_btn.text = "Withdraw"
	withdraw_btn.custom_minimum_size = Vector2(120, 36)
	withdraw_btn.pressed.connect(_toggle_withdraw)
	btn_row.add_child(withdraw_btn)

	# Withdraw input row (hidden by default)
	withdraw_row = HBoxContainer.new()
	withdraw_row.alignment = BoxContainer.ALIGNMENT_CENTER
	withdraw_row.add_theme_constant_override("separation", 8)
	withdraw_row.visible = false
	bank_controls.add_child(withdraw_row)

	var all_btn := Button.new()
	all_btn.text = "Withdraw All"
	all_btn.custom_minimum_size = Vector2(100, 30)
	all_btn.pressed.connect(_on_withdraw_all)
	withdraw_row.add_child(all_btn)

	withdraw_input_label = Label.new()
	withdraw_input_label.text = "Amount: _"
	withdraw_input_label.add_theme_font_size_override("font_size", 16)
	withdraw_row.add_child(withdraw_input_label)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.custom_minimum_size = Vector2(80, 30)
	confirm_btn.pressed.connect(_on_withdraw_confirm)
	withdraw_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(70, 30)
	cancel_btn.pressed.connect(_hide_withdraw)
	withdraw_row.add_child(cancel_btn)

	# Separator before items
	var items_sep := HSeparator.new()
	bank_controls.add_child(items_sep)

	# ScrollContainer with categorized bank items
	var iscroll := ScrollContainer.new()
	iscroll.custom_minimum_size = Vector2(370, 260)
	iscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_controls.add_child(iscroll)

	items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 4)
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iscroll.add_child(items_vbox)

	# ── SEPARATOR ──
	var vsep := VSeparator.new()
	inv_content.add_child(vsep)

	# ── RIGHT PANE: Equipment + Stats ──
	equip_vbox = HBoxContainer.new()
	equip_vbox.add_theme_constant_override("separation", 0)
	equip_vbox.custom_minimum_size = Vector2(440, 0)
	equip_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_content.add_child(equip_vbox)

	# Filter sidebar
	_build_filter_sidebar()

	var eq_vsep := VSeparator.new()
	equip_vbox.add_child(eq_vsep)

	# Content area
	content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 6)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_vbox.add_child(content_vbox)

	var eq_title := Label.new()
	eq_title.text = "Equipment"
	eq_title.add_theme_font_size_override("font_size", 16)
	eq_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	eq_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(eq_title)

	var eq_scroll := ScrollContainer.new()
	eq_scroll.custom_minimum_size = Vector2(320, 220)
	content_vbox.add_child(eq_scroll)

	slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 4)
	slots_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_scroll.add_child(slots_vbox)

	# Potions section
	potions_sep_node = HSeparator.new()
	content_vbox.add_child(potions_sep_node)

	pot_title_node = Label.new()
	pot_title_node.text = "Potions"
	pot_title_node.add_theme_font_size_override("font_size", 14)
	pot_title_node.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	content_vbox.add_child(pot_title_node)

	potions_vbox = VBoxContainer.new()
	potions_vbox.add_theme_constant_override("separation", 4)
	content_vbox.add_child(potions_vbox)

	stats_sep_node = HSeparator.new()
	content_vbox.add_child(stats_sep_node)

	st_title_node = Label.new()
	st_title_node.text = "Stats"
	st_title_node.add_theme_font_size_override("font_size", 14)
	st_title_node.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	content_vbox.add_child(st_title_node)

	stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 5)
	content_vbox.add_child(stats_vbox)

# ── Bank controls ──

func _toggle_withdraw() -> void:
	withdraw_active = true
	withdraw_input_text = ""
	withdraw_input_label.text = "Amount: _"
	withdraw_row.visible = true

func _hide_withdraw() -> void:
	withdraw_active = false
	withdraw_input_text = ""
	withdraw_row.visible = false

func _rebuild_items_list() -> void:
	for child in items_vbox.get_children():
		child.queue_free()
	confirm_discard_row = null

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var bank_items_arr: Array = inv.get("bank_items")
	if bank_items_arr.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No items in bank."
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_vbox.add_child(empty_lbl)
		return

	# Group items by category
	var categories := {"weapon": [], "armor": [], "potion": [], "other": []}
	for item in bank_items_arr:
		var cat: String = item.get("category", "other")
		if not categories.has(cat):
			cat = "other"
		categories[cat].append(item)

	# Split weapons and armor into individual sub-groups
	var weapon_melee: Array = categories["weapon"].filter(func(i): return i.get("slot") == "weapon_melee")
	var weapon_ranged: Array = categories["weapon"].filter(func(i): return i.get("slot") == "weapon_ranged")
	var weapon_magic: Array = categories["weapon"].filter(func(i): return i.get("slot") == "weapon_magic")
	var armor_helmet: Array    = categories["armor"].filter(func(i): return i.get("slot") == "helmet")
	var armor_chest: Array     = categories["armor"].filter(func(i): return i.get("slot") == "breastplate")
	var armor_pants: Array     = categories["armor"].filter(func(i): return i.get("slot") == "pants")
	var armor_shoes: Array     = categories["armor"].filter(func(i): return i.get("slot") == "shoes")
	var armor_gauntlets: Array = categories["armor"].filter(func(i): return i.get("slot") == "gauntlets")

	var cat_config := [
		{"items": weapon_melee,      "label": "⚔ Melee",   "color": Color(1.0, 0.5, 0.3)},
		{"items": weapon_ranged,     "label": "🏹 Ranged",  "color": Color(0.4, 0.9, 0.5)},
		{"items": weapon_magic,      "label": "✦ Magic",   "color": Color(0.6, 0.4, 1.0)},
		{"items": armor_helmet,      "label": "Helmet",    "color": Color(0.75, 0.75, 1.0)},
		{"items": armor_chest,       "label": "Chest",     "color": Color(0.75, 0.75, 1.0)},
		{"items": armor_pants,       "label": "Pants",     "color": Color(0.75, 0.75, 1.0)},
		{"items": armor_shoes,       "label": "Shoes",     "color": Color(0.75, 0.75, 1.0)},
		{"items": armor_gauntlets,   "label": "Gauntlets", "color": Color(0.75, 0.75, 1.0)},
		{"items": categories["potion"], "label": "Potions","color": Color(0.5, 1.0, 0.6)},
		{"items": categories["other"],  "label": "Other",  "color": Color(0.8, 0.8, 0.8)},
	]

	for cfg in cat_config:
		var items_in_cat: Array = cfg["items"]
		if items_in_cat.size() == 0:
			continue
		_add_inv_category_header(cfg["label"], cfg["color"])
		for i in range(items_in_cat.size()):
			var item: Dictionary = items_in_cat[i]
			var row := VBoxContainer.new()
			row.add_theme_constant_override("separation", 2)
			items_vbox.add_child(row)

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 8)
			row.add_child(hbox)

			var name_lbl := Label.new()
			name_lbl.text = item.get("name", "???")
			name_lbl.add_theme_font_size_override("font_size", 13)
			name_lbl.custom_minimum_size = Vector2(130, 0)
			hbox.add_child(name_lbl)

			var stat_lbl := Label.new()
			stat_lbl.text = _get_stat_summary(item)
			stat_lbl.add_theme_font_size_override("font_size", 11)
			stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
			stat_lbl.custom_minimum_size = Vector2(100, 0)
			hbox.add_child(stat_lbl)

			var item_ref := item
			var equip_btn := Button.new()
			equip_btn.text = "Equip"
			equip_btn.custom_minimum_size = Vector2(55, 24)
			equip_btn.pressed.connect(func(): _equip_item(item_ref))
			hbox.add_child(equip_btn)

			var discard_btn := Button.new()
			discard_btn.text = "Discard"
			discard_btn.custom_minimum_size = Vector2(55, 24)
			discard_btn.pressed.connect(func(): _show_discard_confirm(row, item_ref, i))
			hbox.add_child(discard_btn)

func _add_inv_category_header(text: String, color: Color) -> void:
	var sep := HSeparator.new()
	items_vbox.add_child(sep)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	items_vbox.add_child(lbl)

func _equip_item(item: Dictionary) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	inv.call("equip_item", item)
	_rebuild_items_list()

func _show_discard_confirm(row: VBoxContainer, item: Dictionary, idx: int) -> void:
	if confirm_discard_row != null and is_instance_valid(confirm_discard_row):
		var old: Node = confirm_discard_row.get_node_or_null("DiscardConfirm")
		if old:
			old.queue_free()
	confirm_discard_row = row

	var hbox := HBoxContainer.new()
	hbox.name = "DiscardConfirm"
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	var lbl := Label.new()
	lbl.text = "Discard %s?" % item.get("name", "item")
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	hbox.add_child(lbl)

	var yes_btn := Button.new()
	yes_btn.text = "Yes"
	yes_btn.custom_minimum_size = Vector2(45, 22)
	yes_btn.pressed.connect(func(): _discard_item(item))
	hbox.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(45, 22)
	no_btn.pressed.connect(func(): hbox.queue_free(); confirm_discard_row = null)
	hbox.add_child(no_btn)

func _discard_item(item: Dictionary) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var bank_items_arr: Array = inv.get("bank_items")
	var idx := bank_items_arr.find(item)
	if idx >= 0:
		bank_items_arr.remove_at(idx)
		inv.bank_changed.emit()
	_rebuild_items_list()

# ── Gold operations ──

func _on_deposit_all() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var carried: int = int(inv.get("carried_gold"))
	if carried > 0:
		inv.call("deposit_to_bank", carried, [])
	_refresh_gold()

func _on_withdraw_all() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var bank: int = int(inv.get("bank_gold"))
	if bank > 0:
		inv.call("withdraw_gold", bank)
	_hide_withdraw()
	_refresh_gold()

func _on_withdraw_confirm() -> void:
	var amount: int = int(withdraw_input_text) if withdraw_input_text.is_valid_int() else 0
	if amount > 0:
		var inv: Node = get_node_or_null("/root/InventorySystem")
		if inv != null:
			inv.call("withdraw_gold", amount)
	_hide_withdraw()
	_refresh_gold()

# ── Equipment filter sidebar ──

func _build_filter_sidebar() -> void:
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(90, 0)
	sidebar.add_theme_constant_override("separation", 2)
	equip_vbox.add_child(sidebar)

	var filters := [
		["All", "all"],
		["⚔ Melee", "melee"],
		["🏹 Ranged", "ranged"],
		["✦ Magic", "magic"],
		["_separator_", ""],
		["Helmet", "helmet"],
		["Chest", "breastplate"],
		["Pants", "pants"],
		["Shoes", "shoes"],
		["Gauntlets", "gauntlets"],
		["🧪 Potions", "potions"],
		["📊 Stats", "stats"],
	]

	for f in filters:
		if f[0] == "_separator_":
			var lbl := Label.new()
			lbl.text = "─── Armor ───"
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
			sidebar.add_child(lbl)
			continue

		var btn := Button.new()
		btn.text = f[0]
		btn.custom_minimum_size = Vector2(88, 22)
		btn.add_theme_font_size_override("font_size", 11)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var key: String = f[1]
		btn.pressed.connect(func(): _set_equip_filter(key))
		sidebar.add_child(btn)
		filter_buttons[f[1]] = btn

	_update_filter_highlight()

func _set_equip_filter(key: String) -> void:
	equip_filter = key
	_update_filter_highlight()
	_rebuild_slots()
	_rebuild_potions()
	_rebuild_stats()
	_update_equip_section_visibility()

func _update_filter_highlight() -> void:
	for k in filter_buttons:
		var btn: Button = filter_buttons[k]
		if k == equip_filter:
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func _update_equip_section_visibility() -> void:
	var show_potions: bool = equip_filter == "all" or equip_filter == "potions"
	var show_stats: bool = equip_filter == "all" or equip_filter == "stats"
	potions_sep_node.visible = show_potions
	pot_title_node.visible = show_potions
	potions_vbox.visible = show_potions
	stats_sep_node.visible = show_stats
	st_title_node.visible = show_stats
	stats_vbox.visible = show_stats

# ── Equipment (right pane of Inventory tab) ──

func _rebuild_slots() -> void:
	for child in slots_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return

	# Hide slots entirely for potions/stats-only filters
	if equip_filter == "potions" or equip_filter == "stats":
		return

	var equipped: Dictionary = inv.get("equipped")
	var slot_labels := {
		"weapon_melee": "Melee Weapon",
		"weapon_ranged": "Ranged Weapon",
		"weapon_magic": "Magic Weapon",
		"helmet": "Helmet",
		"breastplate": "Breastplate",
		"pants": "Pants",
		"shoes": "Shoes",
		"gauntlets": "Gauntlets",
	}

	# Weapons — split by type
	if equip_filter in ["all", "melee"]:
		_add_section_header("⚔ Melee", Color(1.0, 0.5, 0.3))
		_add_slot_row("weapon_melee", slot_labels["weapon_melee"], equipped.get("weapon_melee", {}), inv)

	if equip_filter in ["all", "ranged"]:
		_add_section_header("🏹 Ranged", Color(0.4, 0.9, 0.5))
		_add_slot_row("weapon_ranged", slot_labels["weapon_ranged"], equipped.get("weapon_ranged", {}), inv)

	if equip_filter in ["all", "magic"]:
		_add_section_header("✦ Magic", Color(0.6, 0.4, 1.0))
		_add_slot_row("weapon_magic", slot_labels["weapon_magic"], equipped.get("weapon_magic", {}), inv)

	# Armor — each piece as its own sub-section
	var armor_config := [
		{"slot": "helmet",      "label": "Helmet",     "color": Color(0.75, 0.75, 1.0)},
		{"slot": "breastplate", "label": "Chest",      "color": Color(0.75, 0.75, 1.0)},
		{"slot": "pants",       "label": "Pants",      "color": Color(0.75, 0.75, 1.0)},
		{"slot": "shoes",       "label": "Shoes",      "color": Color(0.75, 0.75, 1.0)},
		{"slot": "gauntlets",   "label": "Gauntlets",  "color": Color(0.75, 0.75, 1.0)},
	]
	for cfg in armor_config:
		var s: String = cfg["slot"]
		if equip_filter != "all" and equip_filter != s:
			continue
		_add_section_header(cfg["label"], cfg["color"])
		_add_slot_row(s, slot_labels[s], equipped.get(s, {}), inv)

func _add_section_header(text: String, color: Color = Color(0.9, 0.8, 0.5)) -> void:
	var sep := HSeparator.new()
	slots_vbox.add_child(sep)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	slots_vbox.add_child(lbl)

func _add_slot_row(slot: String, label: String, item: Dictionary, inv: Node, tag: Dictionary = {}) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	slots_vbox.add_child(hbox)

	# Type tag label
	if not tag.is_empty() and tag.get("text", "") != "":
		var tag_lbl := Label.new()
		tag_lbl.text = tag["text"]
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", tag["color"])
		tag_lbl.custom_minimum_size = Vector2(55, 0)
		hbox.add_child(tag_lbl)

		var slot_lbl := Label.new()
		slot_lbl.text = ":"
		slot_lbl.add_theme_font_size_override("font_size", 12)
		slot_lbl.custom_minimum_size = Vector2(10, 0)
		hbox.add_child(slot_lbl)
	else:
		var slot_lbl := Label.new()
		slot_lbl.text = label + ":"
		slot_lbl.add_theme_font_size_override("font_size", 12)
		slot_lbl.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(slot_lbl)

	if item.is_empty():
		var empty := Label.new()
		empty.text = "Empty"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(empty)
	else:
		var name_lbl := Label.new()
		name_lbl.text = item.get("name", "???")
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_lbl)

		var stat_lbl := Label.new()
		stat_lbl.text = _get_stat_summary(item)
		stat_lbl.add_theme_font_size_override("font_size", 11)
		stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		hbox.add_child(stat_lbl)

		var unequip_btn := Button.new()
		unequip_btn.text = "Unequip"
		unequip_btn.custom_minimum_size = Vector2(70, 24)
		var s := slot
		unequip_btn.pressed.connect(func(): inv.call("unequip_item", s))
		hbox.add_child(unequip_btn)

func _rebuild_potions() -> void:
	for child in potions_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var potions: Array = inv.get_all_potions()
	if potions.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No potions carried."
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		potions_vbox.add_child(empty_lbl)
		return

	for stack in potions:
		var item: Dictionary = stack["item"]
		var count: int = stack["count"]
		var pid: String = stack["id"]

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		potions_vbox.add_child(hbox)

		var name_lbl := Label.new()
		name_lbl.text = "%s x%d" % [item.get("name", "???"), count]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.custom_minimum_size = Vector2(170, 0)
		hbox.add_child(name_lbl)

		var effect_lbl := Label.new()
		effect_lbl.text = _get_stat_summary(item)
		effect_lbl.add_theme_font_size_override("font_size", 11)
		effect_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		effect_lbl.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(effect_lbl)

		var use_btn := Button.new()
		use_btn.text = "Use"
		use_btn.custom_minimum_size = Vector2(50, 24)
		var p := pid
		use_btn.pressed.connect(func(): inv.use_potion(p))
		hbox.add_child(use_btn)

func _rebuild_stats() -> void:
	for child in stats_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return

	_add_stat_line("Total Defense:", str(int(inv.get("total_defense"))), Color(0.5, 0.8, 1.0))
	_add_stat_line("Melee Dmg Bonus:", "+%d" % int(inv.get("melee_damage_bonus")), Color(0.9, 0.6, 0.4))
	_add_stat_line("Ranged Dmg Bonus:", "+%d" % int(inv.get("ranged_damage_bonus")), Color(0.6, 0.9, 0.5))
	_add_stat_line("Magic Dmg Bonus:", "+%d" % int(inv.get("magic_damage_bonus")), Color(0.7, 0.5, 1.0))
	_add_stat_line("Speed Bonus:", "+%d" % int(inv.get("speed_bonus")), Color(0.9, 0.9, 0.5))

	var sep := HSeparator.new()
	stats_vbox.add_child(sep)

	_add_stat_line("Carried Gold:", "%d" % int(inv.get("carried_gold")), Color(0.9, 0.8, 0.2))
	_add_stat_line("Bank Gold:", "%d" % int(inv.get("bank_gold")), Color(0.7, 0.7, 0.5))

func _add_stat_line(label: String, value: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	stats_vbox.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", color)
	hbox.add_child(val)

func _refresh_gold() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	bank_label.text = "Bank:  %d gold" % int(inv.get("bank_gold"))
	carried_label.text = "In pocket:  %d gold" % int(inv.get("carried_gold"))

func _update_bank_visibility() -> void:
	bank_locked_label.visible = not at_home
	bank_controls.visible = at_home

# ══════════════════════════════════════════════════════════
# REFRESH + HELPERS
# ══════════════════════════════════════════════════════════

func _refresh() -> void:
	if active_tab == 0:
		_update_shop_tab_colors()
		_rebuild_shop_item_list()
		_rebuild_sell_panel()
	else:
		_update_bank_visibility()
		_refresh_gold()
		_rebuild_slots()
		_rebuild_potions()
		_rebuild_stats()
		_update_equip_section_visibility()
		_rebuild_items_list()

func _get_stat_summary(item: Dictionary) -> String:
	var parts: Array = []
	if item.has("damage_bonus"):
		parts.append("+%d dmg" % int(item.get("damage_bonus")))
	if item.has("defense"):
		parts.append("+%d def" % int(item.get("defense")))
	if item.has("heal_amount"):
		parts.append("+%d HP" % int(item.get("heal_amount")))
	if item.has("speed_bonus"):
		parts.append("+%d spd" % int(item.get("speed_bonus")))
	if item.has("attack_speed_bonus"):
		parts.append("+%.0f%% atk spd" % (float(item.get("attack_speed_bonus")) * 100.0))
	return ", ".join(parts) if parts.size() > 0 else ""

# ══════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_I or key.keycode == KEY_E:
			menu_closed.emit()
			return
		# Withdraw numeric input
		if active_tab == 1 and withdraw_active and at_home:
			if key.keycode >= KEY_0 and key.keycode <= KEY_9:
				withdraw_input_text += str(key.keycode - KEY_0)
				withdraw_input_label.text = "Amount: %s" % withdraw_input_text
			elif key.keycode == KEY_BACKSPACE and withdraw_input_text.length() > 0:
				withdraw_input_text = withdraw_input_text.substr(0, withdraw_input_text.length() - 1)
				withdraw_input_label.text = "Amount: %s" % (withdraw_input_text if withdraw_input_text.length() > 0 else "_")
			elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
				_on_withdraw_confirm()
