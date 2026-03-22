extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const CombatArenaScene = preload("res://scenes/combat/combat_arena.tscn")
const ContractSystem = preload("res://scripts/systems/contract_system.gd")
const VendorSystem = preload("res://scripts/systems/vendor_system.gd")

@onready var flow_ui: FlowUI = $FlowUI

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()
var contract_system := ContractSystem.new()
var vendor_system := VendorSystem.new()
var active_encounter: Dictionary = {}
var selected_weapon_id: String = "blade_iron"
var combat_arena: CombatArena = null
var current_run_ring: String = "inner"
var pending_run_ring: String = ""
var pending_run_seed: int = 0

func _ready() -> void:
	print("The Long Walk MVP Slice 1 booted")
	_load_save_state()
	_connect_ui()
	_connect_state()
	_initialize_loadouts()
	flow_ui.on_idle_ready()

func _connect_ui() -> void:
	flow_ui.start_run_pressed.connect(_on_start_run_pressed)
	flow_ui.resolve_encounter_pressed.connect(_on_resolve_encounter_pressed)
	flow_ui.extract_pressed.connect(_on_extract_pressed)
	flow_ui.die_pressed.connect(_on_die_pressed)
	flow_ui.loadout_selected.connect(_on_loadout_selected)
	flow_ui.vendor_purchase_pressed.connect(_on_vendor_purchase_pressed)
	flow_ui.modifier_selected.connect(_on_modifier_selected)

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

func _begin_run(ring_id: String, seed: int) -> void:
	current_run_ring = ring_id
	GameState.start_run(seed, ring_id)
	# Get contract target from ring data
	var ring_data := DataStore.get_ring(ring_id)
	var contract_target := int(ring_data.get("contract_target", 3))
	var contract_id := "ring_%s_clearance" % ring_id
	var contract := contract_system.start_contract(contract_id, ring_id, contract_target)
	flow_ui.on_objective_started(contract)
	active_encounter = ring_director.generate_encounter(
		seed,
		ring_id,
		DataStore.enemies,
		DataStore.encounter_templates
	)
	_ensure_combat_arena()
	combat_arena.set_context(ring_id, seed, int(active_encounter.get("enemy_count", 1)))
	combat_arena.set_arena_active(true)
	flow_ui.set_current_loadout(selected_weapon_id)

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

func _on_extract_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if not contract_system.can_extract():
		flow_ui.on_extract_blocked(contract_system.get_contract())
		return
	GameState.extract()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	contract_system.reset()
	_save_state()

func _on_die_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	GameState.die_in_run()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	contract_system.fail_active_contract()
	flow_ui.on_objective_failed(contract_system.get_contract())
	_save_state()

func _on_extracted_signal(total_xp: int, total_loot: int) -> void:
	flow_ui.on_extracted(total_xp, total_loot)
	if combat_arena != null:
		combat_arena.set_arena_active(false)

func _on_player_died() -> void:
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)
	_save_state()

func _on_vendor_purchase_pressed(upgrade_id: String) -> void:
	var purchased := vendor_system.purchase(upgrade_id)
	if purchased:
		_save_state()
		flow_ui.refresh_vendor()

func _ensure_combat_arena() -> void:
	if combat_arena != null:
		return
	combat_arena = CombatArenaScene.instantiate() as CombatArena
	add_child(combat_arena)
	combat_arena.attack_hook_triggered.connect(_on_attack_hook_triggered)
	combat_arena.dodge_hook_triggered.connect(_on_dodge_hook_triggered)
	combat_arena.guard_hook_changed.connect(_on_guard_hook_changed)
	combat_arena.encounter_cleared.connect(_on_encounter_cleared)

func _on_attack_hook_triggered() -> void:
	print("Combat hook: attack")

func _on_dodge_hook_triggered() -> void:
	print("Combat hook: dodge")

func _on_guard_hook_changed(is_guarding: bool) -> void:
	print("Combat hook: guard=%s" % is_guarding)

func _on_encounter_cleared(enemy_count: int) -> void:
	print("Combat hook: encounter cleared (%d enemies)" % enemy_count)
	_on_resolve_encounter_pressed()

func _initialize_loadouts() -> void:
	var weapons := DataStore.weapons.get("weapons", [])
	if weapons.size() > 0:
		selected_weapon_id = str(weapons[0].get("id", selected_weapon_id))
	flow_ui.set_available_loadouts(weapons)
	flow_ui.set_current_loadout(selected_weapon_id)

func _on_loadout_selected(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	flow_ui.set_current_loadout(selected_weapon_id)

func _load_save_state() -> void:
	var state := SaveSystem.load_state(GameState.default_save_state())
	GameState.apply_save_state(state)

func _save_state() -> void:
	SaveSystem.save_state(GameState.to_save_state())
