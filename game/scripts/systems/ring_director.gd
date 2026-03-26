extends RefCounted
class_name RingDirector

const MAX_SAME_ENEMY_TYPE := 3

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
	# M31 — escalation: add extra enemies based on encounters cleared this run
	var cm: Node = Engine.get_main_loop().root.get_node_or_null("ChallengeManager") if Engine.get_main_loop() else null
	if cm and cm.has_method("has_challenge") and cm.has_challenge("escalation"):
		var gs: Node = Engine.get_main_loop().root.get_node_or_null("GameState")
		var extra := mini(int(gs.run_encounters_cleared) if gs else 0, 4)
		count += extra
	var selected: Array = []
	var type_counts: Dictionary = {}

	var attempts := 0
	while selected.size() < count and attempts < 100:
		attempts += 1
		var candidate: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		var cid := str(candidate.get("id", ""))
		var current_count := int(type_counts.get(cid, 0))
		if current_count < MAX_SAME_ENEMY_TYPE:
			selected.append(candidate)
			type_counts[cid] = current_count + 1

	return {
		"ring": ring_id,
		"seed": seed,
		"enemy_count": selected.size(),
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

	# M25 — Weighted template selection: build cumulative weight array
	var template: Dictionary = _weighted_pick(ring_templates, rng)

	# Enforce max 2 of same type when building from template
	var type_counts: Dictionary = {}
	var selected: Array = []
	for enemy_id in template.get("enemy_ids", []):
		var key := str(enemy_id)
		if by_id.has(key):
			var current_count := int(type_counts.get(key, 0))
			if current_count < MAX_SAME_ENEMY_TYPE:
				selected.append(by_id[key])
				type_counts[key] = current_count + 1

	if selected.is_empty():
		return {}

	var result := {
		"ring": ring_id,
		"seed": seed,
		"template_id": str(template.get("id", "")),
		"template_name": str(template.get("name", "")),
		"enemy_count": selected.size(),
		"enemies": selected,
	}
	var flavor := str(template.get("flavor_text", ""))
	if flavor != "":
		result["flavor_text"] = flavor
	return result

## M25 — Pick a template using cumulative weights. Falls back to uniform if no weights.
func _weighted_pick(templates: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0
	for t in templates:
		total_weight += int(t.get("weight", 5))
	if total_weight <= 0:
		return templates[rng.randi_range(0, templates.size() - 1)]
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for t in templates:
		cumulative += int(t.get("weight", 5))
		if roll <= cumulative:
			return t
	return templates[templates.size() - 1]
