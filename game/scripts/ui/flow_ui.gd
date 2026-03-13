extends CanvasLayer
class_name FlowUI

signal start_run_pressed
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_selected(weapon_id: String)
signal descend_warden_pressed
signal upgrade_selected(upgrade: Dictionary)
signal back_to_menu_requested

@onready var prep_screen: VBoxContainer = $PrepScreen
@onready var run_screen: VBoxContainer = $RunScreen
@onready var prep_status: Label = $PrepScreen/PrepStatus
@onready var loadout_select: OptionButton = $PrepScreen/LoadoutSelect
@onready var loadout_summary: Label = $PrepScreen/LoadoutSummary
@onready var weapon_stat_panel: VBoxContainer = $PrepScreen/WeaponStatPanel
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
@onready var ring_display: Label = $RunScreen/RingDisplay
@onready var pause_menu: PanelContainer = $PauseMenu
@onready var resume_button: Button = $PauseMenu/VBoxContainer/ResumeButton
@onready var quit_to_menu_button: Button = $PauseMenu/VBoxContainer/QuitButton
@onready var settings_button: Button = $PauseMenu/VBoxContainer/SettingsButton
@onready var upgrade_draw_panel: PanelContainer = $UpgradeDrawPanel
@onready var upgrade_card_0: Button = $UpgradeDrawPanel/VBoxContainer/HBoxContainer/UpgradeCard0
@onready var upgrade_card_1: Button = $UpgradeDrawPanel/VBoxContainer/HBoxContainer/UpgradeCard1
@onready var upgrade_card_2: Button = $UpgradeDrawPanel/VBoxContainer/HBoxContainer/UpgradeCard2
@onready var upgrade_list_label: Label = $RunScreen/UpgradeListLabel
@onready var upgrade_toast: Label = $UpgradeToast
@onready var vendor_button: Button = $PrepScreen/VendorButton

var run_base_status: String = ""
var objective_status: String = ""
var _is_paused: bool = false
var _current_draw: Array = []
var _vendor_instance: Node = null

var _ui_sfx_player: AudioStreamPlayer = null
var _ui_click_stream: AudioStream = null
var _ui_upgrade_stream: AudioStream = null

func _ready() -> void:
	_setup_ui_audio()
	_show_prep()
	return_button.pressed.connect(_on_return_to_sanctuary)
	return_button.pressed.connect(_play_ui_click)
	descend_warden_button.pressed.connect(_on_descend_warden_pressed)
	descend_warden_button.pressed.connect(_play_ui_click)
	resume_button.pressed.connect(_on_resume_pressed)
	resume_button.pressed.connect(_play_ui_click)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	quit_to_menu_button.pressed.connect(_play_ui_click)
	settings_button.pressed.connect(_on_settings_button_pressed)
	settings_button.pressed.connect(_play_ui_click)
	upgrade_card_0.pressed.connect(_on_upgrade_card_selected.bind(0))
	upgrade_card_0.pressed.connect(_play_ui_upgrade_select)
	upgrade_card_1.pressed.connect(_on_upgrade_card_selected.bind(1))
	upgrade_card_1.pressed.connect(_play_ui_upgrade_select)
	upgrade_card_2.pressed.connect(_on_upgrade_card_selected.bind(2))
	upgrade_card_2.pressed.connect(_play_ui_upgrade_select)
	vendor_button.pressed.connect(_on_visit_vendor_pressed)
	vendor_button.pressed.connect(_play_ui_click)
	upgrade_toast.visible = false
	_populate_ring_selector()

func _setup_ui_audio() -> void:
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.name = "UISFXPlayer"
	_ui_sfx_player.bus = "SFX"
	add_child(_ui_sfx_player)
	var click_path := "res://audio/ui_click.wav"
	if ResourceLoader.exists(click_path):
		_ui_click_stream = load(click_path)
	var upgrade_path := "res://audio/ui_upgrade_select.wav"
	if ResourceLoader.exists(upgrade_path):
		_ui_upgrade_stream = load(upgrade_path)

func _play_ui_click() -> void:
	if _ui_sfx_player and _ui_click_stream:
		_ui_sfx_player.stream = _ui_click_stream
		_ui_sfx_player.play()

func _play_ui_upgrade_select() -> void:
	if _ui_sfx_player and _ui_upgrade_stream:
		_ui_sfx_player.stream = _ui_upgrade_stream
		_ui_sfx_player.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_pause_input()

func _handle_pause_input() -> void:
	if not run_screen.visible:
		return
	if upgrade_draw_panel.visible:
		return
	if _is_paused:
		_unpause()
	else:
		_pause()

func _pause() -> void:
	_is_paused = true
	pause_menu.visible = true
	get_tree().paused = true

func _unpause() -> void:
	_is_paused = false
	pause_menu.visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_unpause()

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	_is_paused = false
	pause_menu.visible = false
	GameState.die_in_run()
	on_idle_ready()

func _on_settings_button_pressed() -> void:
	var settings_scene := load("res://scenes/ui/settings.tscn")
	var settings_instance := settings_scene.instantiate()
	add_child(settings_instance)
	settings_instance.settings_closed.connect(_on_settings_closed.bind(settings_instance))

func _on_settings_closed(settings_instance: Node) -> void:
	settings_instance.queue_free()

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
	_play_ui_click()
	start_run_pressed.emit()

func _on_resolve_encounter_button_pressed() -> void:
	_play_ui_click()
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	_play_ui_click()
	if GameState.current_ring in ["inner", "mid"]:
		_show_upgrade_draw()
	else:
		extract_pressed.emit()

func _on_die_button_pressed() -> void:
	_play_ui_click()
	die_pressed.emit()

func _on_descend_warden_pressed() -> void:
	descend_warden_pressed.emit()

func _on_loadout_select_item_selected(index: int) -> void:
	var weapon_id: String = str(loadout_select.get_item_metadata(index))
	loadout_selected.emit(weapon_id)
	_refresh_weapon_stats(weapon_id)

func _refresh_weapon_stats(weapon_id: String) -> void:
	var weapons: Array = DataStore.weapons.get("weapons", [])
	var weapon_data: Dictionary = {}
	for w in weapons:
		if w.get("id", "") == weapon_id:
			weapon_data = w
			break
	if weapon_data.is_empty():
		weapon_stat_panel.visible = false
		return
	weapon_stat_panel.visible = true
	var name_label: Label = weapon_stat_panel.get_node_or_null("WeaponName")
	var light_dmg_label: Label = weapon_stat_panel.get_node_or_null("LightDamage")
	var heavy_dmg_label: Label = weapon_stat_panel.get_node_or_null("HeavyDamage")
	var stamina_label: Label = weapon_stat_panel.get_node_or_null("StaminaCost")
	var poise_label: Label = weapon_stat_panel.get_node_or_null("PoiseDamage")
	if name_label:
		name_label.text = str(weapon_data.get("id", ""))
	if light_dmg_label:
		light_dmg_label.text = "Damage: %d" % weapon_data.get("light_damage", 0)
	if heavy_dmg_label:
		heavy_dmg_label.text = "Heavy Damage: %d" % weapon_data.get("heavy_damage", 0)
	if stamina_label:
		stamina_label.text = "Stamina Cost: %d" % weapon_data.get("light_stamina_cost", 0)
	if poise_label:
		poise_label.text = "Poise Damage: %d" % weapon_data.get("poise_damage_light", 0)

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
	_refresh_ring_display()
	_refresh_upgrade_display()

func _refresh_ring_display() -> void:
	var ring_names := {
		"inner": "Ring 1 - The Inner Way",
		"mid": "Ring 2 - The Mid Path",
		"outer": "Ring 3 - The Outer Reaches",
	}
	ring_display.text = ring_names.get(GameState.current_ring, "")

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
	_refresh_upgrade_display()
	death_panel.visible = true

func _on_return_to_sanctuary() -> void:
	death_panel.visible = false
	on_idle_ready()

func on_idle_ready() -> void:
	_show_prep()
	death_panel.visible = false
	upgrade_draw_panel.visible = false
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

func _show_upgrade_draw() -> void:
	var f := FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	var upgrades_data: Array = []
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			upgrades_data = parsed.get("upgrades", [])
	else:
		push_error("upgrades.json not found — skipping upgrade draw")
		extract_pressed.emit()
		return
	if upgrades_data.is_empty():
		push_error("upgrades.json parsed but contains no upgrades — skipping upgrade draw")
		extract_pressed.emit()
		return
	# Filter out upgrades already selected this run
	var taken_ids: Array = GameState.active_upgrades.map(func(u): return u.get("id", ""))
	var available: Array = upgrades_data.filter(func(u): return u.get("id", "") not in taken_ids)
	available.shuffle()
	_current_draw = available.slice(0, 3)
	if _current_draw.size() < 3:
		extract_pressed.emit()
		return
	upgrade_card_0.text = "%s\n%s" % [_current_draw[0]["name"], _current_draw[0]["description"]]
	upgrade_card_1.text = "%s\n%s" % [_current_draw[1]["name"], _current_draw[1]["description"]]
	upgrade_card_2.text = "%s\n%s" % [_current_draw[2]["name"], _current_draw[2]["description"]]
	upgrade_card_0.disabled = false
	upgrade_card_1.disabled = false
	upgrade_card_2.disabled = false
	upgrade_draw_panel.visible = true

func _on_upgrade_card_selected(index: int) -> void:
	upgrade_card_0.disabled = true
	upgrade_card_1.disabled = true
	upgrade_card_2.disabled = true
	var selected: Dictionary = _current_draw[index]
	GameState.apply_upgrade(selected)
	upgrade_selected.emit(selected)
	upgrade_draw_panel.visible = false
	_refresh_upgrade_display()
	_show_upgrade_toast(str(selected.get("name", "")))
	extract_pressed.emit()

func _show_upgrade_toast(upgrade_name: String) -> void:
	upgrade_toast.text = "Applied: %s" % upgrade_name
	upgrade_toast.visible = true
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void: upgrade_toast.visible = false)

func _refresh_upgrade_display() -> void:
	if GameState.active_upgrades.is_empty():
		upgrade_list_label.text = ""
	else:
		var names: Array = GameState.active_upgrades.map(func(u): return u["name"])
		upgrade_list_label.text = "Upgrades: " + ", ".join(names)

func _refresh_run_status() -> void:
	var lines: PackedStringArray = []
	if run_base_status != "":
		lines.append(run_base_status)
	if objective_status != "":
		lines.append("Objective: %s" % objective_status)
	run_status.text = "\n".join(lines)

func _refresh_warden_option() -> void:
	var outer_target: int = 3
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == "outer":
			outer_target = r.get("contract_target", 3)
			break
	var show_warden: bool = GameState.current_ring == "outer" \
		and GameState.encounters_cleared >= outer_target \
		and not GameState.warden_defeated
	descend_warden_button.visible = show_warden

func show_credits() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	death_panel.visible = false
	_refresh_upgrade_display()
	credits_panel.visible = true

func _on_begin_new_journey_pressed() -> void:
	credits_panel.visible = false
	on_idle_ready()

func _on_back_to_menu_pressed() -> void:
	credits_panel.visible = false
	back_to_menu_requested.emit()

func _on_visit_vendor_pressed() -> void:
	var vendor_scene := load("res://scenes/ui/vendor.tscn")
	if not vendor_scene:
		push_error("vendor.tscn not found")
		return
	_vendor_instance = vendor_scene.instantiate()
	_vendor_instance.closed.connect(_on_vendor_closed)
	add_child(_vendor_instance)

func _on_vendor_closed() -> void:
	if _vendor_instance:
		_vendor_instance.queue_free()
		_vendor_instance = null
	_refresh_ring_selector()
