extends RefCounted
class_name VendorSystem

## Handles vendor purchase logic and stat bonus calculation.
## Reads upgrade definitions from DataStore.vendor_upgrades.
## Persists purchase state through GameState.vendor_upgrades.

func get_available_upgrades() -> Array:
	return DataStore.get_vendor_upgrades()

func can_purchase(upgrade_id: String) -> bool:
	var upg := DataStore.get_vendor_upgrade(upgrade_id)
	if upg.is_empty():
		return false
	var cost := int(upg.get("cost", 9999))
	var max_level := int(upg.get("max_level", 1))
	var current_level := GameState.get_upgrade_level(upgrade_id)
	return current_level < max_level and GameState.banked_loot >= cost

func purchase(upgrade_id: String) -> bool:
	var upg := DataStore.get_vendor_upgrade(upgrade_id)
	if upg.is_empty():
		return false
	var cost := int(upg.get("cost", 9999))
	var max_level := int(upg.get("max_level", 1))
	var current_level := GameState.get_upgrade_level(upgrade_id)
	if current_level >= max_level:
		return false
	return GameState.purchase_upgrade(upgrade_id, cost)

func get_stat_bonus(stat: String) -> float:
	"""Return total bonus for a given stat from all purchased vendor upgrades."""
	var total := 0.0
	for upg in DataStore.get_vendor_upgrades():
		if str(upg.get("stat", "")) == stat:
			var upg_id := str(upg.get("id", ""))
			var level := GameState.get_upgrade_level(upg_id)
			var bonus_per_level := float(upg.get("bonus_per_level", 0))
			total += level * bonus_per_level
	return total

func get_max_hp_bonus() -> int:
	return int(get_stat_bonus("max_hp"))

func get_max_stamina_bonus() -> int:
	return int(get_stat_bonus("max_stamina"))

func get_max_poise_bonus() -> int:
	return int(get_stat_bonus("max_poise"))

func get_attack_damage_pct_bonus() -> float:
	return get_stat_bonus("attack_damage_pct")
