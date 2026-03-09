extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")

@onready var flow_ui: FlowUI = $FlowUI

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()
var active_encounter: Dictionary = {}

func _ready() -> void:
	print("The Long Walk MVP Slice 1 booted")
	_connect_ui()
	_connect_state()
	flow_ui.on_idle_ready()

func _connect_ui() -> void:
	flow_ui.start_run_pressed.connect(_on_start_run_pressed)
	flow_ui.resolve_encounter_pressed.connect(_on_resolve_encounter_pressed)
	flow_ui.extract_pressed.connect(_on_extract_pressed)
	flow_ui.die_pressed.connect(_on_die_pressed)

func _connect_state() -> void:
	GameState.run_started.connect(flow_ui.on_run_started)
	GameState.encounter_completed.connect(flow_ui.on_encounter_resolved)
	GameState.extracted.connect(flow_ui.on_extracted)
	GameState.player_died.connect(_on_player_died)

func _on_start_run_pressed() -> void:
	var seed := Time.get_unix_time_from_system()
	GameState.start_run(int(seed), "inner")
	active_encounter = ring_director.generate_encounter(int(seed), "inner", DataStore.enemies)

func _on_resolve_encounter_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if active_encounter.get("enemies", []).is_empty():
		return

	var rewards := reward_system.calculate_rewards(
		"inner",
		DataStore.rings,
		int(active_encounter.get("enemy_count", 1))
	)
	GameState.add_unbanked(int(rewards["xp"]), int(rewards["loot"]))
	active_encounter = {}

func _on_extract_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	GameState.extract()

func _on_die_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	GameState.die_in_run()

func _on_player_died() -> void:
	flow_ui.on_died(GameState.unbanked_xp, GameState.unbanked_loot)
