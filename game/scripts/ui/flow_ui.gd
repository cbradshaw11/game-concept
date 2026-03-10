extends CanvasLayer
class_name FlowUI

signal start_run_pressed
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_selected(weapon_id: String)

@onready var prep_screen: VBoxContainer = $PrepScreen
@onready var run_screen: VBoxContainer = $RunScreen
@onready var prep_status: Label = $PrepScreen/PrepStatus
@onready var loadout_select: OptionButton = $PrepScreen/LoadoutSelect
@onready var loadout_summary: Label = $PrepScreen/LoadoutSummary
@onready var run_status: Label = $RunScreen/RunStatus
@onready var run_loadout: Label = $RunScreen/RunLoadout

func _ready() -> void:
	_show_prep()

func _on_start_run_button_pressed() -> void:
	start_run_pressed.emit()

func _on_resolve_encounter_button_pressed() -> void:
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	extract_pressed.emit()

func _on_die_button_pressed() -> void:
	die_pressed.emit()

func _on_loadout_select_item_selected(index: int) -> void:
	var weapon_id := loadout_select.get_item_metadata(index)
	loadout_selected.emit(str(weapon_id))

func _show_prep() -> void:
	prep_screen.visible = true
	run_screen.visible = false

func _show_run() -> void:
	prep_screen.visible = false
	run_screen.visible = true

func on_run_started(seed: int) -> void:
	_show_run()
	run_status.text = "Run active (seed %d)" % seed

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
	run_status.text = "Encounter won: +%d XP, +%d Loot" % [xp_gain, loot_gain]

func on_extracted(total_xp: int, total_loot: int) -> void:
	_show_prep()
	prep_status.text = "Extracted. Banked XP: %d, Loot: %d" % [total_xp, total_loot]

func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
	_show_prep()
	prep_status.text = "You died. Remaining unbanked XP: %d, Loot: %d" % [unbanked_xp, unbanked_loot]

func on_idle_ready() -> void:
	_show_prep()
	prep_status.text = "Sanctuary: choose loadout and start run"
