extends CanvasLayer

signal hub_closed

# UI state
enum Screen { MAIN, WITHDRAW_AMOUNT }
var current_screen: Screen = Screen.MAIN
var withdraw_input_text: String = ""

# Panels built in code
var main_panel: PanelContainer
var withdraw_panel: PanelContainer
var bank_label: Label
var carried_label: Label
var withdraw_input_label: Label

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	# ── MAIN PANEL ──────────────────────────────────────────
	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(420, 260)
	add_child(main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	main_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🏠  Home Bank"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

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

func _refresh() -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return
	bank_label.text = "Bank:  %d gold" % int(inv.get("bank_gold"))
	carried_label.text = "In pocket:  %d gold" % int(inv.get("carried_gold"))

func _show_main_screen() -> void:
	current_screen = Screen.MAIN
	withdraw_input_text = ""
	main_panel.visible = true
	withdraw_panel.visible = false
	_refresh()

func _show_withdraw_screen() -> void:
	current_screen = Screen.WITHDRAW_AMOUNT
	withdraw_input_text = ""
	withdraw_input_label.text = "Amount: _"
	main_panel.visible = false
	withdraw_panel.visible = true

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
