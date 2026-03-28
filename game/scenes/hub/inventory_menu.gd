extends CanvasLayer

signal inventory_closed

var main_panel: PanelContainer
var slots_vbox: VBoxContainer
var stats_vbox: VBoxContainer

func _ready() -> void:
	_build_ui()
	_refresh()
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.inventory_changed.connect(_refresh)
		inv.bank_changed.connect(_refresh)

func _build_ui() -> void:
	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(620, 460)
	add_child(main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	main_panel.add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Two columns
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root_vbox.add_child(columns)

	# Left column: equipment slots
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.custom_minimum_size = Vector2(360, 0)
	columns.add_child(left)

	var eq_title := Label.new()
	eq_title.text = "Equipment"
	eq_title.add_theme_font_size_override("font_size", 15)
	eq_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	left.add_child(eq_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 340)
	left.add_child(scroll)

	slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 4)
	slots_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(slots_vbox)

	# Right column: stats
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.custom_minimum_size = Vector2(200, 0)
	columns.add_child(right)

	var st_title := Label.new()
	st_title.text = "Stats"
	st_title.add_theme_font_size_override("font_size", 15)
	st_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	right.add_child(st_title)

	stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 6)
	right.add_child(stats_vbox)

	# Close hint
	var hint := Label.new()
	hint.text = "Press ESC or I to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(hint)

func _refresh() -> void:
	_rebuild_slots()
	_rebuild_stats()

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
	var slot_order := ["weapon_melee", "weapon_ranged", "weapon_magic", "helmet", "breastplate", "pants", "shoes", "gauntlets"]

	# Add section headers
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

func _get_stat_summary(item: Dictionary) -> String:
	var parts: Array = []
	if item.has("damage_bonus"):
		parts.append("+%d dmg" % int(item.get("damage_bonus")))
	if item.has("defense"):
		parts.append("+%d def" % int(item.get("defense")))
	if item.has("speed_bonus"):
		parts.append("+%d spd" % int(item.get("speed_bonus")))
	return ", ".join(parts) if parts.size() > 0 else ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_I:
			inventory_closed.emit()
