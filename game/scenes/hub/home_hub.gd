extends CanvasLayer

signal hub_closed

# UI state
enum Screen { GOLD_MAIN, WITHDRAW_AMOUNT, ITEMS }
var current_screen: Screen = Screen.GOLD_MAIN
var withdraw_input_text: String = ""
var confirm_discard_item: Dictionary = {}
var confirm_discard_row: Node = null

# Panels built in code
var main_panel: PanelContainer
var withdraw_panel: PanelContainer
var items_panel: PanelContainer
var bank_label: Label
var carried_label: Label
var withdraw_input_label: Label
var items_vbox: VBoxContainer

# Tab buttons
var gold_tab_btn: Button
var items_tab_btn: Button

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	# ── MAIN PANEL (Gold tab) ──────────────────────────────────
	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(460, 340)
	add_child(main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Home Bank"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Tab row
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 16)
	vbox.add_child(tab_row)

	gold_tab_btn = Button.new()
	gold_tab_btn.text = "Gold"
	gold_tab_btn.custom_minimum_size = Vector2(100, 30)
	gold_tab_btn.pressed.connect(_show_main_screen)
	tab_row.add_child(gold_tab_btn)

	items_tab_btn = Button.new()
	items_tab_btn.text = "Items"
	items_tab_btn.custom_minimum_size = Vector2(100, 30)
	items_tab_btn.pressed.connect(_show_items_screen)
	tab_row.add_child(items_tab_btn)

	var sep1b := HSeparator.new()
	vbox.add_child(sep1b)

	# Bank balance
	bank_label = Label.new()
	bank_label.add_theme_font_size_override("font_size", 15)
	bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bank_label)

	# Carried gold
	carried_label = Label.new()
	carried_label.add_theme_font_size_override("font_size", 14)
	carried_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carried_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	vbox.add_child(carried_label)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var deposit_btn := Button.new()
	deposit_btn.text = "Deposit All"
	deposit_btn.custom_minimum_size = Vector2(130, 40)
	deposit_btn.pressed.connect(_on_deposit_all)
	btn_row.add_child(deposit_btn)

	var withdraw_btn := Button.new()
	withdraw_btn.text = "Withdraw"
	withdraw_btn.custom_minimum_size = Vector2(130, 40)
	withdraw_btn.pressed.connect(_show_withdraw_screen)
	btn_row.add_child(withdraw_btn)

	# Close hint
	var hint := Label.new()
	hint.text = "Press ESC to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# ── WITHDRAW PANEL ──────────────────────────────────────
	withdraw_panel = PanelContainer.new()
	withdraw_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	withdraw_panel.custom_minimum_size = Vector2(380, 240)
	withdraw_panel.visible = false
	add_child(withdraw_panel)

	var wvbox := VBoxContainer.new()
	wvbox.add_theme_constant_override("separation", 14)
	withdraw_panel.add_child(wvbox)

	var wtitle := Label.new()
	wtitle.text = "Withdraw Gold"
	wtitle.add_theme_font_size_override("font_size", 18)
	wtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wvbox.add_child(wtitle)

	var wsep := HSeparator.new()
	wvbox.add_child(wsep)

	withdraw_input_label = Label.new()
	withdraw_input_label.text = "Amount: 0"
	withdraw_input_label.add_theme_font_size_override("font_size", 22)
	withdraw_input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wvbox.add_child(withdraw_input_label)

	var key_hint := Label.new()
	key_hint.text = "Type an amount, then press Enter"
	key_hint.add_theme_font_size_override("font_size", 11)
	key_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wvbox.add_child(key_hint)

	var wsep2 := HSeparator.new()
	wvbox.add_child(wsep2)

	var wbtn_row := HBoxContainer.new()
	wbtn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wbtn_row.add_theme_constant_override("separation", 16)
	wvbox.add_child(wbtn_row)

	var all_btn := Button.new()
	all_btn.text = "Withdraw All"
	all_btn.custom_minimum_size = Vector2(130, 40)
	all_btn.pressed.connect(_on_withdraw_all)
	wbtn_row.add_child(all_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.custom_minimum_size = Vector2(100, 40)
	confirm_btn.pressed.connect(_on_withdraw_confirm)
	wbtn_row.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(80, 40)
	back_btn.pressed.connect(_show_main_screen)
	wbtn_row.add_child(back_btn)

	# ── ITEMS PANEL ──────────────────────────────────────
	items_panel = PanelContainer.new()
	items_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	items_panel.custom_minimum_size = Vector2(500, 420)
	items_panel.visible = false
	add_child(items_panel)

	var ivbox := VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 10)
	items_panel.add_child(ivbox)

	var ititle := Label.new()
	ititle.text = "Bank Items"
	ititle.add_theme_font_size_override("font_size", 18)
	ititle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ivbox.add_child(ititle)

	# Tab row (duplicated for items panel)
	var itab_row := HBoxContainer.new()
	itab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	itab_row.add_theme_constant_override("separation", 16)
	ivbox.add_child(itab_row)

	var igold_btn := Button.new()
	igold_btn.text = "Gold"
	igold_btn.custom_minimum_size = Vector2(100, 30)
	igold_btn.pressed.connect(_show_main_screen)
	itab_row.add_child(igold_btn)

	var iitems_btn := Button.new()
	iitems_btn.text = "Items"
	iitems_btn.custom_minimum_size = Vector2(100, 30)
	iitems_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	itab_row.add_child(iitems_btn)

	var isep := HSeparator.new()
	ivbox.add_child(isep)

	var iscroll := ScrollContainer.new()
	iscroll.custom_minimum_size = Vector2(460, 300)
	ivbox.add_child(iscroll)

	items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 4)
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iscroll.add_child(items_vbox)

	var ihint := Label.new()
	ihint.text = "Press ESC to close"
	ihint.add_theme_font_size_override("font_size", 11)
	ihint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ihint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ivbox.add_child(ihint)

func _refresh() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	bank_label.text = "Bank:  %d gold" % int(inv.get("bank_gold"))
	carried_label.text = "In pocket:  %d gold" % int(inv.get("carried_gold"))

func _show_main_screen() -> void:
	current_screen = Screen.GOLD_MAIN
	withdraw_input_text = ""
	main_panel.visible = true
	withdraw_panel.visible = false
	items_panel.visible = false
	_refresh()

func _show_withdraw_screen() -> void:
	current_screen = Screen.WITHDRAW_AMOUNT
	withdraw_input_text = ""
	withdraw_input_label.text = "Amount: _"
	main_panel.visible = false
	withdraw_panel.visible = true
	items_panel.visible = false

func _show_items_screen() -> void:
	current_screen = Screen.ITEMS
	main_panel.visible = false
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
	var bank_items: Array = inv.get("bank_items")
	if bank_items.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No items in bank."
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_vbox.add_child(empty_lbl)
		return

	for i in range(bank_items.size()):
		var item: Dictionary = bank_items[i]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		items_vbox.add_child(row)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row.add_child(hbox)

		var name_lbl := Label.new()
		name_lbl.text = item.get("name", "???")
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.custom_minimum_size = Vector2(150, 0)
		hbox.add_child(name_lbl)

		var stat_lbl := Label.new()
		stat_lbl.text = _get_stat_summary(item)
		stat_lbl.add_theme_font_size_override("font_size", 11)
		stat_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		stat_lbl.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(stat_lbl)

		var slot_lbl := Label.new()
		slot_lbl.text = item.get("slot", "")
		slot_lbl.add_theme_font_size_override("font_size", 11)
		slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		slot_lbl.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(slot_lbl)

		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.custom_minimum_size = Vector2(60, 26)
		var item_ref := item
		equip_btn.pressed.connect(func(): _equip_item(item_ref))
		hbox.add_child(equip_btn)

		var discard_btn := Button.new()
		discard_btn.text = "Discard"
		discard_btn.custom_minimum_size = Vector2(60, 26)
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
	yes_btn.custom_minimum_size = Vector2(50, 24)
	yes_btn.pressed.connect(func(): _discard_item(item))
	hbox.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "No"
	no_btn.custom_minimum_size = Vector2(50, 24)
	no_btn.pressed.connect(func(): hbox.queue_free(); confirm_discard_row = null)
	hbox.add_child(no_btn)

func _discard_item(item: Dictionary) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var bank_items: Array = inv.get("bank_items")
	var idx := bank_items.find(item)
	if idx >= 0:
		bank_items.remove_at(idx)
		inv.bank_changed.emit()
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
	return ", ".join(parts) if parts.size() > 0 else ""

func _on_deposit_all() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var carried: int = int(inv.get("carried_gold"))
	if carried > 0:
		inv.call("deposit_to_bank", carried, [])
	_refresh()

func _on_withdraw_all() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	var bank: int = int(inv.get("bank_gold"))
	if bank > 0:
		inv.call("withdraw_gold", bank)
	_show_main_screen()

func _on_withdraw_confirm() -> void:
	var amount: int = int(withdraw_input_text) if withdraw_input_text.is_valid_int() else 0
	if amount > 0:
		var inv: Node = get_node_or_null("/root/InventorySystem")
		if inv != null:
			inv.call("withdraw_gold", amount)
	_show_main_screen()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			hub_closed.emit()
			return
		if current_screen == Screen.WITHDRAW_AMOUNT:
			# Number input
			if key.keycode >= KEY_0 and key.keycode <= KEY_9:
				withdraw_input_text += str(key.keycode - KEY_0)
				withdraw_input_label.text = "Amount: %s" % withdraw_input_text
			elif key.keycode == KEY_BACKSPACE and withdraw_input_text.length() > 0:
				withdraw_input_text = withdraw_input_text.substr(0, withdraw_input_text.length() - 1)
				withdraw_input_label.text = "Amount: %s" % (withdraw_input_text if withdraw_input_text.length() > 0 else "_")
			elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
				_on_withdraw_confirm()
