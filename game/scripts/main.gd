extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const CombatArenaScene = preload("res://scenes/combat/combat_arena.tscn")
const ContractSystem = preload("res://scripts/systems/contract_system.gd")

@onready var flow_ui: FlowUI = $FlowUI

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()
var contract_system := ContractSystem.new()
var active_encounter: Dictionary = {}
var selected_weapon_id: String = "blade_iron"
var combat_arena: CombatArena = null

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
	flow_ui.descend_warden_pressed.connect(_on_descend_warden_pressed)

func _connect_state() -> void:
	GameState.run_started.connect(flow_ui.on_run_started)
	GameState.encounter_completed.connect(flow_ui.on_encounter_resolved)
	GameState.extracted.connect(flow_ui.on_extracted)
	GameState.player_died.connect(_on_player_died)

func _on_start_run_pressed() -> void:
	var seed := Time.get_unix_time_from_system()
	GameState.start_run(int(seed), GameState.current_ring)
	var ring_data: Dictionary = {}
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == GameState.current_ring:
			ring_data = r
			break
	var contract_target: int = ring_data.get("contract_target", 3)
	var contract := contract_system.start_contract("ring_clearance", GameState.current_ring, contract_target)
	flow_ui.on_objective_started(contract)
	active_encounter = ring_director.generate_encounter(
		int(seed),
		GameState.current_ring,
		DataStore.enemies,
		DataStore.encounter_templates
	)
	_ensure_combat_arena()
	combat_arena.set_context(GameState.current_ring, int(seed), int(active_encounter.get("enemy_count", 1)))
	combat_arena.set_arena_active(true)
	flow_ui.set_current_loadout(selected_weapon_id)

func _on_resolve_encounter_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if active_encounter.get("enemies", []).is_empty():
		return

	var rewards := reward_system.calculate_rewards(
		GameState.current_ring,
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

func _on_player_died() -> void:
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)

func _on_combat_player_died() -> void:
	if GameState.current_ring == "sanctuary":
		return
	GameState.die_in_run()
	contract_system.fail_active_contract()
	flow_ui.on_objective_failed(contract_system.get_contract())
	_save_state()

func _ensure_combat_arena() -> void:
	if combat_arena != null:
		return
	combat_arena = CombatArenaScene.instantiate() as CombatArena
	add_child(combat_arena)
	combat_arena.attack_hook_triggered.connect(_on_attack_hook_triggered)
	combat_arena.dodge_hook_triggered.connect(_on_dodge_hook_triggered)
	combat_arena.guard_hook_changed.connect(_on_guard_hook_changed)
	combat_arena.encounter_cleared.connect(_on_encounter_cleared)
	combat_arena.boss_encounter_cleared.connect(_on_warden_defeated)
	combat_arena.player_died.connect(_on_combat_player_died)

func _on_attack_hook_triggered() -> void:
	print("Combat hook: attack")

func _on_dodge_hook_triggered() -> void:
	print("Combat hook: dodge")

func _on_guard_hook_changed(is_guarding: bool) -> void:
	print("Combat hook: guard=%s" % is_guarding)

func _on_encounter_cleared(enemy_count: int) -> void:
	print("Combat hook: encounter cleared (%d enemies)" % enemy_count)
	_on_resolve_encounter_pressed()

func _on_descend_warden_pressed() -> void:
	_ensure_combat_arena()
	combat_arena.set_arena_active(true)
	combat_arena.start_boss_encounter("outer_warden")

func _on_warden_defeated() -> void:
	GameState.warden_defeated = true
	GameState.game_completed = true
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	_save_state()
	flow_ui.show_credits()

func _initialize_loadouts() -> void:
	var weapons: Array = DataStore.weapons.get("weapons", [])
	if weapons.size() > 0:
		selected_weapon_id = str(weapons[0].get("id", selected_weapon_id))
	flow_ui.set_available_loadouts(weapons)
	flow_ui.set_current_loadout(selected_weapon_id)

func _on_loadout_selected(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	GameState.selected_weapon_id = weapon_id
	flow_ui.set_current_loadout(selected_weapon_id)
	if is_instance_valid(combat_arena) and is_instance_valid(combat_arena.player):
		combat_arena.player.reload_weapon_stats()

func _load_save_state() -> void:
	var state := SaveSystem.load_state(GameState.default_save_state())
	GameState.apply_save_state(state)

func _save_state() -> void:
	SaveSystem.save_state(GameState.to_save_state())
