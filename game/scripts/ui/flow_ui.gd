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
@onready var history_button: Button = $PrepScreen/HistoryButton
@onready var permanent_upgrades_label: Label = $PrepScreen/PermanentUpgradesList

var run_base_status: String = ""
var objective_status: String = ""
var _is_paused: bool = false
var _current_draw: Array = []
var _vendor_instance: Node = null
var _history_instance: Node = null
var _modifier_draw_instance: Node = null
var _current_modifier_draw: Array = []

var _ui_sfx_player: AudioStreamPlayer = null
var _ui_click_stream: AudioStream = null
var _ui_upgrade_stream: AudioStream = null
var _pool_exhaustion_tween: Tween = null

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
	history_button.pressed.connect(_play_ui_click)
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
	GameState.abandon_run()
	var _SaveSystem := load("res://scripts/systems/save_system.gd")
	_SaveSystem.save_state(GameState.to_save_state())
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
	_refresh_ring_briefing()

func _refresh_ring_briefing() -> void:
	var rings_data: Array = DataStore.rings.get("rings", [])
	var briefing: String = ""
	for r in rings_data:
		if r.get("id", "") == GameState.current_ring:
			briefing = r.get("briefing", "")
			break
	if briefing != "":
		prep_status.text = briefing
	else:
		prep_status.text = "Sanctuary: choose your loadout and begin the next run."

func _on_start_run_button_pressed() -> void:
	_play_ui_click()
	_show_modifier_draw()

func _show_modifier_draw() -> void:
	if is_instance_valid(_modifier_draw_instance):
		return
	var pool: Array = DataStore.modifiers.get("modifiers", []).duplicate()
	if pool.size() < 2:
		push_warning("modifier_draw: pool has fewer than 2 modifiers -- skipping draw")
		start_run_pressed.emit()
		return
	pool.shuffle()
	_current_modifier_draw = pool.slice(0, 2)
	var modifier_draw_scene := load("res://scenes/ui/modifier_draw.tscn")
	if modifier_draw_scene == null:
		push_error("modifier_draw: scene not found")
		start_run_pressed.emit()
		return
	_modifier_draw_instance = modifier_draw_scene.instantiate()
	add_child(_modifier_draw_instance)
	_modifier_draw_instance.modifier_selected.connect(_on_modifier_selected)
	_modifier_draw_instance.populate(_current_modifier_draw)

func _on_modifier_selected(modifier: Dictionary) -> void:
	_modifier_draw_instance = null
	GameState.pending_modifier = modifier
	_show_upgrade_toast("Modifier: " + modifier.get("name", "?"))
	start_run_pressed.emit()

func _on_resolve_encounter_button_pressed() -> void:
	_play_ui_click()
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	_play_ui_click()
	if GameState.current_ring in ["inner", "mid", "outer"]:
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
		name_label.text = str(weapon_data.get("display_name", weapon_data.get("id", "")))
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
	var display_text: String = GameState.current_ring
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == GameState.current_ring:
			display_text = r.get("display_name", GameState.current_ring)
			break
	ring_display.text = display_text

func set_available_loadouts(weapons: Array) -> void:
	loadout_select.clear()
	for weapon in weapons:
		var weapon_id := str(weapon.get("id", ""))
		var display_name := str(weapon.get("display_name", weapon_id))
		var is_unlocked: bool = weapon_id in GameState.weapons_unlocked
		if is_unlocked:
			loadout_select.add_item(display_name)
			loadout_select.set_item_metadata(loadout_select.get_item_count() - 1, weapon_id)
		else:
			# Show locked weapons with XP cost
			var cost_xp: int = _get_weapon_unlock_cost(weapon_id)
			loadout_select.add_item("%s [LOCKED - %d XP]" % [display_name, cost_xp])
			loadout_select.set_item_metadata(loadout_select.get_item_count() - 1, weapon_id)
			loadout_select.set_item_disabled(loadout_select.get_item_count() - 1, true)
	if loadout_select.get_item_count() > 0:
		# Select first non-disabled item
		for i in range(loadout_select.get_item_count()):
			if not loadout_select.is_item_disabled(i):
				loadout_select.select(i)
				_on_loadout_select_item_selected(i)
				break

func _get_weapon_unlock_cost(weapon_id: String) -> int:
	var items: Array = DataStore.shop_items.get("items", [])
	for item in items:
		if item.get("type") == "weapon_unlock" and item.get("value") == weapon_id:
			return int(item.get("cost_xp", 999))
	return 999

func set_current_loadout(weapon_id: String) -> void:
	var weapons: Array = DataStore.weapons.get("weapons", [])
	var display_name: String = weapon_id
	for w in weapons:
		if w.get("id") == weapon_id:
			display_name = str(w.get("display_name", weapon_id))
			break
	loadout_summary.text = "Selected loadout: %s" % display_name
	run_loadout.text = "Loadout: %s" % display_name

func on_encounter_resolved(xp_gain: int, loot_gain: int) -> void:
	run_base_status = "Encounter won: +%d XP, +%d Loot" % [xp_gain, loot_gain]
	_refresh_run_status()
	_refresh_warden_option()

func on_extracted(total_xp: int, total_loot: int, ring_id: String = "") -> void:
	_show_prep()
	var cleared_ring_id: String = ring_id if ring_id != "" else (GameState.rings_cleared[-1] if not GameState.rings_cleared.is_empty() else "?")
	var extraction_flavor: String = ""
	for r in DataStore.rings.get("rings", []):
		if r.get("id", "") == cleared_ring_id:
			extraction_flavor = r.get("extraction_flavor", "")
			break
	var status_text: String = "Extracted!\nRing Cleared: %s\nXP Banked: %d  |  Loot Banked: %d" % [
		cleared_ring_id,
		total_xp,
		total_loot
	]
	if extraction_flavor != "":
		status_text += "\n\n%s" % extraction_flavor
	prep_status.text = status_text
	_refresh_ring_selector()
	_refresh_permanent_upgrades_display()

func on_died(unbanked_xp: int, unbanked_loot: int, ring_id: String = GameState.current_ring) -> void:
	var ring_display_name: String = ring_id
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == ring_id:
			ring_display_name = r.get("display_name", ring_id)
			break
	ring_label.text = "Ring Reached: %s" % ring_display_name
	encounters_label.text = "Encounters Cleared: %d" % GameState.encounters_cleared
	var xp_kept: int = int(unbanked_xp * 0.5)
	var xp_lost: int = unbanked_xp - xp_kept
	xp_label.text = "XP: Lost %d | Kept %d (50%% retention)" % [xp_lost, xp_kept]
	var loot_kept: int = int(unbanked_loot * 0.25)
	var loot_lost: int = unbanked_loot - loot_kept
	loot_label.text = "Loot: Lost %d | Kept %d (25%% retention)" % [loot_lost, loot_kept]
	_refresh_upgrade_display()
	run_screen.visible = false
	death_panel.visible = true

func _on_return_to_sanctuary() -> void:
	death_panel.visible = false
	on_idle_ready()

func on_idle_ready() -> void:
	if is_instance_valid(_modifier_draw_instance):
		_modifier_draw_instance.queue_free()
		_modifier_draw_instance = null
	_show_prep()
	death_panel.visible = false
	upgrade_draw_panel.visible = false
	if is_instance_valid(_pool_exhaustion_tween) and _pool_exhaustion_tween.is_running():
		_pool_exhaustion_tween.kill()
		_pool_exhaustion_tween = null
	run_base_status = ""
	objective_status = ""
	_refresh_ring_selector()
	_refresh_ring_briefing()
	_refresh_permanent_upgrades_display()
	set_available_loadouts(DataStore.weapons.get("weapons", []))
	set_current_loadout(GameState.selected_weapon_id)
	_refresh_weapon_unlock_panel()

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
	var upgrades_data: Array = DataStore.upgrades.get("upgrades", [])
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
		upgrade_toast.text = "Upgrade pool exhausted -- no cards available."
		upgrade_toast.visible = true
		_pool_exhaustion_tween = create_tween()
		_pool_exhaustion_tween.tween_interval(2.0)
		_pool_exhaustion_tween.tween_callback(func() -> void:
			upgrade_toast.visible = false
			extract_pressed.emit()
		)
		return
	upgrade_card_0.text = "%s\n%s" % [_current_draw[0].get("name", "?"), _current_draw[0].get("description", "")]
	upgrade_card_1.text = "%s\n%s" % [_current_draw[1].get("name", "?"), _current_draw[1].get("description", "")]
	upgrade_card_2.text = "%s\n%s" % [_current_draw[2].get("name", "?"), _current_draw[2].get("description", "")]
	upgrade_card_0.disabled = false
	upgrade_card_1.disabled = false
	upgrade_card_2.disabled = false
	upgrade_draw_panel.visible = true

func _on_upgrade_card_selected(index: int) -> void:
	upgrade_card_0.disabled = true
	upgrade_card_1.disabled = true
	upgrade_card_2.disabled = true
	if index < 0 or index >= _current_draw.size():
		push_error("Upgrade card index %d out of bounds (draw size %d)" % [index, _current_draw.size()])
		extract_pressed.emit()
		return
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
		var names: Array = GameState.active_upgrades.map(func(u): return u.get("name", u.get("id", "Unknown")))
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
	var _SaveSystem := load("res://scripts/systems/save_system.gd")
	_SaveSystem.save_state(GameState.to_save_state())
	_refresh_ring_selector()
	_refresh_permanent_upgrades_display()

func _on_history_closed() -> void:
	if is_instance_valid(_history_instance):
		_history_instance.queue_free()
		_history_instance = null

func _on_history_button_pressed() -> void:
	if is_instance_valid(_history_instance):
		return
	var history_scene := load("res://scenes/ui/run_history.tscn")
	if not history_scene:
		push_error("run_history.tscn not found")
		return
	_history_instance = history_scene.instantiate()
	add_child(_history_instance)
	_history_instance.closed.connect(_on_history_closed)

func _refresh_permanent_upgrades_display() -> void:
	if not is_instance_valid(permanent_upgrades_label):
		return
	var upgrades: Array = GameState.permanent_upgrades
	if upgrades.is_empty():
		permanent_upgrades_label.text = "No permanent upgrades yet."
		return
	var parts: Array = []
	for u in upgrades:
		var name: String = u.get("name", u.get("id", "?"))
		parts.append(name)
	permanent_upgrades_label.text = "Active Bonuses: " + ", ".join(parts)

func _refresh_weapon_unlock_panel() -> void:
	var panel: Node = get_node_or_null("PrepScreen/WeaponUnlockPanel")
	if not panel:
		push_warning("WeaponUnlockPanel not found in scene tree -- weapon unlock UI will not render")
		return
	for child in panel.get_children():
		child.queue_free()
	var items: Array = DataStore.shop_items.get("items", [])
	for item in items:
		if item.get("type") != "weapon_unlock":
			continue
		var weapon_id: String = str(item.get("value", ""))
		var already_unlocked: bool = weapon_id in GameState.weapons_unlocked
		if already_unlocked:
			continue  # Don't show already unlocked weapons
		var cost_xp: int = int(item.get("cost_xp", 999))
		var btn := Button.new()
		btn.text = "%s -- %d XP" % [item.get("name", weapon_id), cost_xp]
		btn.disabled = not GameState.can_afford_weapon_unlock(cost_xp)
		btn.pressed.connect(_on_unlock_weapon_pressed.bind(btn, item))
		panel.add_child(btn)

func _on_unlock_weapon_pressed(btn: Button, item: Dictionary) -> void:
	btn.disabled = true
	var cost_xp: int = int(item.get("cost_xp", 999))
	var weapon_id: String = str(item.get("value", ""))
	if not GameState.can_afford_weapon_unlock(cost_xp):
		btn.disabled = false
		return
	GameState.spend_xp(cost_xp)
	GameState.unlock_weapon(weapon_id)
	var _SaveSystem := load("res://scripts/systems/save_system.gd")
	_SaveSystem.save_state(GameState.to_save_state())
	set_available_loadouts(DataStore.weapons.get("weapons", []))
	_refresh_weapon_unlock_panel()
