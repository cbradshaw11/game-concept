extends Node

signal inventory_changed
signal inventory_dropped(gold: int, items: Array, drop_position: Vector2)
signal bank_changed

var carried_gold: int = 0
var carried_items: Array = []
var bank_gold: int = 0
var bank_items: Array = []

# Equipment slots — what the player currently has equipped
var equipped: Dictionary = {
	"weapon_melee": {},
	"weapon_ranged": {},
	"weapon_magic": {},
	"helmet": {},
	"breastplate": {},
	"pants": {},
	"shoes": {},
	"gauntlets": {},
}

# Computed stats from equipment
var total_defense: int = 0
var melee_damage_bonus: int = 0
var ranged_damage_bonus: int = 0
var magic_damage_bonus: int = 0
var speed_bonus: float = 0.0

func add_carried_gold(amount: int) -> void:
	carried_gold += amount
	inventory_changed.emit()

func add_carried_item(item: Dictionary) -> void:
	carried_items.append(item)
	inventory_changed.emit()

func deposit_to_bank(gold: int, items: Array) -> void:
	var gold_to_deposit := mini(gold, carried_gold)
	carried_gold -= gold_to_deposit
	bank_gold += gold_to_deposit
	for item in items:
		var idx := carried_items.find(item)
		if idx >= 0:
			carried_items.remove_at(idx)
			bank_items.append(item)
	inventory_changed.emit()
	bank_changed.emit()

func withdraw_gold(amount: int) -> void:
	var gold_to_withdraw := mini(amount, bank_gold)
	bank_gold -= gold_to_withdraw
	carried_gold += gold_to_withdraw
	inventory_changed.emit()
	bank_changed.emit()

func withdraw_item(item: Dictionary) -> void:
	var idx := bank_items.find(item)
	if idx >= 0:
		bank_items.remove_at(idx)
		carried_items.append(item)
		inventory_changed.emit()
		bank_changed.emit()

func equip_item(item: Dictionary) -> void:
	var slot: String = item.get("slot", "")
	if slot == "" or not equipped.has(slot):
		return
	var current = equipped[slot]
	# If something is already equipped, move it back to bank_items
	if not current.is_empty():
		bank_items.append(current)
		bank_changed.emit()
	# Remove item from bank_items and equip it
	var idx := bank_items.find(item)
	if idx >= 0:
		bank_items.remove_at(idx)
	equipped[slot] = item
	_recalculate_stats()
	inventory_changed.emit()

func unequip_item(slot: String) -> void:
	var current = equipped.get(slot, {})
	if current.is_empty():
		return
	bank_items.append(current)
	equipped[slot] = {}
	_recalculate_stats()
	bank_changed.emit()
	inventory_changed.emit()

func _recalculate_stats() -> void:
	total_defense = 0
	melee_damage_bonus = 0
	ranged_damage_bonus = 0
	magic_damage_bonus = 0
	speed_bonus = 0.0
	for slot_name in equipped:
		var item: Dictionary = equipped[slot_name]
		if item.is_empty():
			continue
		total_defense += int(item.get("defense", 0))
		speed_bonus += float(item.get("speed_bonus", 0))
		var dmg: int = int(item.get("damage_bonus", 0))
		var category: String = item.get("category", "")
		var s: String = item.get("slot", "")
		if s == "weapon_melee":
			melee_damage_bonus += dmg
		elif s == "weapon_ranged":
			ranged_damage_bonus += dmg
		elif s == "weapon_magic":
			magic_damage_bonus += dmg
		elif category == "armor":
			# gauntlets can have damage_bonus too
			melee_damage_bonus += dmg

func on_player_death(death_position: Vector2) -> void:
	# Equipped items are NOT dropped — only carried_items and carried_gold
	var dropped_gold := carried_gold
	var dropped_items := carried_items.duplicate()
	carried_gold = 0
	carried_items.clear()
	inventory_changed.emit()
	inventory_dropped.emit(dropped_gold, dropped_items, death_position)

func on_player_respawn() -> void:
	carried_gold = 0
	carried_items.clear()
	inventory_changed.emit()
