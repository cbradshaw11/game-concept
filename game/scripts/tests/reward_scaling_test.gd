extends SceneTree

const RewardSystem = preload("res://scripts/systems/reward_system.gd")

func _initialize() -> void:
	var reward_system := RewardSystem.new()
	var rings_data := _load_json("res://data/rings.json")

	var inner := reward_system.calculate_rewards("inner", rings_data, 2)
	var outer := reward_system.calculate_rewards("outer", rings_data, 2)

	if int(outer["xp"]) <= int(inner["xp"]):
		_fail("Outer ring XP should exceed inner ring XP")
		return

	if int(outer["loot"]) <= int(inner["loot"]):
		_fail("Outer ring loot should exceed inner ring loot")
		return

	print("PASS: reward scaling test")
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
