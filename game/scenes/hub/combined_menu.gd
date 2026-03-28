extends CanvasLayer

signal menu_closed

var at_home: bool = false

# UI references
var main_panel: PanelContainer
var bank_vbox: VBoxContainer
var equip_vbox: VBoxContainer
var stats_vbox: VBoxContainer
var slots_vbox: VBoxContainer
var items_vbox: VBoxContainer

# Bank gold sub-panels
var bank_controls: VBoxContainer
var bank_locked_label: Label

# Bank UI state
enum BankScreen { GOLD, WITHDRAW, ITEMS }
var bank_screen: BankScreen = BankScreen.GOLD
var withdraw_input_text: String = ""
var withdraw_input_label: Label
var gold_panel: VBoxContainer
var withdraw_panel: VBoxContainer
var items_panel: VBoxContainer
var bank_label: Label
var carried_label: Label
var confirm_discard_row: Node = null

# Tab buttons (for highlighting)
var gold_tab_btn: Button
var items_tab_btn: Button

func _ready() -> void:
	_build_ui()
	_refresh()
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.inventory_changed.connect(_refresh)
		inv.bank_changed.connect(_refresh)

func _build_ui() -> void:
	# Full-screen backdrop so the panel is centered correctly
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# Centering container
	var screen_fill := Control.new()
	screen_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_fill)

	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(920, 520)

	# Solid opaque background
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
	screen_fill.add_child(main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	main_panel.add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = "Inventory & Bank"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Two-pane layout
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 0)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	# ── LEFT PANE: Bank ──────────────────────────────────────
	bank_vbox = VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 6)
	bank_vbox.custom_minimum_size = Vector2(400, 0)
	bank_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(bank_vbox)

	var bank_title := Label.new()
	bank_title.text = "Bank"
	bank_title.add_theme_font_size_override("font_size", 16)
	bank_title.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	bank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_vbox.add_child(bank_title)

	# Bank locked message (shown when not at home)
	bank_locked_label = Label.new()
	bank_locked_label.text = "Return home to access bank"
	bank_locked_label.add_theme_font_size_override("font_size", 14)
	bank_locked_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	bank_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_locked_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bank_vbox.add_child(bank_locked_label)

	# Bank controls container (shown when at home)
	bank_controls = VBoxContainer.new()
	bank_controls.add_theme_constant_override("separation", 6)
	bank_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_vbox.add_child(bank_controls)

	# Tab row
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 16)
	bank_controls.add_child(tab_row)

	gold_tab_btn = Button.new()
	gold_tab_btn.text = "Gold"
	gold_tab_btn.custom_minimum_size = Vector2(90, 28)
	gold_tab_btn.pressed.connect(_show_gold_screen)
	tab_row.add_child(gold_tab_btn)

	items_tab_btn = Button.new()
	items_tab_btn.text = "Items"
	items_tab_btn.custom_minimum_size = Vector2(90, 28)
	items_tab_btn.pressed.connect(_show_items_screen)
	tab_row.add_child(items_tab_btn)

	var tab_sep := HSeparator.new()
	bank_controls.add_child(tab_sep)

	# ── Gold sub-panel ──
	gold_panel = VBoxContainer.new()
	gold_panel.add_theme_constant_override("separation", 10)
	bank_controls.add_child(gold_panel)

	bank_label = Label.new()
	bank_label.add_theme_font_size_override("font_size", 15)
	bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_panel.add_child(bank_label)

	carried_label = Label.new()
	carried_label.add_theme_font_size_override("font_size", 14)
	carried_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carried_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	gold_panel.add_child(carried_label)

	var gold_sep := HSeparator.new()
	gold_panel.add_child(gold_sep)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	gold_panel.add_child(btn_row)

	var deposit_btn := Button.new()
	deposit_btn.text = "Deposit All"
	deposit_btn.custom_minimum_size = Vector2(120, 36)
	deposit_btn.pressed.connect(_on_deposit_all)
	btn_row.add_child(deposit_btn)

	var withdraw_btn := Button.new()
	withdraw_btn.text = "Withdraw"
	withdraw_btn.custom_minimum_size = Vector2(120, 36)
	withdraw_btn.pressed.connect(_show_withdraw_screen)
	btn_row.add_child(withdraw_btn)

	# ── Withdraw sub-panel ──
	withdraw_panel = VBoxContainer.new()
	withdraw_panel.add_theme_constant_override("separation", 10)
	withdraw_panel.visible = false
	bank_controls.add_child(withdraw_panel)

	var wtitle := Label.new()
	wtitle.text = "Withdraw Gold"
	wtitle.add_theme_font_size_override("font_size", 16)
	wtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	withdraw_panel.add_child(wtitle)

	withdraw_input_label = Label.new()
	withdraw_input_label.text = "Amount: _"
	withdraw_input_label.add_theme_font_size_override("font_size", 20)
	withdraw_input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	withdraw_panel.add_child(withdraw_input_label)

	var key_hint := Label.new()
	key_hint.text = "Type an amount, then press Enter"
	key_hint.add_theme_font_size_override("font_size", 11)
	key_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	withdraw_panel.add_child(key_hint)

	var wbtn_row := HBoxContainer.new()
	wbtn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wbtn_row.add_theme_constant_override("separation", 12)
	withdraw_panel.add_child(wbtn_row)

	var all_btn := Button.new()
	all_btn.text = "Withdraw All"
	all_btn.custom_minimum_size = Vector2(110, 34)
	all_btn.pressed.connect(_on_withdraw_all)
	wbtn_row.add_child(all_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.custom_minimum_size = Vector2(90, 34)
	confirm_btn.pressed.connect(_on_withdraw_confirm)
	wbtn_row.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(70, 34)
	back_btn.pressed.connect(_show_gold_screen)
	wbtn_row.add_child(back_btn)

	# ── Items sub-panel ──
	items_panel = VBoxContainer.new()
	items_panel.add_theme_constant_override("separation", 6)
	items_panel.visible = false
	items_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_controls.add_child(items_panel)

	var iscroll := ScrollContainer.new()
	iscroll.custom_minimum_size = Vector2(370, 300)
	iscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_panel.add_child(iscroll)

	items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 4)
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iscroll.add_child(items_vbox)

	# ── SEPARATOR ──────────────────────────────────────
	var vsep := VSeparator.new()
	columns.add_child(vsep)

	# ── RIGHT PANE: Equipment + Stats ──────────────────────────────────────
	equip_vbox = VBoxContainer.new()
	equip_vbox.add_theme_constant_override("separation", 6)
	equip_vbox.custom_minimum_size = Vector2(440, 0)
	equip_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(equip_vbox)

	var eq_title := Label.new()
	eq_title.text = "Equipment"
	eq_title.add_theme_font_size_override("font_size", 16)
	eq_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	eq_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_vbox.add_child(eq_title)

	var eq_scroll := ScrollContainer.new()
	eq_scroll.custom_minimum_size = Vector2(420, 220)
	equip_vbox.add_child(eq_scroll)

	slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 4)
	slots_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_scroll.add_child(slots_vbox)

	var stats_sep := HSeparator.new()
	equip_vbox.add_child(stats_sep)

	var st_title := Label.new()
	st_title.text = "Stats"
	st_title.add_theme_font_size_override("font_size", 14)
	st_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	equip_vbox.add_child(st_title)

	stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 5)
	equip_vbox.add_child(stats_vbox)

	# ── Close hint ──
	var bottom_sep := HSeparator.new()
	root_vbox.add_child(bottom_sep)

	var hint := Label.new()
	hint.text = "Press ESC / I / E to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(hint)

# ── Refresh ──────────────────────────────────────

func _refresh() -> void:
	_update_bank_visibility()
	_refresh_gold()
	_rebuild_slots()
	_rebuild_stats()
	if bank_screen == BankScreen.ITEMS:
		_rebuild_items_list()

func _update_bank_visibility() -> void:
	bank_locked_label.visible = not at_home
	bank_controls.visible = at_home

func _refresh_gold() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	bank_label.text = "Bank:  %d gold" % int(inv.get("bank_gold"))
	carried_label.text = "In pocket:  %d gold" % int(inv.get("carried_gold"))

# ── Bank Screens ──────────────────────────────────────

func _show_gold_screen() -> void:
	bank_screen = BankScreen.GOLD
	withdraw_input_text = ""
	gold_panel.visible = true
	withdraw_panel.visible = false
	items_panel.visible = false
	_refresh_gold()

func _show_withdraw_screen() -> void:
	bank_screen = BankScreen.WITHDRAW
	withdraw_input_text = ""
	withdraw_input_label.text = "Amount: _"
	gold_panel.visible = false
	withdraw_panel.visible = true
	items_panel.visible = false

func _show_items_screen() -> void:
	bank_screen = BankScreen.ITEMS
	gold_panel.visible = false
	withdraw_panel.visible = false
	items_panel.visible = true
	_rebuild_items_list()

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

	for i in range(bank_items_arr.size()):
		var item: Dictionary = bank_items_arr[i]
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

		var slot_lbl := Label.new()
		slot_lbl.text = item.get("slot", "")
		slot_lbl.add_theme_font_size_override("font_size", 11)
		slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		slot_lbl.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(slot_lbl)

		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.custom_minimum_size = Vector2(55, 24)
		var item_ref := item
		equip_btn.pressed.connect(func(): _equip_item(item_ref))
		hbox.add_child(equip_btn)

		var discard_btn := Button.new()
		discard_btn.text = "Discard"
		discard_btn.custom_minimum_size = Vector2(55, 24)
		discard_btn.pressed.connect(func(): _show_discard_confirm(row, item_ref, i))
		hbox.add_child(discard_btn)

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

# ── Gold operations ──────────────────────────────────────

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
	_show_gold_screen()

func _on_withdraw_confirm() -> void:
	var amount: int = int(withdraw_input_text) if withdraw_input_text.is_valid_int() else 0
	if amount > 0:
		var inv: Node = get_node_or_null("/root/InventorySystem")
		if inv != null:
			inv.call("withdraw_gold", amount)
	_show_gold_screen()

# ── Equipment (right pane) ──────────────────────────────────────

func _rebuild_slots() -> void:
	for child in slots_vbox.get_children():
		child.queue_free()

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
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

	_add_section_header("Weapons")
	for slot in ["weapon_melee", "weapon_ranged", "weapon_magic"]:
		_add_slot_row(slot, slot_labels[slot], equipped.get(slot, {}), inv)

	_add_section_header("Armor")
	for slot in ["helmet", "breastplate", "pants", "shoes", "gauntlets"]:
		_add_slot_row(slot, slot_labels[slot], equipped.get(slot, {}), inv)

func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	slots_vbox.add_child(lbl)

func _add_slot_row(slot: String, label: String, item: Dictionary, inv: Node) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	slots_vbox.add_child(hbox)

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

# ── Helpers ──────────────────────────────────────

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
	return ", ".join(parts) if parts.size() > 0 else ""

# ── Input ──────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_I or key.keycode == KEY_E:
			menu_closed.emit()
			return
		if bank_screen == BankScreen.WITHDRAW and at_home:
			if key.keycode >= KEY_0 and key.keycode <= KEY_9:
				withdraw_input_text += str(key.keycode - KEY_0)
				withdraw_input_label.text = "Amount: %s" % withdraw_input_text
			elif key.keycode == KEY_BACKSPACE and withdraw_input_text.length() > 0:
				withdraw_input_text = withdraw_input_text.substr(0, withdraw_input_text.length() - 1)
				withdraw_input_label.text = "Amount: %s" % (withdraw_input_text if withdraw_input_text.length() > 0 else "_")
			elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
				_on_withdraw_confirm()
