extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const CombatArenaScene = preload("res://scenes/combat/combat_arena.tscn")
const ContractSystem = preload("res://scripts/systems/contract_system.gd")
const VendorSystem = preload("res://scripts/systems/vendor_system.gd")
const TitleScreenScene = preload("res://scenes/ui/title_screen.tscn")
const SettingsScreenScene = preload("res://scenes/ui/settings_screen.tscn")

@onready var flow_ui: FlowUI = $FlowUI

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()
var contract_system := ContractSystem.new()
var vendor_system := VendorSystem.new()
var active_encounter: Dictionary = {}
var equipped_melee: String = "blade_iron"
var equipped_ranged: String = "bow_iron"
var equipped_magic: String = "resonance_staff"
var combat_arena: CombatArena = null
var current_run_ring: String = "inner"
var pending_run_ring: String = ""
var pending_run_seed: int = 0
var _pending_boss_fight: bool = false
var title_screen: Node = null
var _challenge_timer: Timer = null  # M31 — time_pressure ring timer

func _ready() -> void:
	print("The Long Walk MVP Slice 1 booted")
	_load_save_state()
	_connect_ui()
	_connect_state()
	_initialize_loadouts()
	# M20 — Show title screen as entry point instead of jumping straight to sanctuary
	_show_title_screen()

func _connect_ui() -> void:
	flow_ui.start_run_pressed.connect(_on_start_run_pressed)
	flow_ui.resolve_encounter_pressed.connect(_on_resolve_encounter_pressed)
	flow_ui.extract_pressed.connect(_on_extract_pressed)
	flow_ui.die_pressed.connect(_on_die_pressed)
	flow_ui.loadout_updated.connect(_on_loadout_updated)
	flow_ui.vendor_purchase_pressed.connect(_on_vendor_purchase_pressed)
	flow_ui.modifier_selected.connect(_on_modifier_selected)
	flow_ui.warden_gate_dismissed.connect(_on_warden_gate_dismissed)
	# M21 — Return to title from run summary
	flow_ui.return_to_title_pressed.connect(_on_return_to_title)

func _connect_state() -> void:
	GameState.run_started.connect(flow_ui.on_run_started)
	GameState.encounter_completed.connect(flow_ui.on_encounter_resolved)
	GameState.extracted.connect(_on_extracted_signal)
	GameState.player_died.connect(_on_player_died)

func _on_start_run_pressed(ring_id: String) -> void:
	# Check if ring is unlocked
	if not GameState.is_ring_unlocked(ring_id, DataStore.rings):
		return
	# Store pending run info and show modifier selection first
	pending_run_ring = ring_id
	pending_run_seed = int(Time.get_unix_time_from_system())
	flow_ui.show_modifier_selection(pending_run_seed)

func _on_modifier_selected(_modifier_id: String) -> void:
	# Modifier already applied to GameState by flow_ui
	# Now actually start the run
	_begin_run(pending_run_ring, pending_run_seed)

func _begin_run(ring_id: String, _seed: int) -> void:
	current_run_ring = ring_id
	# M28 — Ring enter SFX + combat music by ring
	if AudioManager:
		AudioManager.play_sfx("ring_enter")
		var music_map := {"inner": "combat_inner", "mid": "combat_mid", "outer": "combat_outer"}
		var track: String = music_map.get(ring_id, "combat_inner")
		AudioManager.play_music(track)
	# M17 T10 — show ring entry flavor text before run begins
	var entry_text := NarrativeManager.get_ring_text(ring_id, "entry")
	if entry_text != "":
		flow_ui.show_narrative_text(entry_text)
	GameState.start_run(_seed, ring_id)
	# Get contract target from ring data
	var ring_data := DataStore.get_ring(ring_id)
	var contract_target := int(ring_data.get("contract_target", 3))
	# M27 — inner_knowledge permanent unlock: reduce inner ring contract by 1
	if ring_id == "inner" and GameState.has_permanent_unlock("inner_knowledge"):
		contract_target = max(2, contract_target - 1)
	var contract_id := "ring_%s_clearance" % ring_id
	var contract := contract_system.start_contract(contract_id, ring_id, contract_target)
	flow_ui.on_objective_started(contract)
	active_encounter = ring_director.generate_encounter(
		_seed,
		ring_id,
		DataStore.enemies,
		DataStore.encounter_templates
	)
	# M25 — Show encounter flavor text banner before combat
	var encounter_flavor := str(active_encounter.get("flavor_text", ""))
	if encounter_flavor != "":
		flow_ui.show_encounter_flavor(encounter_flavor)
	# M31 — time_pressure: start ring timer
	_start_challenge_timer(ring_id)
	_ensure_combat_arena()
	combat_arena.set_context(ring_id, _seed, int(active_encounter.get("enemy_count", 1)))
	combat_arena.set_equipped_weapons(equipped_melee, equipped_ranged, equipped_magic)
	combat_arena.set_arena_active(true)
	flow_ui.set_current_loadout(equipped_melee, equipped_ranged, equipped_magic)

func _on_resolve_encounter_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if active_encounter.get("enemies", []).is_empty():
		return

	var rewards := reward_system.calculate_rewards(
		current_run_ring,
		DataStore.rings,
		int(active_encounter.get("enemy_count", 1))
	)
	GameState.add_unbanked(int(rewards["xp"]), int(rewards["loot"]))
	var contract := contract_system.record_encounter_completed()
	flow_ui.on_objective_progress(contract)
	active_encounter = {}

# M19 T6 — Extraction hold delay
const EXTRACTION_HOLD_DELAY := 0.5

func _on_extract_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	# M31 — warden_hunt: block extraction until artifact is retrieved
	if ChallengeManager and ChallengeManager.has_challenge("warden_hunt") and not GameState.artifact_retrieved:
		flow_ui.on_extract_blocked_challenge("The Warden still stands.")
		return
	# M26 — full_commitment modifier blocks early extraction
	if ModifierManager and ModifierManager.has_flag("block_early_extraction"):
		flow_ui.on_extract_blocked(contract_system.get_contract())
		return
	if not contract_system.can_extract():
		flow_ui.on_extract_blocked(contract_system.get_contract())
		return
	# Outer ring: completing the contract triggers the Warden boss gate
	if current_run_ring == "outer" and not _pending_boss_fight:
		_trigger_warden_gate()
		return
	# M31 — Stop challenge timer on extraction
	_stop_challenge_timer()
	# M19 T6 — Brief hold before routing to reward screen
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	# M28 — Extraction SFX
	if AudioManager:
		AudioManager.play_sfx("extraction")
	var timer := get_tree().create_timer(EXTRACTION_HOLD_DELAY)
	timer.timeout.connect(func():
		GameState.extract()
		contract_system.reset()
		_save_state()
	)

func _on_die_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	# M31 — Stop challenge timer on death
	_stop_challenge_timer()
	GameState.die_in_run()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	contract_system.fail_active_contract()
	flow_ui.on_objective_failed(contract_system.get_contract())
	_save_state()

func _on_extracted_signal(total_xp: int, total_loot: int) -> void:
	# M28 — Victory music on extraction
	if AudioManager:
		AudioManager.play_music("victory")
	flow_ui.on_extracted(total_xp, total_loot)
	if combat_arena != null:
		combat_arena.set_arena_active(false)

# M19 T5 — Death screen delay constant
const DEATH_SCREEN_DELAY := 0.8

var _death_handling: bool = false

func _on_player_died() -> void:
	# Guard against re-entrancy (die_in_run emits player_died signal)
	if _death_handling:
		return
	_death_handling = true
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	# M31 — one_life: no retry, no rewards, straight to run summary
	if ChallengeManager and ChallengeManager.has_challenge("one_life"):
		_stop_challenge_timer()
		GameState.unbanked_xp = 0
		GameState.unbanked_loot = 0
		GameState.die_in_run()
		contract_system.fail_active_contract()
		_save_state()
		_death_handling = false
		return
	# M19 T5 — Let the death moment breathe before showing the panel
	var timer := get_tree().create_timer(DEATH_SCREEN_DELAY)
	timer.timeout.connect(func():
		flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)
		_save_state()
		_death_handling = false
	)

func _on_vendor_purchase_pressed(upgrade_id: String) -> void:
	# M31 — naked_run: cannot purchase upgrades this run
	if ChallengeManager and ChallengeManager.has_challenge("naked_run"):
		return
	# M26 — cursed_silver blocks vendor purchases during a run
	if ModifierManager and ModifierManager.has_flag("vendor_locked"):
		return
	var purchased := vendor_system.purchase(upgrade_id)
	if purchased:
		# M28 — Upgrade purchase SFX
		if AudioManager:
			AudioManager.play_sfx("upgrade_purchase")
		_save_state()
		flow_ui.refresh_vendor()
		# M22 — Show Genn purchase reaction toast
		var purchase_line := get_vendor_purchase_line()
		flow_ui.show_vendor_purchase_toast(purchase_line)

func _ensure_combat_arena() -> void:
	if combat_arena != null:
		return
	combat_arena = CombatArenaScene.instantiate() as CombatArena
	add_child(combat_arena)
	combat_arena.attack_hook_triggered.connect(_on_attack_hook_triggered)
	combat_arena.dodge_hook_triggered.connect(_on_dodge_hook_triggered)
	combat_arena.guard_hook_changed.connect(_on_guard_hook_changed)
	combat_arena.encounter_cleared.connect(_on_encounter_cleared)
	combat_arena.player_died.connect(_on_player_died)

func _on_attack_hook_triggered() -> void:
	print("Combat hook: attack")

func _on_dodge_hook_triggered() -> void:
	print("Combat hook: dodge")

func _on_guard_hook_changed(is_guarding: bool) -> void:
	print("Combat hook: guard=%s" % is_guarding)

func _on_encounter_cleared(enemy_count: int) -> void:
	print("Combat hook: encounter cleared (%d enemies)" % enemy_count)
	_on_resolve_encounter_pressed()
	# M31 — silent_run: skip lore fragments and modifier cards
	var is_silent := ChallengeManager and ChallengeManager.has_challenge("silent_run")
	# M23 — Roll for lore fragment drop after encounter reward
	if not is_silent:
		var frag_seed: int = abs(GameState.active_seed + GameState.run_encounters_cleared)
		var frag_id := GameState.roll_fragment_drop(frag_seed)
		if frag_id != "":
			GameState.collect_fragment(frag_id)
			# M28 — Lore fragment SFX
			if AudioManager:
				AudioManager.play_sfx("lore_fragment")
			var frag := NarrativeManager.get_lore_fragment(frag_id)
			if not frag.is_empty():
				flow_ui.show_fragment_pickup(frag)
	# M26 — Offer a between-encounter run modifier card
	if not is_silent:
		_offer_run_modifier()

# ── M26 — Between-encounter modifier card offer ──────────────────────────────

func _offer_run_modifier() -> void:
	var mod_seed: int = abs(GameState.active_seed + GameState.run_encounters_cleared * 7)
	var offered := ModifierManager.roll_modifier_offer(mod_seed)
	flow_ui.show_modifier_card_offer(offered)

func _initialize_loadouts() -> void:
	var weapons: Array = DataStore.weapons.get("weapons", [])
	# Restore equipped slots from GameState (save migration fills defaults)
	equipped_melee = GameState.equipped_melee
	equipped_ranged = GameState.equipped_ranged
	equipped_magic = GameState.equipped_magic
	flow_ui.set_available_loadouts(weapons)
	flow_ui.set_current_loadout(equipped_melee, equipped_ranged, equipped_magic)

func _on_loadout_updated(melee_id: String, ranged_id: String, magic_id: String) -> void:
	equipped_melee = melee_id
	equipped_ranged = ranged_id
	equipped_magic = magic_id
	GameState.equipped_melee = melee_id
	GameState.equipped_ranged = ranged_id
	GameState.equipped_magic = magic_id
	flow_ui.set_current_loadout(equipped_melee, equipped_ranged, equipped_magic)

func _load_save_state() -> void:
	var state := SaveSystem.load_state(GameState.default_save_state())
	GameState.apply_save_state(state)

func _save_state() -> void:
	SaveSystem.save_state(GameState.to_save_state())

# ── M31 — Challenge Timer (time_pressure) ────────────────────────────────────

func _start_challenge_timer(ring_id: String) -> void:
	_stop_challenge_timer()
	if not ChallengeManager or not ChallengeManager.has_challenge("time_pressure"):
		return
	var ch := ChallengeManager.get_active_challenge_data()
	var limits: Variant = ch.get("time_limits", {})
	if typeof(limits) != TYPE_DICTIONARY:
		return
	var seconds := int(limits.get(ring_id, 0))
	if seconds <= 0:
		return
	_challenge_timer = Timer.new()
	_challenge_timer.one_shot = true
	_challenge_timer.wait_time = float(seconds)
	_challenge_timer.timeout.connect(_on_challenge_timer_expired)
	add_child(_challenge_timer)
	_challenge_timer.start()

func _stop_challenge_timer() -> void:
	if _challenge_timer != null and is_instance_valid(_challenge_timer):
		_challenge_timer.stop()
		_challenge_timer.queue_free()
		_challenge_timer = null

func _on_challenge_timer_expired() -> void:
	_stop_challenge_timer()
	# Time ran out — force death
	_on_die_pressed()

# ── M20 — Title Screen ────────────────────────────────────────────────────────

func _show_title_screen() -> void:
	# M28 — Title music
	if AudioManager:
		AudioManager.play_music("title")
	# Hide FlowUI until title screen is dismissed
	flow_ui.visible = false
	title_screen = TitleScreenScene.instantiate()
	add_child(title_screen)
	var has_save := not GameState.is_first_run() or GameState.banked_xp > 0 or GameState.banked_loot > 0
	title_screen.set_continue_visible(has_save)
	title_screen.begin_pressed.connect(_on_title_begin)
	title_screen.continue_pressed.connect(_on_title_continue)
	title_screen.settings_pressed.connect(_open_settings)

func _on_title_begin() -> void:
	_dismiss_title_screen()
	flow_ui.visible = true
	if GameState.is_first_run() and not _has_seen_prologue():
		# First run — show prologue, then sanctuary
		flow_ui.on_idle_ready()
		flow_ui.show_prologue(NarrativeManager.get_prologue())
		_mark_prologue_seen()
	else:
		# Returning player chose Begin (new run from scratch)
		flow_ui.on_idle_ready()

func _on_title_continue() -> void:
	_dismiss_title_screen()
	flow_ui.visible = true
	flow_ui.on_idle_ready()

func _open_settings() -> void:
	var settings := SettingsScreenScene.instantiate()
	add_child(settings)

func _dismiss_title_screen() -> void:
	if title_screen != null:
		title_screen.queue_free()
		title_screen = null

# ── M17 T9 — Prologue seen flag ───────────────────────────────────────────────

const _PROLOGUE_FLAG_PATH := "user://prologue_seen.flag"

func _has_seen_prologue() -> bool:
	return FileAccess.file_exists(_PROLOGUE_FLAG_PATH)

func _mark_prologue_seen() -> void:
	var f := FileAccess.open(_PROLOGUE_FLAG_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("1")
		f.close()

# ── M18 — Warden Boss Gate + Artifact Extraction ─────────────────────────────

func _trigger_warden_gate() -> void:
	_pending_boss_fight = true
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	var warden_lines := NarrativeManager.get_warden_intro()
	flow_ui.show_warden_gate(warden_lines)

func _on_warden_gate_dismissed() -> void:
	if not _pending_boss_fight:
		return
	# M28 — Warden boss music
	if AudioManager:
		AudioManager.play_music("warden")
	# Start boss combat
	_ensure_combat_arena()
	combat_arena.set_context(current_run_ring, GameState.active_seed, 1, true)
	combat_arena.set_arena_active(true)
	combat_arena.boss_defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)

func _on_boss_defeated() -> void:
	_pending_boss_fight = false
	_stop_challenge_timer()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	# M28 — Artifact pickup SFX + victory music
	if AudioManager:
		AudioManager.play_sfx("artifact_pickup")
		AudioManager.play_music("victory")
	# Artifact extraction sequence
	var extraction_text := NarrativeManager.get_ring_text("outer", "extraction")
	var artifact_text := NarrativeManager.get_artifact_text()
	GameState.retrieve_artifact()
	contract_system.reset()
	_save_state()
	flow_ui.show_artifact_victory(extraction_text, artifact_text)

# ── M17 T11 — Vendor dialogue integration ────────────────────────────────────

## Called by flow_ui when the player opens the vendor screen.
func get_vendor_greeting() -> String:
	return NarrativeManager.get_npc_line("genn_vendor")

## Called by flow_ui after a successful purchase.
func get_vendor_purchase_line() -> String:
	return NarrativeManager.get_genn_vendor_reaction("purchase")

# ── M21 — Return to title from run summary ───────────────────────────────────

func _on_return_to_title() -> void:
	flow_ui.visible = false
	_save_state()
	_show_title_screen()
