extends CanvasLayer
class_name FlowUI

signal start_run_pressed(ring_id: String)
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_selected(weapon_id: String)
signal vendor_purchase_pressed(upgrade_id: String)

@onready var prep_screen: PanelContainer = $PrepScreen
@onready var run_screen: PanelContainer = $RunScreen
@onready var prep_status: Label = $PrepScreen/PrepVBox/PrepStatus
@onready var loadout_select: OptionButton = $PrepScreen/PrepVBox/LoadoutSelect
@onready var loadout_summary: Label = $PrepScreen/PrepVBox/LoadoutSummary
@onready var run_status: Label = $RunScreen/RunVBox/RunStatus
@onready var run_loadout: Label = $RunScreen/RunVBox/RunLoadout

# Vendor & Ring 2 nodes (created dynamically)
var vendor_panel: PanelContainer = null
var vendor_loot_label: Label = null
var vendor_upgrade_buttons: Dictionary = {}  # upgrade_id -> Button

var run_base_status: String = ""
var objective_status: String = ""

func _ready() -> void:
	_setup_ring2_button()
	_setup_vendor_panel()
	_setup_history_button()
	_show_prep()

func _on_start_run_button_pressed() -> void:
	_play_click()
	start_run_pressed.emit("inner")

func _on_start_ring2_button_pressed() -> void:
	_play_click()
	start_run_pressed.emit("mid")

func _on_resolve_encounter_button_pressed() -> void:
	_play_click()
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	_play_click()
	extract_pressed.emit()

func _on_die_button_pressed() -> void:
	_play_click()
	die_pressed.emit()

func _on_loadout_select_item_selected(index: int) -> void:
	var weapon_id: Variant = loadout_select.get_item_metadata(index)
	loadout_selected.emit(str(weapon_id))

func _on_vendor_button_pressed(upgrade_id: String) -> void:
	_play_click()
	vendor_purchase_pressed.emit(upgrade_id)

func _play_click() -> void:
	if AudioManager:
		AudioManager.play_ui_click()

# ── Screen visibility ─────────────────────────────────────────────────────────

func _show_prep() -> void:
	prep_screen.visible = true
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if AudioManager:
		AudioManager.play_sanctuary_music()

func _show_run() -> void:
	prep_screen.visible = false
	run_screen.visible = true
	if vendor_panel:
		vendor_panel.visible = false

func _show_vendor() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = true
		_refresh_vendor_ui()

# ── Public API called from main.gd ───────────────────────────────────────────

func on_run_started(seed: int) -> void:
	_show_run()
	run_base_status = "Run active (seed %d)" % seed
	_refresh_run_status()

func set_available_loadouts(weapons: Array) -> void:
	loadout_select.clear()
	for weapon in weapons:
		var weapon_id := str(weapon.get("id", ""))
		loadout_select.add_item(weapon_id)
		loadout_select.set_item_metadata(loadout_select.get_item_count() - 1, weapon_id)
	if loadout_select.get_item_count() > 0:
		loadout_select.select(0)
		_on_loadout_select_item_selected(0)

func set_current_loadout(weapon_id: String) -> void:
	loadout_summary.text = "Selected loadout: %s" % weapon_id
	run_loadout.text = "Loadout: %s" % weapon_id

func on_encounter_resolved(xp_gain: int, loot_gain: int) -> void:
	run_base_status = "Encounter won: +%d XP, +%d Loot" % [xp_gain, loot_gain]
	_refresh_run_status()

func on_extracted(total_xp: int, total_loot: int) -> void:
	_show_prep()
	prep_status.text = "Extracted successfully. Banked XP: %d  Loot: %d" % [total_xp, total_loot]
	_refresh_ring_buttons()

func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
	_show_prep()
	prep_status.text = "You fell in the Ring.\nLost XP: %d  Lost Loot: %d" % [unbanked_xp, unbanked_loot]
	_refresh_ring_buttons()

func on_idle_ready() -> void:
	_show_prep()
	run_base_status = ""
	objective_status = ""
	prep_status.text = "Choose your loadout and enter the Ring."
	_refresh_ring_buttons()

func on_objective_started(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	var target := int(contract.get("target", 1))
	objective_status = "%s  0/%d  (active)" % [contract_id, target]
	_refresh_run_status()

func on_objective_progress(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	var progress := int(contract.get("progress", 0))
	var target := int(contract.get("target", 1))
	var state := str(contract.get("state", "active"))
	objective_status = "%s  %d/%d  (%s)" % [contract_id, progress, target, state]
	_refresh_run_status()

func on_extract_blocked(contract: Dictionary) -> void:
	var progress := int(contract.get("progress", 0))
	var target := int(contract.get("target", 1))
	run_base_status = "⚠ Extraction locked — objective incomplete (%d/%d)" % [progress, target]
	_refresh_run_status()

func on_objective_failed(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	objective_status = "%s  failed" % contract_id
	_refresh_run_status()

func refresh_vendor() -> void:
	_refresh_vendor_ui()

# ── Internal helpers ──────────────────────────────────────────────────────────

func _refresh_run_status() -> void:
	var lines: PackedStringArray = []
	if run_base_status != "":
		lines.append(run_base_status)
	if objective_status != "":
		lines.append("Objective: %s" % objective_status)
	run_status.text = "\n".join(lines)

func _refresh_ring_buttons() -> void:
	# Show Ring 2 button only if unlocked
	var ring2_btn := prep_screen.find_child("Ring2Button", true, false)
	if ring2_btn is Button:
		var unlocked := GameState.has_extracted_from("inner")
		ring2_btn.visible = unlocked
		ring2_btn.disabled = not unlocked

# ── Dynamic UI construction ───────────────────────────────────────────────────

func _setup_ring2_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "Ring2Button"
	btn.text = "▶  Enter Ring 2 (Mid Reaches)"
	btn.visible = false  # Hidden until unlocked
	btn.pressed.connect(_on_start_ring2_button_pressed)
	prep_vbox.add_child(btn)

func _setup_vendor_panel() -> void:
	# Build a simple vendor panel as a sibling of PrepScreen
	vendor_panel = PanelContainer.new()
	vendor_panel.name = "VendorPanel"
	vendor_panel.visible = false
	vendor_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vendor_panel)

	var vbox := VBoxContainer.new()
	vendor_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🏪  VENDOR — Spend your loot"
	vbox.add_child(title)

	vendor_loot_label = Label.new()
	vendor_loot_label.text = "Loot: 0"
	vbox.add_child(vendor_loot_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Upgrade buttons
	for upg in DataStore.get_vendor_upgrades():
		var upg_id := str(upg.get("id", ""))
		var upg_name := str(upg.get("name", upg_id))
		var upg_desc := str(upg.get("description", ""))
		var upg_cost := int(upg.get("cost", 0))
		var max_level := int(upg.get("max_level", 1))

		var row := HBoxContainer.new()
		vbox.add_child(row)

		var lbl := Label.new()
		lbl.text = "%s — %s  (cost: %d loot, max %d)" % [upg_name, upg_desc, upg_cost, max_level]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn := Button.new()
		btn.name = "VendorBtn_" + upg_id
		btn.text = "Buy"
		var cap_id := upg_id  # capture for lambda
		btn.pressed.connect(func(): _on_vendor_button_pressed(cap_id))
		row.add_child(btn)
		vendor_upgrade_buttons[upg_id] = btn

	var back_btn := Button.new()
	back_btn.text = "← Back to Sanctuary"
	back_btn.pressed.connect(func(): _show_prep())
	vbox.add_child(back_btn)

	# Wire the existing vendor button in PrepScreen if it exists
	var existing_vendor_btn := prep_screen.find_child("VendorButton", true, false)
	if existing_vendor_btn is Button:
		existing_vendor_btn.pressed.connect(func(): _show_vendor())
	else:
		# Add a vendor button to prep vbox
		var vendor_nav_btn := Button.new()
		vendor_nav_btn.name = "VendorButton"
		vendor_nav_btn.text = "🏪  Visit Vendor"
		vendor_nav_btn.pressed.connect(func():
			_play_click()
			_show_vendor()
		)
		var prep_vbox := prep_screen.get_node("PrepVBox")
		if prep_vbox:
			prep_vbox.add_child(vendor_nav_btn)

func _setup_history_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "HistoryButton"
	btn.text = "📜  Run History"
	btn.pressed.connect(func():
		_play_click()
		_show_run_history()
	)
	prep_vbox.add_child(btn)

func _refresh_vendor_ui() -> void:
	if vendor_loot_label:
		vendor_loot_label.text = "Loot available: %d" % GameState.banked_loot

	for upg_id in vendor_upgrade_buttons:
		var btn: Button = vendor_upgrade_buttons[upg_id]
		var upg := DataStore.get_vendor_upgrade(upg_id)
		var cost := int(upg.get("cost", 9999))
		var max_level := int(upg.get("max_level", 1))
		var current_level := GameState.get_upgrade_level(upg_id)
		var can_buy := current_level < max_level and GameState.banked_loot >= cost
		btn.text = "Buy (Lv %d/%d)" % [current_level, max_level]
		btn.disabled = not can_buy

func _show_run_history() -> void:
	# Display run history in prep_status for simplicity
	var history := GameState.get_run_history()
	if history.is_empty():
		prep_status.text = "No runs yet. Enter the Ring!"
		return
	var lines: PackedStringArray = []
	lines.append("── Run History (last %d) ──" % history.size())
	var start_idx := max(0, history.size() - 10)
	for i in range(history.size() - 1, start_idx - 1, -1):
		var entry: Dictionary = history[i]
		var ring := str(entry.get("ring", "?"))
		var outcome := "✓ Extracted" if bool(entry.get("extracted", false)) else "✗ Died"
		var xp := int(entry.get("unbanked_xp", 0))
		var loot := int(entry.get("unbanked_loot", 0))
		lines.append("Ring: %s | %s | XP: %d Loot: %d" % [ring, outcome, xp, loot])
	prep_status.text = "\n".join(lines)
