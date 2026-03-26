extends RefCounted
class_name RewardSystem

func calculate_rewards(ring_id: String, ring_data: Dictionary, enemy_count: int) -> Dictionary:
	var rings: Array = ring_data.get("rings", [])
	var xp_mult: float = 1.0
	var loot_mult: float = 1.0
	for ring in rings:
		if ring.get("id") == ring_id:
			xp_mult = float(ring.get("xp_multiplier", 1.0))
			loot_mult = float(ring.get("loot_multiplier", 1.0))
			break

	# M26 — Apply run modifier loot bonus
	var loot_bonus: float = 0.0
	if ModifierManager:
		loot_bonus = ModifierManager.get_stat_bonus("loot_pct")

	var base_xp := 20 * enemy_count
	var base_loot := 12 * enemy_count
	return {
		"xp": int(round(base_xp * xp_mult)),
		"loot": int(round(base_loot * loot_mult * (1.0 + loot_bonus)))
	}
