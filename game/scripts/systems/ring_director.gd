extends RefCounted
class_name RingDirector

# Deterministic ring encounter selection based on seed and ring index.
func generate_encounter(
	seed: int,
	ring_id: String,
	enemies_data: Dictionary,
	templates_data: Dictionary = {}
) -> Dictionary:
	var template_encounter := _generate_template_encounter(seed, ring_id, enemies_data, templates_data)
	if not template_encounter.is_empty():
		return template_encounter

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

func _generate_template_encounter(
	seed: int,
	ring_id: String,
	enemies_data: Dictionary,
	templates_data: Dictionary
) -> Dictionary:
	var templates: Array = templates_data.get("templates", [])
	if templates.is_empty():
		return {}

	var ring_templates: Array = []
	for template in templates:
		if str(template.get("ring", "")) == ring_id:
			ring_templates.append(template)
	if ring_templates.is_empty():
		return {}

	var by_id: Dictionary = {}
	for enemy in enemies_data.get("enemies", []):
		by_id[str(enemy.get("id", ""))] = enemy

	var rng := RandomNumberGenerator.new()
	rng.seed = _combine_seed(seed, ring_id)
	var template := ring_templates[rng.randi_range(0, ring_templates.size() - 1)]

	var selected: Array = []
	for enemy_id in template.get("enemy_ids", []):
		var key := str(enemy_id)
		if by_id.has(key):
			selected.append(by_id[key])

	if selected.is_empty():
		return {}

	return {
		"ring": ring_id,
		"seed": seed,
		"template_id": str(template.get("id", "")),
		"enemy_count": selected.size(),
		"enemies": selected,
	}
