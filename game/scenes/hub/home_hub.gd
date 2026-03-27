extends CanvasLayer

signal hub_closed

@onready var shop_container: VBoxContainer = $Panel/Tabs/Shop/ScrollContainer/ShopList
@onready var bank_gold_label: Label = $Panel/Tabs/Bank/BankGoldLabel
@onready var carried_gold_label: Label = $Panel/Tabs/Bank/CarriedGoldLabel
@onready var health_label: Label = $Panel/Tabs/Status/HealthLabel
@onready var regen_label: Label = $Panel/Tabs/Status/RegenLabel

func _ready() -> void:
	_populate_shop()
	_update_bank()
	_update_status()
	InventorySystem.inventory_changed.connect(_update_bank)
	InventorySystem.bank_changed.connect(_update_bank)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hub_closed.emit()

func _populate_shop() -> void:
	var items: Array = DataStore.shop_items.get("shop_items", [])
	for item in items:
		var hbox := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s - %dg" % [item.get("name", "???"), int(item.get("cost", 0))]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(item.get("description", ""))
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(desc_label)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(_on_buy_pressed.bind(item))
		hbox.add_child(buy_btn)

		shop_container.add_child(hbox)

func _on_buy_pressed(item: Dictionary) -> void:
	var cost := int(item.get("cost", 0))
	if InventorySystem.carried_gold >= cost:
		InventorySystem.carried_gold -= cost
		InventorySystem.add_carried_item({
			"id": item.get("id", ""),
			"name": item.get("name", ""),
			"type": item.get("type", ""),
			"value": cost
		})
		InventorySystem.inventory_changed.emit()
		_update_bank()

func _on_deposit_all_pressed() -> void:
	InventorySystem.deposit_to_bank(InventorySystem.carried_gold, InventorySystem.carried_items.duplicate())

func _on_close_pressed() -> void:
	hub_closed.emit()

func _update_bank() -> void:
	if not is_inside_tree():
		return
	bank_gold_label.text = "Bank: %dg" % InventorySystem.bank_gold
	carried_gold_label.text = "Carried: %dg" % InventorySystem.carried_gold

func _update_status() -> void:
	health_label.text = "HP: Full"
	regen_label.text = "Regen: Active (Sanctuary)"
