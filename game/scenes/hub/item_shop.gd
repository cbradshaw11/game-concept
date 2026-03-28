extends CanvasLayer

signal shop_closed

var main_panel: PanelContainer
var item_list_vbox: VBoxContainer
var carried_label: Label
var active_category: String = "weapon"
var confirm_row_parent: Node = null

# Category buttons
var weapon_btn: Button
var potion_btn: Button
var armor_btn: Button

func _ready() -> void:
	_build_ui()
	_show_category("weapon")

func _build_ui() -> void:
	# Dimmed backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# CenterContainer for true screen-center placement
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(560, 500)

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

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Item Shop"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Category tabs
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 12)
	vbox.add_child(tab_row)

	weapon_btn = Button.new()
	weapon_btn.text = "Weapons"
	weapon_btn.custom_minimum_size = Vector2(100, 32)
	weapon_btn.pressed.connect(func(): _show_category("weapon"))
	tab_row.add_child(weapon_btn)

	potion_btn = Button.new()
	potion_btn.text = "Potions"
	potion_btn.custom_minimum_size = Vector2(100, 32)
	potion_btn.pressed.connect(func(): _show_category("potion"))
	tab_row.add_child(potion_btn)

	armor_btn = Button.new()
	armor_btn.text = "Armor"
	armor_btn.custom_minimum_size = Vector2(100, 32)
	armor_btn.pressed.connect(func(): _show_category("armor"))
	tab_row.add_child(armor_btn)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Scrollable item list
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 320)
	vbox.add_child(scroll)

	item_list_vbox = VBoxContainer.new()
	item_list_vbox.add_theme_constant_override("separation", 6)
	item_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_list_vbox)

	# Footer: carried gold + close hint
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 30)
	vbox.add_child(footer)

	carried_label = Label.new()
	carried_label.add_theme_font_size_override("font_size", 14)
	carried_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	footer.add_child(carried_label)

	var hint := Label.new()
	hint.text = "ESC to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	footer.add_child(hint)

func _show_category(cat: String) -> void:
	active_category = cat
	confirm_row_parent = null
	_update_tab_colors()
	_rebuild_item_list()

func _update_tab_colors() -> void:
	var active_col := Color(1.0, 0.9, 0.5)
	var normal_col := Color(0.8, 0.8, 0.8)
	weapon_btn.add_theme_color_override("font_color", active_col if active_category == "weapon" else normal_col)
	potion_btn.add_theme_color_override("font_color", active_col if active_category == "potion" else normal_col)
	armor_btn.add_theme_color_override("font_color", active_col if active_category == "armor" else normal_col)

func _rebuild_item_list() -> void:
	for child in item_list_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	var carried: int = int(inv.get("carried_gold")) if inv else 0
	carried_label.text = "Carried: %dg" % carried

	var items: Array = _get_shop_items()

	if active_category == "weapon":
		# Sub-headers for weapon slots
		var melee_items: Array = items.filter(func(i): return i.get("slot") == "weapon_melee")
		var ranged_items: Array = items.filter(func(i): return i.get("slot") == "weapon_ranged")
		var magic_items: Array = items.filter(func(i): return i.get("slot") == "weapon_magic")
		if melee_items.size() > 0:
			_add_sub_header("Melee")
			for item in melee_items:
				_add_item_row(item, carried)
		if ranged_items.size() > 0:
			_add_sub_header("Ranged")
			for item in ranged_items:
				_add_item_row(item, carried)
		if magic_items.size() > 0:
			_add_sub_header("Magic")
			for item in magic_items:
				_add_item_row(item, carried)
	else:
		for item in items:
			_add_item_row(item, carried)

func _add_sub_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	item_list_vbox.add_child(lbl)

func _add_item_row(item: Dictionary, carried: int) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	item_list_vbox.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.custom_minimum_size = Vector2(160, 0)
	hbox.add_child(name_lbl)

	# Stats summary
	var stats_text := _get_stat_summary(item)
	var stat_lbl := Label.new()
	stat_lbl.text = stats_text
	stat_lbl.add_theme_font_size_override("font_size", 12)
	stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	stat_lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(stat_lbl)

	# Cost
	var cost: int = int(item.get("cost", 0))
	var cost_lbl := Label.new()
	cost_lbl.text = "%dg" % cost
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	cost_lbl.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(cost_lbl)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 28)
	if carried < cost:
		buy_btn.disabled = true
		buy_btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		buy_btn.pressed.connect(func(): _show_confirm(row, item))
	hbox.add_child(buy_btn)

func _show_confirm(row: VBoxContainer, item: Dictionary) -> void:
	# Remove any existing confirm row
	if confirm_row_parent != null and is_instance_valid(confirm_row_parent):
		var old_confirm: Node = confirm_row_parent.get_node_or_null("ConfirmRow")
		if old_confirm:
			old_confirm.queue_free()
	confirm_row_parent = row

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
	no_btn.pressed.connect(func(): confirm.queue_free(); confirm_row_parent = null)
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
	confirm_row_parent = null
	_rebuild_item_list()

func _get_stat_summary(item: Dictionary) -> String:
	var parts: Array = []
	if item.has("damage_bonus"):
		parts.append("+%d damage" % int(item.get("damage_bonus")))
	if item.has("defense"):
		parts.append("+%d defense" % int(item.get("defense")))
	if item.has("heal_amount"):
		parts.append("+%d HP" % int(item.get("heal_amount")))
	if item.has("speed_bonus"):
		parts.append("+%d speed" % int(item.get("speed_bonus")))
	if item.has("attack_speed_bonus"):
		parts.append("+%.0f%% atk spd" % (float(item.get("attack_speed_bonus")) * 100.0))
	return ", ".join(parts) if parts.size() > 0 else ""

func _get_shop_items() -> Array:
	var data: Node = get_node_or_null("/root/DataStore")
	var all_items: Array = []
	if data and data.has_method("get") and data.get("shop_items") is Array:
		all_items = data.get("shop_items")
	else:
		# Fallback: load directly
		var file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var result = json.data
				if result is Dictionary and result.has("shop_items"):
					all_items = result["shop_items"]
	return all_items.filter(func(i): return i.get("category", "") == active_category)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			shop_closed.emit()
