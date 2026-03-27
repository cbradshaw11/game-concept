extends Node

signal inventory_changed
signal inventory_dropped(gold: int, items: Array, drop_position: Vector2)
signal bank_changed

var carried_gold: int = 0
var carried_items: Array = []
var bank_gold: int = 0
var bank_items: Array = []

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

func on_player_death(death_position: Vector2) -> void:
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
