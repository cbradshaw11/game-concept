extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()

func _ready() -> void:
	print("The Long Walk MVP Slice 1 booted")
	_run_slice_1_demo()

func _run_slice_1_demo() -> void:
	var seed := 10101
	GameState.start_run(seed, "inner")
	var encounter := ring_director.generate_encounter(seed, "inner", DataStore.enemies)
	if encounter.get("enemies", []).is_empty():
		push_error("No encounters available for ring")
		return

	var rewards := reward_system.calculate_rewards(
		"inner",
		DataStore.rings,
		int(encounter.get("enemy_count", 1))
	)
	GameState.add_unbanked(int(rewards["xp"]), int(rewards["loot"]))
	GameState.extract()
	print("Slice 1 demo completed. Banked XP: %d, Loot: %d" % [GameState.banked_xp, GameState.banked_loot])
