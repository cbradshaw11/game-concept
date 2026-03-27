extends CanvasLayer
class_name FlowUI

signal start_run_pressed(ring_id: String)
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_updated(melee_id: String, ranged_id: String, magic_id: String)
signal vendor_purchase_pressed(upgrade_id: String)
signal modifier_selected(modifier_id: String)
signal warden_gate_dismissed
signal return_to_title_pressed
signal run_modifier_resolved

const RunSummaryScene = preload("res://scenes/ui/run_summary.tscn")

@onready var prep_screen: PanelContainer = $PrepScreen
@onready var run_screen: PanelContainer = $RunScreen
@onready var prep_status: Label = $PrepScreen/PrepVBox/PrepStatus
@onready var loadout_select: OptionButton = $PrepScreen/PrepVBox/LoadoutSelect
@onready var loadout_summary: Label = $PrepScreen/PrepVBox/LoadoutSummary

# M38 — Three-slot weapon selectors (built dynamically from loadout_select's parent)
var _melee_select: OptionButton = null
var _ranged_select: OptionButton = null
var _magic_select: OptionButton = null
var _all_weapons: Array = []
@onready var run_status: Label = $RunScreen/RunVBox/RunStatus
@onready var run_loadout: Label = $RunScreen/RunVBox/RunLoadout

# Vendor & Ring 2 nodes (created dynamically)
var vendor_panel: PanelContainer = null
var vendor_loot_label: Label = null
var vendor_upgrade_buttons: Dictionary = {}  # upgrade_id -> Button
var vendor_upgrade_labels: Dictionary = {}  # upgrade_id -> Label (row label)
var _vendor_toast: Label = null

# Victory / Death / Modifier / Run Summary / Shrine panels (created dynamically)
var victory_panel: PanelContainer = null
var death_panel: PanelContainer = null
var modifier_panel: PanelContainer = null
var run_summary_panel: PanelContainer = null
var shrine_panel: PanelContainer = null
var shrine_shard_label: Label = null
var shrine_unlock_buttons: Dictionary = {}  # unlock_id -> Button
var shrine_unlock_labels: Dictionary = {}   # unlock_id -> Label
var _shrine_first_visit: bool = true

# M31 — Challenge Run panel
var challenge_panel: PanelContainer = null
var challenge_buttons: Dictionary = {}  # challenge_id -> Button
var challenge_labels: Dictionary = {}   # challenge_id -> Label
var challenge_status_label: Label = null

var run_base_status: String = ""
var objective_status: String = ""
var _initial_show_done: bool = false
var _return_toast: Label = null

# M32 — Achievement gallery panel and toast
var achievement_panel: PanelContainer = null
var _achievement_toast: PanelContainer = null

# Death flavor lines keyed by ring id and/or enemy type
const DEATH_FLAVOR: Dictionary = {
	"inner": [
		"The outer walls didn't kill you. The inner ring did.",
		"You walked in with hope. You left in pieces.",
		"Even the weakest scavengers found your weakness.",
		"The ring claimed another body for the ash.",
		"They said Ring 1 was easy. They lied.",
		"Your equipment survived. You didn't.",
		"A grunt dealt the killing blow. Let that sink in.",
		"The Long Walk ends here, apparently.",
		"Death doesn't discriminate by ring number.",
		"Tomorrow you'll do better. Today you're dead.",
	],
	"mid": [
		"The Mid Reaches are called that for a reason.",
		"Flanked, outpaced, overwhelmed. Classic mid.",
		"You had the skills. The flankers had the numbers.",
		"Another soul left in the ash dunes.",
		"The berserkers barely noticed you.",
		"Mid ring sends its regards.",
		"You got farther than most. Not far enough.",
		"The Long Walk claimed you at the midpoint.",
		"Poise broken, guard shattered, hope extinguished.",
		"You'll come back stronger. Or you won't.",
	],
	"outer": [
		"The Outer Ring was always going to kill you.",
		"Elite threats require elite preparation. Next time.",
		"The Warden's approach path is littered with the fallen.",
		"You saw the outer ring. That's more than most.",
		"The rift casters had your number from the start.",
		"Outer ring death is an achievement in itself.",
		"The warden hunter was named for a reason.",
		"Far from home. Far from safety. Far from alive.",
		"Your loot stays here. Your lessons go with you.",
		"The Long Walk ends at the outer gate.",
	],
	"berserker": [
		"Hit first, hit hard — the berserker's creed.",
		"Staggered once, finished twice. That's berserker math.",
		"Fast, fragile, and faster than you.",
	],
	"shield_wall": [
		"You forgot: break poise before dealing damage.",
		"The Shield Wall absorbed everything. Literally everything.",
		"Attrition wins when you can't break guard.",
	],
}

func _ready() -> void:
	_setup_ring2_button()
	_setup_vendor_panel()
	_setup_history_button()
	_setup_how_to_play_button()
	_setup_recovered_notes_button()
	_setup_achievements_button()
	_setup_settings_button()
	_setup_shrine_panel()
	_setup_challenge_panel()
	_setup_achievement_panel()
	_setup_victory_panel()
	_setup_death_panel()
	_setup_modifier_panel()
	# M32 — Connect achievement toast
	if AchievementManager:
		AchievementManager.achievement_unlocked.connect(_show_achievement_toast)
	_show_prep()

func _on_start_run_button_pressed() -> void:
	_play_click()
	start_run_pressed.emit("inner")

func _on_start_ring2_button_pressed() -> void:
	_play_click()
	start_run_pressed.emit("mid")

func _on_start_ring3_button_pressed() -> void:
	_play_click()
	start_run_pressed.emit("outer")

func _on_resolve_encounter_button_pressed() -> void:
	_play_click()
	resolve_encounter_pressed.emit()

func _on_extract_button_pressed() -> void:
	_play_click()
	extract_pressed.emit()

func _on_die_button_pressed() -> void:
	_play_click()
	die_pressed.emit()

func _on_loadout_select_item_selected(_index: int) -> void:
	# Legacy — replaced by M38 three-slot selectors
	_emit_loadout_updated()

func _emit_loadout_updated() -> void:
	var melee_id := ""
	var ranged_id := ""
	var magic_id := ""
	if _melee_select and _melee_select.get_item_count() > 0:
		melee_id = str(_melee_select.get_item_metadata(_melee_select.selected))
	if _ranged_select and _ranged_select.get_item_count() > 0:
		ranged_id = str(_ranged_select.get_item_metadata(_ranged_select.selected))
	if _magic_select and _magic_select.get_item_count() > 0:
		magic_id = str(_magic_select.get_item_metadata(_magic_select.selected))
	loadout_updated.emit(melee_id, ranged_id, magic_id)

func _on_vendor_button_pressed(upgrade_id: String) -> void:
	_play_click()
	vendor_purchase_pressed.emit(upgrade_id)

func _play_click() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")

func _play_cancel() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_cancel")

# ── Screen visibility ─────────────────────────────────────────────────────────

func _show_prep() -> void:
	prep_screen.visible = true
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = false
	_hide_run_summary()
	# M23 — Show/hide Recovered Notes button based on collected fragments
	var notes_btn := prep_screen.find_child("RecoveredNotesButton", true, false)
	if notes_btn is Button:
		notes_btn.visible = not GameState.collected_fragments.is_empty()
	# M28 — Sanctuary music
	if AudioManager:
		AudioManager.play_music("sanctuary")
	# M20 T4 — Show return greeting toast when coming back from a run
	if _initial_show_done and not GameState.run_history.is_empty():
		_show_return_toast()
	_initial_show_done = true

func _show_run() -> void:
	prep_screen.visible = false
	run_screen.visible = true
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = false
	_hide_run_summary()

func _show_vendor() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = true
		_refresh_vendor_ui()
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = false

func _show_victory(stats: Dictionary) -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if victory_panel:
		_populate_victory_panel(stats)
		victory_panel.visible = true

func _show_death(ring_id: String, killer_enemy_id: String) -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if death_panel:
		_populate_death_panel(ring_id, killer_enemy_id)
		death_panel.visible = true

func _show_modifier_selection(choices: Array) -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if modifier_panel:
		_populate_modifier_panel(choices)
		modifier_panel.visible = true

# ── Public API called from main.gd ───────────────────────────────────────────

func on_run_started(seed: int) -> void:
	_show_run()
	run_base_status = "Run active (seed %d)" % seed
	_refresh_run_status()

func set_available_loadouts(weapons: Array) -> void:
	_all_weapons = weapons
	# Hide legacy single selector
	loadout_select.visible = false
	# Build three category selectors if not already created
	if _melee_select == null:
		_build_slot_selectors()
	_populate_slot_selector(_melee_select, "melee")
	_populate_slot_selector(_ranged_select, "ranged")
	_populate_slot_selector(_magic_select, "magic")

func _build_slot_selectors() -> void:
	var parent_vbox: VBoxContainer = loadout_select.get_parent() as VBoxContainer
	if parent_vbox == null:
		return
	var insert_idx := loadout_select.get_index() + 1
	# Melee
	var melee_label := Label.new()
	melee_label.text = "Melee (LMB / Z):"
	parent_vbox.add_child(melee_label)
	parent_vbox.move_child(melee_label, insert_idx)
	_melee_select = OptionButton.new()
	_melee_select.name = "MeleeSelect"
	_melee_select.item_selected.connect(_on_slot_select_changed)
	parent_vbox.add_child(_melee_select)
	parent_vbox.move_child(_melee_select, insert_idx + 1)
	# Ranged
	var ranged_label := Label.new()
	ranged_label.text = "Ranged (Q):"
	parent_vbox.add_child(ranged_label)
	parent_vbox.move_child(ranged_label, insert_idx + 2)
	_ranged_select = OptionButton.new()
	_ranged_select.name = "RangedSelect"
	_ranged_select.item_selected.connect(_on_slot_select_changed)
	parent_vbox.add_child(_ranged_select)
	parent_vbox.move_child(_ranged_select, insert_idx + 3)
	# Magic
	var magic_label := Label.new()
	magic_label.text = "Magic (R):"
	parent_vbox.add_child(magic_label)
	parent_vbox.move_child(magic_label, insert_idx + 4)
	_magic_select = OptionButton.new()
	_magic_select.name = "MagicSelect"
	_magic_select.item_selected.connect(_on_slot_select_changed)
	parent_vbox.add_child(_magic_select)
	parent_vbox.move_child(_magic_select, insert_idx + 5)

func _populate_slot_selector(selector: OptionButton, category: String) -> void:
	selector.clear()
	for weapon in _all_weapons:
		if str(weapon.get("category", "")) == category:
			var wid := str(weapon.get("id", ""))
			var wname := str(weapon.get("name", wid))
			selector.add_item(wname)
			selector.set_item_metadata(selector.get_item_count() - 1, wid)
	if selector.get_item_count() > 0:
		selector.select(0)

func _on_slot_select_changed(_index: int) -> void:
	_emit_loadout_updated()

func set_current_loadout(melee_id: String, ranged_id: String, magic_id: String) -> void:
	var m_name := _weapon_name(melee_id)
	var r_name := _weapon_name(ranged_id)
	var mg_name := _weapon_name(magic_id)
	loadout_summary.text = "M: %s | R: %s | Mg: %s" % [m_name, r_name, mg_name]
	run_loadout.text = "M: %s | R: %s | Mg: %s" % [m_name, r_name, mg_name]
	# Sync selectors
	_select_weapon_in_slot(_melee_select, melee_id)
	_select_weapon_in_slot(_ranged_select, ranged_id)
	_select_weapon_in_slot(_magic_select, magic_id)

func _weapon_name(weapon_id: String) -> String:
	for w in _all_weapons:
		if str(w.get("id", "")) == weapon_id:
			return str(w.get("name", weapon_id))
	return weapon_id

func _select_weapon_in_slot(selector: OptionButton, weapon_id: String) -> void:
	if selector == null:
		return
	for i in selector.get_item_count():
		if str(selector.get_item_metadata(i)) == weapon_id:
			selector.select(i)
			return

func on_encounter_resolved(xp_gain: int, loot_gain: int) -> void:
	run_base_status = "Encounter won: +%d XP, +%d Loot" % [xp_gain, loot_gain]
	_refresh_run_status()

func on_extracted(total_xp: int, total_loot: int) -> void:
	# M21 — Route to run summary instead of old victory panel
	_show_run_summary("extraction")
	_refresh_ring_buttons()

func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
	# M21 — Route to run summary instead of old death panel
	_show_run_summary("death")
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

func on_extract_blocked_challenge(message: String) -> void:
	run_base_status = "⚠ %s" % message
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

func show_modifier_selection(seed: int) -> void:
	var count := DataStore.get_modifier_choices_per_run()
	var choices := DataStore.get_random_modifiers(count, seed)
	_show_modifier_selection(choices)

func refresh_vendor() -> void:
	_refresh_vendor_ui()

# ── M17 Narrative hooks ───────────────────────────────────────────────────────

## M17 T9 — Display prologue sequence (once, on first launch).
## beats: Array of prologue beat Dictionaries from NarrativeManager.get_prologue()
func show_prologue(beats: Array) -> void:
	if beats.is_empty():
		return

	# Build a scrollable modal overlay so nothing gets cut off
	var overlay := PanelContainer.new()
	overlay.name = "PrologueOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "THE LONG WALK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := Label.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lines: PackedStringArray = []
	for beat in beats:
		for line in beat.get("lines", []):
			lines.append(str(line))
		var choices: Array = beat.get("choices", [])
		if not choices.is_empty():
			lines.append("")
			for choice in choices:
				lines.append("[%s] %s" % [str(choice.get("text", "")), str(choice.get("response", ""))])
		lines.append("")
	content.text = "\n".join(lines)
	scroll.add_child(content)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Continue →"
	dismiss_btn.pressed.connect(func():
		overlay.queue_free()
	)
	vbox.add_child(dismiss_btn)

## M18 — Display the Warden boss gate intro as sequential text cards.
## lines: Array of Strings from NarrativeManager.get_warden_intro()
func show_warden_gate(lines: Array) -> void:
	if lines.is_empty():
		warden_gate_dismissed.emit()
		return

	var overlay := PanelContainer.new()
	overlay.name = "WardenGateOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "THE WARDEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := Label.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var text_lines: PackedStringArray = []
	for line in lines:
		text_lines.append(str(line))
		text_lines.append("")
	content.text = "\n".join(text_lines)
	scroll.add_child(content)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Face the Warden →"
	dismiss_btn.pressed.connect(func():
		overlay.queue_free()
		warden_gate_dismissed.emit()
	)
	vbox.add_child(dismiss_btn)

## M18/M21 — Show artifact victory via run summary screen.
func show_artifact_victory(extraction_text: String, artifact_text: String) -> void:
	_show_run_summary("artifact")

## M25 — Display encounter flavor text as a brief banner before combat.
## Shows for 2.5s then fades. Does nothing if text is empty.
func show_encounter_flavor(text: String) -> void:
	if text == "":
		return
	var banner := Label.new()
	banner.text = text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 18)
	banner.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	banner.anchors_preset = Control.PRESET_CENTER_BOTTOM
	banner.position.y -= 80
	banner.modulate.a = 0.0
	add_child(banner)
	# Fade in
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.2)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(banner.queue_free)

## M17 T10 — Display a single narrative text in the run status area.
## Used for ring entry flavor text before a run begins.
func show_narrative_text(text: String) -> void:
	if text == "":
		return
	# Prepend flavor text to run_base_status so it appears alongside run info.
	run_base_status = text
	_refresh_run_status()

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
	# Show Ring 3 button only if mid extracted
	var ring3_btn := prep_screen.find_child("Ring3Button", true, false)
	if ring3_btn is Button:
		var unlocked3 := GameState.has_extracted_from("mid")
		ring3_btn.visible = unlocked3
		ring3_btn.disabled = not unlocked3

# ── Victory Panel ─────────────────────────────────────────────────────────────

func _setup_victory_panel() -> void:
	victory_panel = PanelContainer.new()
	victory_panel.name = "VictoryPanel"
	victory_panel.visible = false
	victory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(victory_panel)

	var vbox := VBoxContainer.new()
	victory_panel.add_child(vbox)

	var title := Label.new()
	title.name = "VictoryTitle"
	title.text = "✦  EXTRACTION SUCCESSFUL  ✦"
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var stats_label := Label.new()
	stats_label.name = "VictoryStats"
	stats_label.text = ""
	vbox.add_child(stats_label)

	var continue_btn := Button.new()
	continue_btn.text = "← Return to Sanctuary"
	continue_btn.pressed.connect(func():
		_play_click()
		_show_prep()
	)
	vbox.add_child(continue_btn)

func _populate_victory_panel(stats: Dictionary) -> void:
	if victory_panel == null:
		return
	var stats_label := victory_panel.find_child("VictoryStats", true, false) as Label
	if stats_label == null:
		return

	var ring := str(stats.get("ring", "?"))
	var seed_val := int(stats.get("seed", 0))
	var encounters := int(stats.get("encounters_cleared", 0))
	var total_xp := int(stats.get("total_xp", 0))
	var total_loot := int(stats.get("total_loot", 0))
	var active_mods: Array = stats.get("active_modifiers", [])
	var active_upgrades: Array = stats.get("vendor_upgrades", [])

	var lines: PackedStringArray = []
	# M19 T6 — Extraction flavor text
	var extraction_flavor := str(stats.get("extraction_flavor", ""))
	if extraction_flavor != "":
		lines.append(extraction_flavor)
		lines.append("")
	lines.append("Ring reached:        %s" % ring.to_upper())
	lines.append("Encounters cleared:  %d" % encounters)
	lines.append("Total XP earned:     %d" % total_xp)
	lines.append("Total loot earned:   %d" % total_loot)
	lines.append("Run seed:            %d" % seed_val)

	if active_mods.is_empty():
		lines.append("Modifiers:           (none)")
	else:
		var mod_names: PackedStringArray = []
		for mod in active_mods:
			mod_names.append(str(mod.get("name", mod.get("id", "?"))))
		lines.append("Modifiers:           %s" % ", ".join(mod_names))

	if active_upgrades.is_empty():
		lines.append("Upgrades active:     (none)")
	else:
		lines.append("Upgrades active:     %s" % ", ".join(PackedStringArray(active_upgrades)))

	stats_label.text = "\n".join(lines)

# ── Death Panel ───────────────────────────────────────────────────────────────

func _setup_death_panel() -> void:
	death_panel = PanelContainer.new()
	death_panel.name = "DeathPanel"
	death_panel.visible = false
	death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(death_panel)

	var vbox := VBoxContainer.new()
	death_panel.add_child(vbox)

	var title := Label.new()
	title.name = "DeathTitle"
	title.text = "✦  YOU HAVE FALLEN  ✦"
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var flavor_label := Label.new()
	flavor_label.name = "DeathFlavor"
	flavor_label.text = ""
	vbox.add_child(flavor_label)

	var continue_btn := Button.new()
	continue_btn.text = "← Try Again"
	continue_btn.pressed.connect(func():
		_play_click()
		_show_prep()
	)
	vbox.add_child(continue_btn)

func _populate_death_panel(ring_id: String, killer_enemy_id: String) -> void:
	if death_panel == null:
		return
	var flavor_label := death_panel.find_child("DeathFlavor", true, false) as Label
	if flavor_label == null:
		return

	# Pick flavor text — prefer enemy-specific, fall back to ring
	var lines: Array = []
	if killer_enemy_id != "" and DEATH_FLAVOR.has(killer_enemy_id):
		lines = DEATH_FLAVOR[killer_enemy_id].duplicate()
	elif DEATH_FLAVOR.has(ring_id):
		lines = DEATH_FLAVOR[ring_id].duplicate()
	else:
		lines = DEATH_FLAVOR["inner"].duplicate()

	# Use seed-based determinism for flavor line selection
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(GameState.active_seed + ring_id.hash())
	rng.randomize()
	var idx := rng.randi_range(0, lines.size() - 1)
	var flavor_text := str(lines[idx])

	# M19 T5 — Append narrative death flavor text from NarrativeManager
	var narrative_death := NarrativeManager.get_ring_text(ring_id, "death")
	if narrative_death != "":
		flavor_text += "\n\n" + narrative_death
	flavor_label.text = flavor_text

# ── Modifier Selection Panel ──────────────────────────────────────────────────

func _setup_modifier_panel() -> void:
	modifier_panel = PanelContainer.new()
	modifier_panel.name = "ModifierPanel"
	modifier_panel.visible = false
	modifier_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(modifier_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "ModifierVBox"
	modifier_panel.add_child(vbox)

	var title := Label.new()
	title.text = "✦  CHOOSE YOUR RUN MODIFIER  ✦"
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Choice buttons added dynamically in _populate_modifier_panel
	var choices_container := VBoxContainer.new()
	choices_container.name = "ModifierChoices"
	vbox.add_child(choices_container)

func _populate_modifier_panel(choices: Array) -> void:
	if modifier_panel == null:
		return
	var choices_container := modifier_panel.find_child("ModifierChoices", true, false) as VBoxContainer
	if choices_container == null:
		return

	# Clear old buttons
	for child in choices_container.get_children():
		child.queue_free()

	for mod in choices:
		var mod_id := str(mod.get("id", ""))
		var mod_name := str(mod.get("name", mod_id))
		var mod_desc := str(mod.get("description", ""))

		var btn := Button.new()
		btn.text = "%s — %s" % [mod_name, mod_desc]
		var cap_id := mod_id
		var cap_mod: Dictionary = mod
		btn.pressed.connect(func():
			_play_click()
			GameState.set_active_modifiers([cap_mod])
			modifier_selected.emit(cap_id)
			_show_run()
		)
		choices_container.add_child(btn)

# ── M26 — Between-Encounter Modifier Card ─────────────────────────────────────

var modifier_card_panel: PanelContainer = null
var _modifier_card_timer: SceneTreeTimer = null

func show_modifier_card_offer(modifier: Dictionary) -> void:
	## Display a modifier card offer after an encounter. Accept or Decline.
	## Auto-dismisses as Decline after 12 seconds.
	if modifier.is_empty():
		run_modifier_resolved.emit()
		return
	_build_modifier_card(modifier)

func _build_modifier_card(modifier: Dictionary) -> void:
	# Clean up any previous card
	if modifier_card_panel != null and is_instance_valid(modifier_card_panel):
		modifier_card_panel.queue_free()

	modifier_card_panel = PanelContainer.new()
	modifier_card_panel.name = "ModifierCardPanel"
	modifier_card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	modifier_card_panel.z_index = 11
	add_child(modifier_card_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	modifier_card_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "MODIFIER OFFERED"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	vbox.add_child(header)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Tier label
	var tier := int(modifier.get("tier", 1))
	var tier_names := {1: "Common", 2: "Uncommon", 3: "Rare"}
	var tier_colors := {1: Color(0.7, 0.7, 0.7), 2: Color(0.4, 0.7, 0.9), 3: Color(0.9, 0.7, 0.3)}
	var tier_label := Label.new()
	tier_label.text = str(tier_names.get(tier, "Common"))
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 12)
	tier_label.add_theme_color_override("font_color", tier_colors.get(tier, Color(0.7, 0.7, 0.7)))
	vbox.add_child(tier_label)

	# Name
	var name_label := Label.new()
	name_label.text = str(modifier.get("name", "Unknown"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# Effect description
	var desc_label := Label.new()
	desc_label.text = str(modifier.get("description", ""))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Flavor text
	var flavor := str(modifier.get("flavor", ""))
	if flavor != "":
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 12
		vbox.add_child(spacer)
		var flavor_label := Label.new()
		flavor_label.text = flavor
		flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flavor_label.add_theme_font_size_override("font_size", 12)
		flavor_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55, 0.8))
		flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(flavor_label)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var mod_id := str(modifier.get("id", ""))

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.pressed.connect(func():
		if AudioManager:
			AudioManager.play_sfx("modifier_accept")
		ModifierManager.add_modifier(mod_id)
		_dismiss_modifier_card()
	)
	btn_row.add_child(accept_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.x = 40
	btn_row.add_child(spacer2)

	var decline_btn := Button.new()
	decline_btn.text = "Decline"
	decline_btn.pressed.connect(func():
		_play_cancel()
		_dismiss_modifier_card()
	)
	btn_row.add_child(decline_btn)

	# Auto-dismiss timer (12s)
	_modifier_card_timer = get_tree().create_timer(12.0)
	var panel_ref := modifier_card_panel
	_modifier_card_timer.timeout.connect(func():
		if is_instance_valid(panel_ref) and panel_ref.visible:
			_dismiss_modifier_card()
	)

func _dismiss_modifier_card() -> void:
	_modifier_card_timer = null
	if modifier_card_panel != null and is_instance_valid(modifier_card_panel):
		modifier_card_panel.queue_free()
		modifier_card_panel = null
	run_modifier_resolved.emit()

# ── M21 — Run Summary ────────────────────────────────────────────────────────

func _show_run_summary(outcome: String) -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	_hide_run_summary()  # Clean up any previous
	run_summary_panel = RunSummaryScene.instantiate()
	add_child(run_summary_panel)
	run_summary_panel.populate(outcome)
	run_summary_panel.return_to_sanctuary.connect(func():
		_hide_run_summary()
		_show_prep()
	)
	run_summary_panel.return_to_title.connect(func():
		_hide_run_summary()
		return_to_title_pressed.emit()
	)

func _hide_run_summary() -> void:
	if run_summary_panel != null and is_instance_valid(run_summary_panel):
		run_summary_panel.queue_free()
		run_summary_panel = null

# ── M20 T4 — Sanctuary Return Toast ──────────────────────────────────────────

func _show_return_toast() -> void:
	# Clean up any existing toast
	if _return_toast != null and is_instance_valid(_return_toast):
		_return_toast.queue_free()

	var greeting := NarrativeManager.get_ring_text("sanctuary", "entry")
	if greeting == "":
		return

	_return_toast = Label.new()
	_return_toast.name = "ReturnToast"
	_return_toast.text = greeting
	_return_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_return_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_return_toast.offset_top = 8
	_return_toast.offset_bottom = 40
	_return_toast.add_theme_font_size_override("font_size", 13)
	_return_toast.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 1.0))
	_return_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_return_toast)

	# Auto-dismiss after 3 seconds
	var timer := get_tree().create_timer(3.0)
	var toast_ref := _return_toast
	timer.timeout.connect(func():
		if is_instance_valid(toast_ref):
			toast_ref.queue_free()
	)

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

	var btn3 := Button.new()
	btn3.name = "Ring3Button"
	btn3.text = "▶  Enter Ring 3 (Outer Ring)"
	btn3.visible = false
	btn3.pressed.connect(_on_start_ring3_button_pressed)
	prep_vbox.add_child(btn3)

func _setup_vendor_panel() -> void:
	# Build a vendor panel as a sibling of PrepScreen, grouped by category
	vendor_panel = PanelContainer.new()
	vendor_panel.name = "VendorPanel"
	vendor_panel.visible = false
	vendor_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vendor_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vendor_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VendorVBox"
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "VENDOR — Spend your silver"
	vbox.add_child(title)

	vendor_loot_label = Label.new()
	vendor_loot_label.text = "Silver: 0"
	vbox.add_child(vendor_loot_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Group upgrades by category
	var upgrades := DataStore.get_vendor_upgrades()
	var by_category: Dictionary = {}  # category -> Array of upgrade dicts
	for upg in upgrades:
		var cat := str(upg.get("category", "other"))
		if not by_category.has(cat):
			by_category[cat] = []
		by_category[cat].append(upg)

	var category_order := ["combat", "survival", "mobility"]
	var category_labels := {"combat": "COMBAT", "survival": "SURVIVAL", "mobility": "MOBILITY"}
	for cat in category_order:
		if not by_category.has(cat):
			continue
		# Category header
		var header := Label.new()
		header.text = "── %s ──" % str(category_labels.get(cat, cat.to_upper()))
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 1.0))
		vbox.add_child(header)

		for upg in by_category[cat]:
			var upg_id := str(upg.get("id", ""))
			var upg_name := str(upg.get("name", upg_id))
			var upg_desc := str(upg.get("description", ""))

			var row := HBoxContainer.new()
			vbox.add_child(row)

			var lbl := Label.new()
			lbl.name = "VendorLbl_" + upg_id
			lbl.text = "%s — %s" % [upg_name, upg_desc]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(lbl)

			var btn := Button.new()
			btn.name = "VendorBtn_" + upg_id
			btn.text = "Buy"
			var cap_id := upg_id
			btn.pressed.connect(func(): _on_vendor_button_pressed(cap_id))
			row.add_child(btn)
			vendor_upgrade_buttons[upg_id] = btn
			vendor_upgrade_labels[upg_id] = lbl

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var back_btn := Button.new()
	back_btn.text = "<- Back to Sanctuary"
	back_btn.pressed.connect(func():
		_play_cancel()
		_show_prep()
	)
	vbox.add_child(back_btn)

	# Wire the existing vendor button in PrepScreen if it exists
	var existing_vendor_btn := prep_screen.find_child("VendorButton", true, false)
	if existing_vendor_btn is Button:
		existing_vendor_btn.pressed.connect(func(): _show_vendor())
	else:
		var vendor_nav_btn := Button.new()
		vendor_nav_btn.name = "VendorButton"
		vendor_nav_btn.text = "Visit Vendor"
		vendor_nav_btn.pressed.connect(func():
			_play_click()
			_show_vendor()
		)
		var prep_vbox := prep_screen.get_node("PrepVBox")
		if prep_vbox:
			prep_vbox.add_child(vendor_nav_btn)

# ── M27 — Resonance Shrine ────────────────────────────────────────────────────

func _setup_shrine_panel() -> void:
	shrine_panel = PanelContainer.new()
	shrine_panel.name = "ShrinePanel"
	shrine_panel.visible = false
	shrine_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shrine_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	shrine_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "ShrineVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "RESONANCE SHRINE"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	shrine_shard_label = Label.new()
	shrine_shard_label.name = "ShrineShardsLabel"
	shrine_shard_label.text = "Resonance Shards: 0"
	shrine_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shrine_shard_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.9, 1.0))
	vbox.add_child(shrine_shard_label)

	# Flavor text on first visit
	var flavor := Label.new()
	flavor.name = "ShrineFlavor"
	flavor.text = "The Shrine remembers what you've done out there. Spend wisely — it doesn't forget."
	flavor.add_theme_font_size_override("font_size", 12)
	flavor.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 1.0))
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(flavor)

	vbox.add_child(HSeparator.new())

	# Build unlocks grouped by tier
	var unlocks := DataStore.get_permanent_unlocks()
	var tier_names := {1: "TIER 1 — 50 Shards", 2: "TIER 2 — 120 Shards", 3: "TIER 3 — 250 Shards"}
	var by_tier: Dictionary = {}
	for unlock in unlocks:
		var tier := int(unlock.get("tier", 1))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(unlock)

	for tier in [1, 2, 3]:
		if not by_tier.has(tier):
			continue
		var header := Label.new()
		header.text = "── %s ──" % str(tier_names.get(tier, "TIER %d" % tier))
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", Color(0.6, 0.85, 0.9, 1.0))
		vbox.add_child(header)

		for unlock in by_tier[tier]:
			var uid := str(unlock.get("id", ""))
			var uname := str(unlock.get("name", uid))
			var udesc := str(unlock.get("description", ""))
			var ucost := int(unlock.get("cost", 0))

			var row := HBoxContainer.new()
			vbox.add_child(row)

			var lbl := Label.new()
			lbl.name = "ShrineLbl_" + uid
			lbl.text = "%s — %s" % [uname, udesc]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(lbl)

			var btn := Button.new()
			btn.name = "ShrineBtn_" + uid
			btn.text = "%d Shards" % ucost
			var cap_id := uid
			var cap_cost := ucost
			btn.pressed.connect(func(): _on_shrine_unlock_pressed(cap_id, cap_cost))
			row.add_child(btn)
			shrine_unlock_buttons[uid] = btn
			shrine_unlock_labels[uid] = lbl

	vbox.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "<- Back to Sanctuary"
	back_btn.pressed.connect(func():
		_play_cancel()
		_show_prep()
	)
	vbox.add_child(back_btn)

	# Add shrine navigation button to prep screen
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox:
		var shrine_nav_btn := Button.new()
		shrine_nav_btn.name = "ShrineButton"
		shrine_nav_btn.text = "Resonance Shrine"
		shrine_nav_btn.pressed.connect(func():
			_play_click()
			_show_shrine()
		)
		prep_vbox.add_child(shrine_nav_btn)

func _show_shrine() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = true
		_refresh_shrine_ui()

func _on_shrine_unlock_pressed(unlock_id: String, cost: int) -> void:
	var success := GameState.purchase_permanent_unlock(unlock_id, cost)
	if success:
		# M28 — Shard unlock SFX
		if AudioManager:
			AudioManager.play_sfx("shard_earn")
		# M32 — Check shrine-related achievements
		if AchievementManager:
			AchievementManager.check_after_shrine_purchase()
		_refresh_shrine_ui()

func _refresh_shrine_ui() -> void:
	if shrine_shard_label:
		shrine_shard_label.text = "Resonance Shards: %d" % GameState.get_available_shards()

	for uid in shrine_unlock_buttons:
		var btn: Button = shrine_unlock_buttons[uid]
		var unlock := DataStore.get_permanent_unlock(uid)
		var ucost := int(unlock.get("cost", 0))
		var owned := GameState.has_permanent_unlock(uid)
		var available := GameState.get_available_shards()

		if owned:
			btn.text = "Unlocked"
			btn.disabled = true
		elif available < ucost:
			btn.text = "%d Shards" % ucost
			btn.disabled = true
		else:
			btn.text = "%d Shards" % ucost
			btn.disabled = false

		if shrine_unlock_labels.has(uid):
			var lbl: Label = shrine_unlock_labels[uid]
			if owned:
				lbl.add_theme_color_override("font_color", Color(0.4, 0.75, 0.4, 1.0))

# ── M31 — Challenge Runs ─────────────────────────────────────────────────────

func _setup_challenge_panel() -> void:
	challenge_panel = PanelContainer.new()
	challenge_panel.name = "ChallengePanel"
	challenge_panel.visible = false
	challenge_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(challenge_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	challenge_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "ChallengeVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "CHALLENGE RUNS"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	challenge_status_label = Label.new()
	challenge_status_label.name = "ChallengeStatusLabel"
	challenge_status_label.text = "No challenge selected"
	challenge_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_status_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.9, 1.0))
	vbox.add_child(challenge_status_label)

	var flavor := Label.new()
	flavor.text = "The Compact measured competence by what you survived, not what you avoided."
	flavor.add_theme_font_size_override("font_size", 12)
	flavor.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 1.0))
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(flavor)

	vbox.add_child(HSeparator.new())

	# "No Challenge" option
	var no_challenge_btn := Button.new()
	no_challenge_btn.name = "NoChallengeBtn"
	no_challenge_btn.text = "No Challenge"
	no_challenge_btn.pressed.connect(func():
		_play_click()
		ChallengeManager.clear_challenge()
		_refresh_challenge_ui()
	)
	vbox.add_child(no_challenge_btn)

	vbox.add_child(HSeparator.new())

	# Build challenge rows
	var challenges := DataStore.get_challenge_runs()
	for ch in challenges:
		var cid := str(ch.get("id", ""))
		var cname := str(ch.get("name", cid))
		var cdesc := str(ch.get("description", ""))
		var cbonus := int(ch.get("shard_bonus", 0))

		var row := VBoxContainer.new()
		vbox.add_child(row)

		var lbl := Label.new()
		lbl.name = "ChallengeLbl_" + cid
		lbl.text = "%s — %s  [+%d Shards]" % [cname, cdesc, cbonus]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl)
		challenge_labels[cid] = lbl

		var btn := Button.new()
		btn.name = "ChallengeBtn_" + cid
		btn.text = "Select"
		var cap_id := cid
		btn.pressed.connect(func():
			_play_click()
			ChallengeManager.select_challenge(cap_id)
			_refresh_challenge_ui()
		)
		row.add_child(btn)
		challenge_buttons[cid] = btn

		var spacer := Control.new()
		spacer.custom_minimum_size.y = 4
		vbox.add_child(spacer)

	vbox.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "<- Back to Sanctuary"
	back_btn.pressed.connect(func():
		_play_cancel()
		_show_prep()
	)
	vbox.add_child(back_btn)

	# Add navigation button to prep screen
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox:
		var challenge_nav_btn := Button.new()
		challenge_nav_btn.name = "ChallengeButton"
		challenge_nav_btn.text = "Challenge Runs"
		challenge_nav_btn.pressed.connect(func():
			_play_click()
			_show_challenge()
		)
		prep_vbox.add_child(challenge_nav_btn)

func _show_challenge() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = true
		_refresh_challenge_ui()

func _refresh_challenge_ui() -> void:
	# Update status label
	if challenge_status_label:
		if ChallengeManager.is_challenge_active():
			var ch := ChallengeManager.get_active_challenge_data()
			challenge_status_label.text = "Active: %s  [+%d Shards]" % [
				str(ch.get("name", "")), int(ch.get("shard_bonus", 0))]
		else:
			challenge_status_label.text = "No challenge selected"

	for cid in challenge_buttons:
		var btn: Button = challenge_buttons[cid]
		var ch := DataStore.get_challenge_run(cid)
		var unlock_type := str(ch.get("unlock_type", ""))
		var threshold := int(ch.get("unlock_threshold", 0))
		var unlocked := false
		if unlock_type == "total_runs":
			unlocked = GameState.total_runs >= threshold
		elif unlock_type == "artifact_retrievals":
			unlocked = GameState.artifact_retrievals >= threshold
		var is_selected := ChallengeManager.has_challenge(cid)

		if is_selected:
			btn.text = "✓ Selected"
			btn.disabled = true
		elif not unlocked:
			if unlock_type == "artifact_retrievals":
				btn.text = "Locked (retrieve %d artifact)" % threshold
			else:
				btn.text = "Locked (%d runs)" % threshold
			btn.disabled = true
		else:
			btn.text = "Select"
			btn.disabled = false

		if challenge_labels.has(cid):
			var lbl: Label = challenge_labels[cid]
			if is_selected:
				lbl.add_theme_color_override("font_color", Color(0.4, 0.75, 0.4, 1.0))
			elif not unlocked:
				lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
			else:
				lbl.remove_theme_color_override("font_color")

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

func _setup_how_to_play_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "HowToPlayButton"
	btn.text = "?  How to Play"
	btn.pressed.connect(func():
		_play_click()
		_show_how_to_play()
	)
	prep_vbox.add_child(btn)

func _setup_recovered_notes_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "RecoveredNotesButton"
	btn.text = "Recovered Notes"
	btn.visible = not GameState.collected_fragments.is_empty()
	btn.pressed.connect(func():
		_play_click()
		_show_recovered_notes()
	)
	prep_vbox.add_child(btn)

func _setup_settings_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "SettingsButton"
	btn.text = "Settings"
	btn.pressed.connect(func():
		_play_click()
		_open_settings_modal()
	)
	prep_vbox.add_child(btn)

const SettingsScreenScene = preload("res://scenes/ui/settings_screen.tscn")

func _open_settings_modal() -> void:
	var settings := SettingsScreenScene.instantiate()
	add_child(settings)

const HowToPlayScene = preload("res://scenes/ui/how_to_play.tscn")

func _show_how_to_play() -> void:
	var htp := HowToPlayScene.instantiate()
	add_child(htp)

func _refresh_vendor_ui() -> void:
	if vendor_loot_label:
		vendor_loot_label.text = "Silver available: %d" % GameState.banked_loot

	# M31 — naked_run: disable all vendor buttons
	var vendor_locked := ChallengeManager and ChallengeManager.has_challenge("naked_run")

	for upg_id in vendor_upgrade_buttons:
		var btn: Button = vendor_upgrade_buttons[upg_id]
		var upg := DataStore.get_vendor_upgrade(upg_id)
		var cost := int(upg.get("cost", 9999))
		var max_level := int(upg.get("max_level", 1))
		var current_level := GameState.get_upgrade_level(upg_id)
		var is_maxed := current_level >= max_level
		var can_buy := not is_maxed and GameState.banked_loot >= cost

		if vendor_locked:
			btn.text = "Challenge Active"
			btn.disabled = true
		elif is_maxed:
			btn.text = "Owned (MAX)"
			btn.disabled = true
		elif current_level > 0:
			btn.text = "Owned Lv %d — Upgrade (%d)" % [current_level, cost]
			btn.disabled = not can_buy
		else:
			btn.text = "Buy (%d)" % cost
			btn.disabled = not can_buy

		# Update label styling for owned upgrades
		if vendor_upgrade_labels.has(upg_id):
			var lbl: Label = vendor_upgrade_labels[upg_id]
			if is_maxed:
				lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
			elif current_level > 0:
				lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1.0))
			else:
				lbl.remove_theme_color_override("font_color")

# ── M22 — Genn purchase toast ─────────────────────────────────────────────────

func show_vendor_purchase_toast(line: String) -> void:
	if line == "":
		return
	# Clean up any existing vendor toast
	if _vendor_toast != null and is_instance_valid(_vendor_toast):
		_vendor_toast.queue_free()
	_vendor_toast = Label.new()
	_vendor_toast.name = "VendorToast"
	_vendor_toast.text = "Genn: \"%s\"" % line
	_vendor_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vendor_toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_vendor_toast.offset_top = -50
	_vendor_toast.offset_bottom = -10
	_vendor_toast.add_theme_font_size_override("font_size", 13)
	_vendor_toast.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	_vendor_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vendor_toast.z_index = 5
	add_child(_vendor_toast)
	# Auto-dismiss after 2.5 seconds
	var timer := get_tree().create_timer(2.5)
	var toast_ref := _vendor_toast
	timer.timeout.connect(func():
		if is_instance_valid(toast_ref):
			toast_ref.queue_free()
	)

# ── M23 — Lore Fragment Pickup Modal ──────────────────────────────────────────

signal fragment_pickup_dismissed

func show_fragment_pickup(fragment: Dictionary) -> void:
	## Display a "RECOVERED NOTE" modal for a newly found lore fragment.
	if fragment.is_empty():
		fragment_pickup_dismissed.emit()
		return

	var overlay := PanelContainer.new()
	overlay.name = "FragmentPickupOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 12
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "RECOVERED NOTE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	vbox.add_child(header)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var title_label := Label.new()
	title_label.text = str(fragment.get("title", "Unknown Document"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 1.0))
	vbox.add_child(title_label)

	var author_label := Label.new()
	var author := str(fragment.get("author", ""))
	if author != "":
		author_label.text = "— %s" % author
		author_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		author_label.add_theme_font_size_override("font_size", 11)
		author_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.8))
		vbox.add_child(author_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var body := Label.new()
	body.name = "FragmentBody"
	body.text = str(fragment.get("text", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72, 1.0))
	scroll.add_child(body)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var btn := Button.new()
	btn.text = "Pocket It"
	btn.pressed.connect(func():
		_play_click()
		overlay.queue_free()
		fragment_pickup_dismissed.emit()
	)
	vbox.add_child(btn)

# ── M23 — Recovered Notes Archive ────────────────────────────────────────────

func _show_recovered_notes() -> void:
	var overlay := PanelContainer.new()
	overlay.name = "RecoveredNotesOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "RECOVERED NOTES  (%d / 5)" % GameState.collected_fragments.size()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	vbox.add_child(header)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var notes_vbox := VBoxContainer.new()
	notes_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(notes_vbox)

	for frag_id in GameState.collected_fragments:
		var frag := NarrativeManager.get_lore_fragment(str(frag_id))
		if frag.is_empty():
			continue
		var frag_title := str(frag.get("title", "Unknown"))
		var frag_author := str(frag.get("author", ""))
		var frag_text := str(frag.get("text", ""))

		# Collapsible entry: title button toggles body visibility
		var entry_btn := Button.new()
		entry_btn.text = frag_title
		entry_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		notes_vbox.add_child(entry_btn)

		var entry_body := Label.new()
		entry_body.text = frag_text
		if frag_author != "":
			entry_body.text += "\n\n— %s" % frag_author
		entry_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_body.visible = false
		entry_body.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72, 1.0))
		notes_vbox.add_child(entry_body)

		var body_ref := entry_body
		entry_btn.pressed.connect(func():
			body_ref.visible = not body_ref.visible
		)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		_play_click()
		overlay.queue_free()
	)
	vbox.add_child(close_btn)

func _show_run_history() -> void:
	# Display run history in prep_status for simplicity
	var history := GameState.get_run_history()
	if history.is_empty():
		prep_status.text = "No runs yet. Enter the Ring!"
		return
	var lines: PackedStringArray = []
	lines.append("── Run History (last %d) ──" % history.size())
	var start_idx: int = max(0, history.size() - 10)
	for i in range(history.size() - 1, start_idx - 1, -1):
		var entry: Dictionary = history[i]
		var ring := str(entry.get("ring", "?"))
		var outcome := "✓ Extracted" if bool(entry.get("extracted", false)) else "✗ Died"
		var xp := int(entry.get("unbanked_xp", 0))
		var loot := int(entry.get("unbanked_loot", 0))
		lines.append("Ring: %s | %s | XP: %d Loot: %d" % [ring, outcome, xp, loot])
	prep_status.text = "\n".join(lines)

# ── M32 — Achievement Toast ──────────────────────────────────────────────────

func _show_achievement_toast(achievement_id: String) -> void:
	if not AchievementManager:
		return
	var ach := AchievementManager.get_achievement(achievement_id)
	if ach.is_empty():
		return

	# Clean up existing toast
	if _achievement_toast != null and is_instance_valid(_achievement_toast):
		_achievement_toast.queue_free()

	_achievement_toast = PanelContainer.new()
	_achievement_toast.name = "AchievementToast"
	_achievement_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_achievement_toast.offset_top = 20
	_achievement_toast.offset_bottom = 100
	_achievement_toast.offset_left = -200
	_achievement_toast.offset_right = 200
	_achievement_toast.z_index = 20
	add_child(_achievement_toast)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_achievement_toast.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "★  Achievement Unlocked"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = str(ach.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(ach.get("description", ""))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65, 0.9))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Auto-dismiss after 4 seconds
	var timer := get_tree().create_timer(4.0)
	var toast_ref := _achievement_toast
	timer.timeout.connect(func():
		if is_instance_valid(toast_ref):
			toast_ref.queue_free()
	)

# ── M32 — Achievement Gallery ────────────────────────────────────────────────

func _setup_achievements_button() -> void:
	var prep_vbox := prep_screen.get_node("PrepVBox")
	if prep_vbox == null:
		return
	var btn := Button.new()
	btn.name = "AchievementsButton"
	btn.text = "Achievements"
	btn.pressed.connect(func():
		_play_click()
		_show_achievements()
	)
	prep_vbox.add_child(btn)

func _setup_achievement_panel() -> void:
	achievement_panel = PanelContainer.new()
	achievement_panel.name = "AchievementPanel"
	achievement_panel.visible = false
	achievement_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(achievement_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	achievement_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "AchievementVBox"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# Header with count
	var header := Label.new()
	header.name = "AchievementHeader"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(header)

	vbox.add_child(HSeparator.new())

	# Scrollable content area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "AchievementContent"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)

	vbox.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "<- Back to Sanctuary"
	back_btn.pressed.connect(func():
		_play_cancel()
		_show_prep()
	)
	vbox.add_child(back_btn)

func _show_achievements() -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if shrine_panel:
		shrine_panel.visible = false
	if challenge_panel:
		challenge_panel.visible = false
	if achievement_panel:
		achievement_panel.visible = true
		_refresh_achievement_ui()

func _refresh_achievement_ui() -> void:
	if not AchievementManager or not achievement_panel:
		return

	# Update header
	var header: Label = achievement_panel.find_child("AchievementHeader", true, false)
	if header:
		header.text = "ACHIEVEMENTS  %d / %d" % [
			AchievementManager.get_unlocked_count(),
			AchievementManager.get_total_count()]

	# Rebuild content
	var content: VBoxContainer = achievement_panel.find_child("AchievementContent", true, false)
	if not content:
		return

	# Clear existing children
	for child in content.get_children():
		child.queue_free()

	var cat_data := AchievementManager.get_category_data()
	var categories: Dictionary = cat_data.get("categories", {})
	var order: Array = cat_data.get("category_order", [])
	var all_achs := AchievementManager.get_all_achievements()

	for cat_id in order:
		var cat_name: String = str(categories.get(cat_id, cat_id.to_upper()))

		# Category header
		var cat_label := Label.new()
		cat_label.text = "\n%s" % cat_name
		cat_label.add_theme_font_size_override("font_size", 14)
		cat_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
		content.add_child(cat_label)

		content.add_child(HSeparator.new())

		# Achievement entries in this category
		for ach in all_achs:
			if str(ach.get("category", "")) != cat_id:
				continue

			var ach_id := str(ach.get("id", ""))
			var unlocked := AchievementManager.is_unlocked(ach_id)
			var is_hidden := bool(ach.get("hidden", false))

			var entry := VBoxContainer.new()
			entry.add_theme_constant_override("separation", 2)

			var name_label := Label.new()
			var desc_label := Label.new()

			if unlocked:
				# Unlocked: gold styling
				name_label.text = "★  %s" % str(ach.get("name", ""))
				name_label.add_theme_font_size_override("font_size", 13)
				name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))

				var desc_text := str(ach.get("description", ""))
				var flavor := str(ach.get("flavor_text", ""))
				if flavor != "":
					desc_text += "  —  \"%s\"" % flavor
				desc_label.text = desc_text
				desc_label.add_theme_font_size_override("font_size", 11)
				desc_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65, 0.9))
				desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			elif is_hidden:
				# Hidden locked: show ???
				name_label.text = "?  ???"
				name_label.add_theme_font_size_override("font_size", 13)
				name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.7))
				desc_label.text = "???"
				desc_label.add_theme_font_size_override("font_size", 11)
				desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.5))
			else:
				# Locked visible: grey styling
				name_label.text = "○  %s" % str(ach.get("name", ""))
				name_label.add_theme_font_size_override("font_size", 13)
				name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))

				var desc_text := str(ach.get("description", ""))
				# Show progress for count-based achievements
				var progress := AchievementManager.get_progress(ach_id)
				if int(progress.get("target", 1)) > 1:
					desc_text += "  (%d / %d)" % [int(progress.get("current", 0)), int(progress.get("target", 1))]
				desc_label.text = desc_text
				desc_label.add_theme_font_size_override("font_size", 11)
				desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
				desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			entry.add_child(name_label)
			entry.add_child(desc_label)
			content.add_child(entry)

			# Small spacer
			var spacer := Control.new()
			spacer.custom_minimum_size.y = 4
			content.add_child(spacer)
