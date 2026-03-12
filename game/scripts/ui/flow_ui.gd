extends CanvasLayer
class_name FlowUI

signal start_run_pressed
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_selected(weapon_id: String)
signal descend_warden_pressed

@onready var prep_screen: VBoxContainer = $PrepScreen
@onready var run_screen: VBoxContainer = $RunScreen
@onready var prep_status: Label = $PrepScreen/PrepStatus
@onready var loadout_select: OptionButton = $PrepScreen/LoadoutSelect
@onready var loadout_summary: Label = $PrepScreen/LoadoutSummary
@onready var ring_selector: OptionButton = $PrepScreen/RingSelector
@onready var run_status: Label = $RunScreen/RunStatus
@onready var run_loadout: Label = $RunScreen/RunLoadout
@onready var death_panel: PanelContainer = $DeathPanel
@onready var ring_label: Label = $DeathPanel/VBox/RingLabel
@onready var encounters_label: Label = $DeathPanel/VBox/EncountersLabel
@onready var xp_label: Label = $DeathPanel/VBox/XPLabel
@onready var loot_label: Label = $DeathPanel/VBox/LootLabel
@onready var return_button: Button = $DeathPanel/VBox/ReturnButton
@onready var descend_warden_button: Button = $RunScreen/DescendWardenButton
@onready var credits_panel: PanelContainer = $CreditsPanel

var run_base_status: String = ""
var objective_status: String = ""

func _ready() -> void:
	_show_prep()
	return_button.pressed.connect(_on_return_to_sanctuary)
	descend_warden_button.pressed.connect(_on_descend_warden_pressed)
	_populate_ring_selector()

func _populate_ring_selector() -> void:
	ring_selector.clear()
	ring_selector.add_item("Ring 1 - The Inner Way")
	ring_selector.set_item_metadata(0, "inner")
	ring_selector.add_item("Ring 2 - The Mid Path")
	ring_selector.set_item_metadata(1, "mid")
	ring_selector.add_item("Ring 3 - The Outer Reaches")
	ring_selector.set_item_metadata(2, "outer")
	_refresh_ring_selector()

func _refresh_ring_selector() -> void:
	var rings_data: Array = DataStore.rings.get("rings", [])
	var thresholds := {}
	for r in rings_data:
		thresholds[r.get("id", "")] = r.get("loot_gate_threshold", 0)

	# inner (index 0): always accessible
	ring_selector.set_item_disabled(0, false)
	ring_selector.set_item_text(0, "Ring 1 - The Inner Way")

	# mid (index 1): requires "inner" in rings_cleared AND banked_loot >= 50
	var mid_threshold: int = thresholds.get("mid", 50)
	var mid_progression_locked: bool = "inner" not in GameState.rings_cleared
	var mid_loot_locked: bool = GameState.banked_loot < mid_threshold
	var mid_locked: bool = mid_progression_locked or mid_loot_locked
	ring_selector.set_item_disabled(1, mid_locked)
	if mid_locked and mid_loot_locked and not mid_progression_locked:
		ring_selector.set_item_text(1, "Ring 2 (requires %d loot)" % mid_threshold)
	else:
		ring_selector.set_item_text(1, "Ring 2 - The Mid Path")

	# outer (index 2): requires "mid" in rings_cleared AND banked_loot >= 150
	var outer_threshold: int = thresholds.get("outer", 150)
	var outer_progression_locked: bool = "mid" not in GameState.rings_cleared
	var outer_loot_locked: bool = GameState.banked_loot < outer_threshold
	var outer_locked: bool = outer_progression_locked or outer_loot_locked
	ring_selector.set_item_disabled(2, outer_locked)
	if outer_locked and outer_loot_locked and not outer_progression_locked:
		ring_selector.set_item_text(2, "Ring 3 (requires %d loot)" % outer_threshold)
	else:
		ring_selector.set_item_text(2, "Ring 3 - The Outer Reaches")

	# Clamp selection to first available ring
	for i in range(ring_selector.item_count):
		if not ring_selector.is_item_disabled(i):
			ring_selector.select(i)
			_on_ring_selected(i)
			break

func _on_ring_selected(index: int) -> void:
	var ring_ids = ["inner", "mid", "outer"]
	if index < ring_ids.size():
		GameState.current_ring = ring_ids[index]

func _on_start_run_button_pressed() -> void:
	start_run_pressed.emit()

func _on_resolve_encounter_button_pressed() -> void:
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	extract_pressed.emit()

func _on_die_button_pressed() -> void:
	die_pressed.emit()

func _on_descend_warden_pressed() -> void:
	descend_warden_pressed.emit()

func _on_loadout_select_item_selected(index: int) -> void:
	var weapon_id: String = str(loadout_select.get_item_metadata(index))
	loadout_selected.emit(weapon_id)

func _show_prep() -> void:
	prep_screen.visible = true
	run_screen.visible = false

func _show_run() -> void:
	prep_screen.visible = false
	run_screen.visible = true
	_refresh_warden_option()

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
	_refresh_warden_option()

func on_extracted(total_xp: int, total_loot: int) -> void:
	_show_prep()
	prep_status.text = "Extracted. Banked XP: %d, Loot: %d" % [total_xp, total_loot]
	_refresh_ring_selector()

func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
	ring_label.text = "Ring Reached: %s" % GameState.current_ring
	encounters_label.text = "Encounters Cleared: %d" % GameState.encounters_cleared
	xp_label.text = "XP Lost: %d" % unbanked_xp
	loot_label.text = "Loot Lost: %d" % unbanked_loot
	death_panel.visible = true

func _on_return_to_sanctuary() -> void:
	death_panel.visible = false
	on_idle_ready()

func on_idle_ready() -> void:
	_show_prep()
	run_base_status = ""
	objective_status = ""
	prep_status.text = "Sanctuary: choose loadout and start run"
	_refresh_ring_selector()

func on_objective_started(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	var target := int(contract.get("target", 1))
	objective_status = "%s 0/%d (active)" % [contract_id, target]
	_refresh_run_status()

func on_objective_progress(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	var progress := int(contract.get("progress", 0))
	var target := int(contract.get("target", 1))
	var state := str(contract.get("state", "active"))
	objective_status = "%s %d/%d (%s)" % [contract_id, progress, target, state]
	_refresh_run_status()

func on_extract_blocked(contract: Dictionary) -> void:
	var progress := int(contract.get("progress", 0))
	var target := int(contract.get("target", 1))
	run_base_status = "Extraction locked: objective incomplete (%d/%d)" % [progress, target]
	_refresh_run_status()

func on_objective_failed(contract: Dictionary) -> void:
	var contract_id := str(contract.get("id", "contract"))
	objective_status = "%s failed" % contract_id
	_refresh_run_status()

func _refresh_run_status() -> void:
	var lines: PackedStringArray = []
	if run_base_status != "":
		lines.append(run_base_status)
	if objective_status != "":
		lines.append("Objective: %s" % objective_status)
	run_status.text = "\n".join(lines)

func _refresh_warden_option() -> void:
	var show_warden: bool = GameState.current_ring == "outer" \
		and GameState.encounters_cleared >= 3 \
		and not GameState.warden_defeated
	descend_warden_button.visible = show_warden

func show_credits() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	death_panel.visible = false
	credits_panel.visible = true

func _on_begin_new_journey_pressed() -> void:
	credits_panel.visible = false
	on_idle_ready()
