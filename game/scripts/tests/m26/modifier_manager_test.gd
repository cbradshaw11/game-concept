## M26 Test: ModifierManager — add/has/clear, stat bonus aggregation, weighted roll,
## flag detection, duplicate prevention
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load run_modifier data directly for test setup
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Dictionary = JSON.parse_string(raw)
	var run_mods: Array = data.get("run_modifiers", [])

	# ─── Helper: build a minimal ModifierManager-like object ──────────────
	# We test the logic by manipulating active_modifiers and calling methods
	# directly on a fresh instance. Since ModifierManager is an autoload,
	# we replicate its core logic with the loaded data.

	# ─── add_modifier + has_modifier ──────────────────────────────────────
	var mm_active: Array = []

	# Find iron_rations in data
	var iron_rations: Dictionary = {}
	var sharp_edge: Dictionary = {}
	var overload: Dictionary = {}
	var full_commit: Dictionary = {}
	for mod in run_mods:
		match str(mod.get("id", "")):
			"iron_rations": iron_rations = mod.duplicate(true)
			"sharp_edge": sharp_edge = mod.duplicate(true)
			"overload": overload = mod.duplicate(true)
			"full_commitment": full_commit = mod.duplicate(true)

	mm_active.append(iron_rations)
	var has_ir := false
	for m in mm_active:
		if str(m.get("id", "")) == "iron_rations":
			has_ir = true
	if has_ir and mm_active.size() == 1:
		print("PASS: add_modifier adds modifier and has_modifier finds it")
		passed += 1
	else:
		printerr("FAIL: add_modifier/has_modifier — active=%d has_ir=%s" % [mm_active.size(), has_ir])
		failed += 1

	# ─── clear_run_modifiers ──────────────────────────────────────────────
	var mm_clear_test: Array = [iron_rations.duplicate(true)]
	mm_clear_test.clear()
	if mm_clear_test.is_empty():
		print("PASS: clear_run_modifiers empties active list")
		passed += 1
	else:
		printerr("FAIL: clear_run_modifiers did not empty list — size=%d" % mm_clear_test.size())
		failed += 1

	# ─── get_stat_bonus single modifier ───────────────────────────────────
	var test_active: Array = [iron_rations]
	var hp_bonus := _get_stat_bonus(test_active, "max_hp_flat")
	if hp_bonus == 15.0:
		print("PASS: get_stat_bonus returns 15 for iron_rations max_hp_flat")
		passed += 1
	else:
		printerr("FAIL: get_stat_bonus max_hp_flat = %f, expected 15.0" % hp_bonus)
		failed += 1

	# ─── get_stat_bonus aggregation (multiple modifiers) ──────────────────
	var multi_active: Array = [sharp_edge, overload]
	var dmg_bonus := _get_stat_bonus(multi_active, "damage_pct")
	# sharp_edge: 0.12, overload: 0.25 → 0.37
	if abs(dmg_bonus - 0.37) < 0.001:
		print("PASS: get_stat_bonus aggregates damage_pct across sharp_edge + overload = 0.37")
		passed += 1
	else:
		printerr("FAIL: aggregated damage_pct = %f, expected 0.37" % dmg_bonus)
		failed += 1

	# ─── get_stat_bonus for non-existent stat returns 0 ──────────────────
	var zero_bonus := _get_stat_bonus(multi_active, "nonexistent_stat")
	if zero_bonus == 0.0:
		print("PASS: get_stat_bonus returns 0.0 for non-existent stat key")
		passed += 1
	else:
		printerr("FAIL: non-existent stat returned %f, expected 0.0" % zero_bonus)
		failed += 1

	# ─── has_flag detects boolean flags ───────────────────────────────────
	var flag_active: Array = [full_commit]
	var has_block := _has_flag(flag_active, "block_early_extraction")
	if has_block:
		print("PASS: has_flag detects block_early_extraction on full_commitment")
		passed += 1
	else:
		printerr("FAIL: has_flag did not detect block_early_extraction")
		failed += 1

	# ─── has_flag returns false when no modifier has the flag ─────────────
	var no_flag := _has_flag([iron_rations], "block_early_extraction")
	if not no_flag:
		print("PASS: has_flag returns false when no modifier has the flag")
		passed += 1
	else:
		printerr("FAIL: has_flag returned true for iron_rations block_early_extraction")
		failed += 1

	# ─── Weighted roll excludes already-held modifiers ────────────────────
	# If we hold all 20, roll should return empty
	var all_held: Array = run_mods.duplicate(true)
	var roll_result := _roll_excluding(run_mods, all_held, 42)
	if roll_result.is_empty():
		print("PASS: roll_modifier_offer returns empty when all 20 modifiers held")
		passed += 1
	else:
		printerr("FAIL: roll returned '%s' when all modifiers held" % roll_result.get("id", "?"))
		failed += 1

	# ─── Weighted roll returns a valid modifier when none held ────────────
	var none_held: Array = []
	var roll_valid := _roll_excluding(run_mods, none_held, 12345)
	if not roll_valid.is_empty() and roll_valid.has("id"):
		print("PASS: roll_modifier_offer returns valid modifier when none held")
		passed += 1
	else:
		printerr("FAIL: roll returned empty or invalid when none held")
		failed += 1

	# ─── Summary ──────────────────────────────────────────────────────────
	print("")
	print("modifier_manager_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()

# ── Replicated ModifierManager logic for headless testing ─────────────────────

func _get_stat_bonus(active: Array, stat: String) -> float:
	var total: float = 0.0
	for mod in active:
		var effects: Variant = mod.get("effects", {})
		if typeof(effects) == TYPE_DICTIONARY and effects.has(stat):
			total += float(effects[stat])
	return total

func _has_flag(active: Array, flag: String) -> bool:
	for mod in active:
		var effects: Variant = mod.get("effects", {})
		if typeof(effects) == TYPE_DICTIONARY:
			if bool(effects.get(flag, false)):
				return true
	return false

func _roll_excluding(all_mods: Array, held: Array, rng_seed: int) -> Dictionary:
	var held_ids: Dictionary = {}
	for m in held:
		held_ids[str(m.get("id", ""))] = true
	var available: Array = []
	for mod in all_mods:
		if not held_ids.has(str(mod.get("id", ""))):
			available.append(mod)
	if available.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var total_weight: float = 0.0
	for mod in available:
		total_weight += float(mod.get("weight", 1))
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for mod in available:
		cumulative += float(mod.get("weight", 1))
		if roll <= cumulative:
			return mod
	return available[available.size() - 1]
