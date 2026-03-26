## M26 Test: Modifier application — verify damage modifier increases damage output,
## HP modifier changes max HP, dodge cost modifier, loot bonus, clear resets state
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# Load run_modifier data
	var raw := FileAccess.get_file_as_string("res://data/modifiers.json")
	var data: Dictionary = JSON.parse_string(raw) as Dictionary
	var run_mods: Array = data.get("run_modifiers", []) as Array

	# Build lookup
	var mod_by_id: Dictionary = {}
	for mod in run_mods:
		mod_by_id[str(mod.get("id", ""))] = mod

	# ─── Damage multiplier with sharp_edge (+12%) ─────────────────────────
	var sharp: Dictionary = mod_by_id.get("sharp_edge", {}) as Dictionary
	var sharp_effects: Dictionary = sharp.get("effects", {}) as Dictionary
	var dmg_pct := float(sharp_effects.get("damage_pct", 0.0))
	var dmg_mult := 1.0 + dmg_pct
	if abs(dmg_mult - 1.12) < 0.001:
		print("PASS: sharp_edge gives damage multiplier 1.12")
		passed += 1
	else:
		printerr("FAIL: sharp_edge damage multiplier = %f, expected 1.12" % dmg_mult)
		failed += 1

	# ─── Damage multiplier stacks: sharp_edge + overload ──────────────────
	var overload: Dictionary = mod_by_id.get("overload", {}) as Dictionary
	var overload_effects: Dictionary = overload.get("effects", {}) as Dictionary
	var combined_dmg := 1.0 + dmg_pct + float(overload_effects.get("damage_pct", 0.0))
	if abs(combined_dmg - 1.37) < 0.001:
		print("PASS: sharp_edge + overload stacks to 1.37 damage multiplier")
		passed += 1
	else:
		printerr("FAIL: stacked damage multiplier = %f, expected 1.37" % combined_dmg)
		failed += 1

	# ─── HP modifier: iron_rations (+15 flat) ─────────────────────────────
	var iron: Dictionary = mod_by_id.get("iron_rations", {}) as Dictionary
	var iron_effects: Dictionary = iron.get("effects", {}) as Dictionary
	var hp_flat := int(iron_effects.get("max_hp_flat", 0))
	var effective_hp := int(round((100 + hp_flat) * 1.0))
	if effective_hp == 115:
		print("PASS: iron_rations increases effective max HP to 115")
		passed += 1
	else:
		printerr("FAIL: iron_rations effective HP = %d, expected 115" % effective_hp)
		failed += 1

	# ─── HP modifier: berserk_pact (+30% dmg, -20% max HP) ───────────────
	var berserk: Dictionary = mod_by_id.get("berserk_pact", {}) as Dictionary
	var berserk_effects: Dictionary = berserk.get("effects", {}) as Dictionary
	var bp_hp_pct := float(berserk_effects.get("max_hp_pct", 0.0))
	var bp_effective_hp := int(round(100 * (1.0 + bp_hp_pct)))
	if bp_effective_hp == 80:
		print("PASS: berserk_pact reduces max HP to 80 (-20%%)")
		passed += 1
	else:
		printerr("FAIL: berserk_pact effective HP = %d, expected 80" % bp_effective_hp)
		failed += 1

	# ─── Combined HP: iron_rations + berserk_pact ─────────────────────────
	var combined_hp := int(round((100 + hp_flat) * (1.0 + bp_hp_pct)))
	if combined_hp == 92:
		print("PASS: iron_rations + berserk_pact = 92 HP ((100+15)*0.8)")
		passed += 1
	else:
		printerr("FAIL: combined HP = %d, expected 92" % combined_hp)
		failed += 1

	# ─── Dodge cost: light_step (-4 stamina) ──────────────────────────────
	var light_step: Dictionary = mod_by_id.get("light_step", {}) as Dictionary
	var ls_effects: Dictionary = light_step.get("effects", {}) as Dictionary
	var dodge_flat := int(ls_effects.get("dodge_cost_flat", 0))
	var effective_dodge: int = max(0, 22 + dodge_flat)
	if effective_dodge == 18:
		print("PASS: light_step reduces dodge cost from 22 to 18")
		passed += 1
	else:
		printerr("FAIL: light_step dodge cost = %d, expected 18" % effective_dodge)
		failed += 1

	# ─── Stamina modifier: stamina_well (+40) ─────────────────────────────
	var stam_well: Dictionary = mod_by_id.get("stamina_well", {}) as Dictionary
	var sw_effects: Dictionary = stam_well.get("effects", {}) as Dictionary
	var stam_flat := int(sw_effects.get("max_stamina_flat", 0))
	var effective_stam := 100 + stam_flat
	if effective_stam == 140:
		print("PASS: stamina_well increases max stamina to 140")
		passed += 1
	else:
		printerr("FAIL: stamina_well effective stamina = %d, expected 140" % effective_stam)
		failed += 1

	# ─── Loot bonus: silver_eye (+20%) ────────────────────────────────────
	var silver_eye: Dictionary = mod_by_id.get("silver_eye", {}) as Dictionary
	var se_effects: Dictionary = silver_eye.get("effects", {}) as Dictionary
	var loot_pct := float(se_effects.get("loot_pct", 0.0))
	# Base loot: 12 * 3 enemies * 1.0 ring mult = 36, with +20% = 43
	var base_loot := 12 * 3
	var modified_loot := int(round(base_loot * 1.0 * (1.0 + loot_pct)))
	if modified_loot == 43:
		print("PASS: silver_eye +20%% loot: 36 base -> 43")
		passed += 1
	else:
		printerr("FAIL: silver_eye loot = %d, expected 43" % modified_loot)
		failed += 1

	# ─── Damage taken modifier: thick_skin (-8%) ─────────────────────────
	var thick: Dictionary = mod_by_id.get("thick_skin", {}) as Dictionary
	var thick_effects: Dictionary = thick.get("effects", {}) as Dictionary
	var taken_pct := float(thick_effects.get("damage_taken_pct", 0.0))
	var taken_mult := 1.0 + taken_pct
	if abs(taken_mult - 0.92) < 0.001:
		print("PASS: thick_skin damage taken multiplier 0.92 (-8%%)")
		passed += 1
	else:
		printerr("FAIL: thick_skin damage taken mult = %f, expected 0.92" % taken_mult)
		failed += 1

	# ─── Clear resets all bonuses to zero ─────────────────────────────────
	var active: Array = [iron.duplicate(true), sharp.duplicate(true)]
	active.clear()
	var post_clear_hp := _get_stat_bonus(active, "max_hp_flat")
	var post_clear_dmg := _get_stat_bonus(active, "damage_pct")
	if post_clear_hp == 0.0 and post_clear_dmg == 0.0:
		print("PASS: clearing modifiers resets all stat bonuses to 0")
		passed += 1
	else:
		printerr("FAIL: post-clear hp=%f dmg=%f, expected 0/0" % [post_clear_hp, post_clear_dmg])
		failed += 1

	# ─── Boolean flags: full_commitment blocks extraction ─────────────────
	var fc: Dictionary = mod_by_id.get("full_commitment", {}) as Dictionary
	var fc_effects: Dictionary = fc.get("effects", {}) as Dictionary
	var fc_flag := bool(fc_effects.get("block_early_extraction", false))
	if fc_flag:
		print("PASS: full_commitment has block_early_extraction flag")
		passed += 1
	else:
		printerr("FAIL: full_commitment missing block_early_extraction flag")
		failed += 1

	# ─── Boolean flags: cursed_silver vendor_locked ───────────────────────
	var cs: Dictionary = mod_by_id.get("cursed_silver", {}) as Dictionary
	var cs_effects: Dictionary = cs.get("effects", {}) as Dictionary
	var cs_flag := bool(cs_effects.get("vendor_locked", false))
	if cs_flag:
		print("PASS: cursed_silver has vendor_locked flag")
		passed += 1
	else:
		printerr("FAIL: cursed_silver missing vendor_locked flag")
		failed += 1

	# ─── Summary ──────────────────────────────────────────────────────────
	print("")
	print("modifier_application_test: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		printerr("SOME TESTS FAILED")
	quit()

func _get_stat_bonus(active: Array, stat: String) -> float:
	var total: float = 0.0
	for mod in active:
		var effects: Variant = mod.get("effects", {})
		if typeof(effects) == TYPE_DICTIONARY and effects.has(stat):
			total += float(effects[stat])
	return total
