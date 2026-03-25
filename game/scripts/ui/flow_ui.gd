extends CanvasLayer
class_name FlowUI

signal start_run_pressed(ring_id: String)
signal resolve_encounter_pressed
signal extract_pressed
signal die_pressed
signal loadout_selected(weapon_id: String)
signal vendor_purchase_pressed(upgrade_id: String)
signal modifier_selected(modifier_id: String)

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

# Victory / Death / Modifier panels (created dynamically)
var victory_panel: PanelContainer = null
var death_panel: PanelContainer = null
var modifier_panel: PanelContainer = null

var run_base_status: String = ""
var objective_status: String = ""

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
	_setup_victory_panel()
	_setup_death_panel()
	_setup_modifier_panel()
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
	if victory_panel:
		victory_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
	if AudioManager:
		AudioManager.play_sanctuary_music()

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

func _show_victory(stats: Dictionary) -> void:
	prep_screen.visible = false
	run_screen.visible = false
	if vendor_panel:
		vendor_panel.visible = false
	if death_panel:
		death_panel.visible = false
	if modifier_panel:
		modifier_panel.visible = false
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
	if modifier_panel:
		_populate_modifier_panel(choices)
		modifier_panel.visible = true

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
	var stats := GameState.get_run_stats()
	_show_victory(stats)
	_refresh_ring_buttons()

func on_died(unbanked_xp: int, unbanked_loot: int) -> void:
	var ring_id := GameState.current_ring
	if ring_id == "sanctuary":
		ring_id = str(GameState.run_history[-1].get("ring", "inner")) if not GameState.run_history.is_empty() else "inner"
	_show_death(ring_id, GameState.run_last_enemy_killer)
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
	# Display the prologue beats as concatenated text in prep_status for now.
	# A full cinematic sequence can be layered on in a future milestone.
	var lines: PackedStringArray = []
	for beat in beats:
		var beat_lines: Array = beat.get("lines", [])
		for line in beat_lines:
			lines.append(str(line))
		# Add dialogue choices summary if present
		var choices: Array = beat.get("choices", [])
		if not choices.is_empty():
			lines.append("")
			for choice in choices:
				lines.append("[%s] %s" % [str(choice.get("text", "")), str(choice.get("response", ""))])
		lines.append("")
	prep_status.text = "\n".join(lines)

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
	flavor_label.text = str(lines[idx])

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
		var cap_mod := mod
		btn.pressed.connect(func():
			_play_click()
			GameState.set_active_modifiers([cap_mod])
			modifier_selected.emit(cap_id)
			_show_run()
		)
		choices_container.add_child(btn)

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
