extends RefCounted
class_name RingDirector

# Deterministic ring encounter selection based on seed and ring index.
func generate_encounter(seed: int, ring_id: String, enemies_data: Dictionary) -> Dictionary:
	var candidates: Array = []
	for enemy in enemies_data.get("enemies", []):
		if ring_id in enemy.get("rings", []):
			candidates.append(enemy)
	if candidates.is_empty():
		return {"ring": ring_id, "enemies": []}

	var rng := RandomNumberGenerator.new()
	rng.seed = _combine_seed(seed, ring_id)
	var count := clampi(rng.randi_range(1, 3), 1, candidates.size())
	var selected: Array = []
	for i in range(count):
		selected.append(candidates[rng.randi_range(0, candidates.size() - 1)])

	return {
		"ring": ring_id,
		"seed": seed,
		"enemy_count": count,
		"enemies": selected,
	}

func _combine_seed(seed: int, ring_id: String) -> int:
	return int(seed + ring_id.hash())
