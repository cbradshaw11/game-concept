extends SceneTree

const RewardSystem = preload("res://scripts/systems/reward_system.gd")

func _initialize() -> void:
	var reward_system := RewardSystem.new()
	var rings_data := _load_json("res://data/rings.json")

	# Reset state baseline.
	GameState.banked_xp = 0
	GameState.banked_loot = 0
	GameState.unbanked_xp = 0
	GameState.unbanked_loot = 0

	GameState.start_run(1234, "inner")
	var rewards := reward_system.calculate_rewards("inner", rings_data, 2)
	GameState.add_unbanked(int(rewards["xp"]), int(rewards["loot"]))
	GameState.extract()

	if GameState.banked_xp <= 0 or GameState.banked_loot <= 0:
		_fail("Extract should bank positive rewards")
		return

	var banked_xp_after_extract := GameState.banked_xp
	var banked_loot_after_extract := GameState.banked_loot

	GameState.start_run(5678, "inner")
	GameState.add_unbanked(100, 50)
	GameState.die_in_run()

	if GameState.unbanked_xp != 50:
		_fail("Death should preserve exactly 50 percent unbanked XP")
		return

	if GameState.unbanked_loot != 0:
		_fail("Death should clear unbanked loot")
		return

	if GameState.banked_xp != banked_xp_after_extract or GameState.banked_loot != banked_loot_after_extract:
		_fail("Death in run should not alter banked totals")
		return

	print("PASS: progression integrity test")
	quit(0)

func _load_json(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
