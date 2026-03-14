extends PanelContainer
class_name Vendor

signal closed

@onready var loot_label: Label = $VBoxContainer/LootLabel
@onready var item_list: VBoxContainer = $VBoxContainer/ItemList
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

var _all_items: Array = []
var _offered_items: Array = []
var _purchasing: bool = false
var _feedback_timer: SceneTreeTimer = null
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_load_and_populate()

func _load_and_populate() -> void:
	var f := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if not f:
		push_error("shop_items.json not found")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_all_items = parsed.get("items", [])
	if _all_items.is_empty():
		push_error("shop_items.json parsed but contains no items")
		return

	# Pick 3-4 random items to offer, seeded by run state for consistency
	# Exclude weapon_unlock and permanent_xp items from the random loot pool
	_rng.seed = GameState.active_seed + GameState.rings_cleared.size() * 1000
	var pool: Array = _all_items.filter(func(i):
		var t: String = i.get("type", "")
		return t != "weapon_unlock" and t != "permanent_xp"
	)
	for i in range(pool.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var offer_count: int = _rng.randi_range(3, 4)
	_offered_items = pool.slice(0, min(offer_count, pool.size()))

	_refresh_loot_label()
	_populate_item_list()

func _refresh_loot_label() -> void:
	loot_label.text = "Your Loot: %d  |  Banked XP: %d" % [GameState.banked_loot, GameState.banked_xp]

func _populate_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	for item in _offered_items:
		var card := HBoxContainer.new()

		var name_label := Label.new()
		name_label.text = str(item.get("name", ""))
		name_label.custom_minimum_size = Vector2(150, 0)
		card.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(item.get("description", ""))
		desc_label.custom_minimum_size = Vector2(280, 0)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc_label)

		var cost_label := Label.new()
		cost_label.text = "%d loot" % int(item.get("cost", 0))
		cost_label.custom_minimum_size = Vector2(70, 0)
		card.add_child(cost_label)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(_on_buy_pressed.bind(str(item.get("id", ""))))
		if item.get("type") == "permanent":
			var already_owned := GameState.permanent_upgrades.any(func(u): return u.get("id", "") == item.get("id", "NONE"))
			if already_owned:
				buy_btn.text = "Owned"
				buy_btn.disabled = true
		card.add_child(buy_btn)

		item_list.add_child(card)

	# Prestige section: show permanent_xp items not yet purchased
	var prestige_items: Array = _all_items.filter(func(i): return i.get("type", "") == "permanent_xp")
	var unpurchased_prestige: Array = prestige_items.filter(func(i): return not GameState.has_purchased(str(i.get("id", ""))))
	if not unpurchased_prestige.is_empty():
		var separator := HSeparator.new()
		item_list.add_child(separator)

		var section_label := Label.new()
		section_label.text = "-- Prestige (XP) --"
		item_list.add_child(section_label)

		for item in unpurchased_prestige:
			var card := HBoxContainer.new()

			var name_label := Label.new()
			name_label.text = str(item.get("name", ""))
			name_label.custom_minimum_size = Vector2(150, 0)
			card.add_child(name_label)

			var desc_label := Label.new()
			desc_label.text = str(item.get("description", ""))
			desc_label.custom_minimum_size = Vector2(280, 0)
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(desc_label)

			var cost_xp: int = int(item.get("cost_xp", 0))
			var cost_label := Label.new()
			cost_label.text = "XP: %d" % cost_xp
			cost_label.custom_minimum_size = Vector2(70, 0)
			card.add_child(cost_label)

			var buy_btn := Button.new()
			buy_btn.text = "Buy"
			buy_btn.disabled = GameState.banked_xp < cost_xp
			buy_btn.pressed.connect(_on_buy_prestige_pressed.bind(str(item.get("id", ""))))
			card.add_child(buy_btn)

			item_list.add_child(card)

func _on_buy_pressed(item_id: String) -> void:
	if _purchasing:
		return
	_purchasing = true

	var item: Dictionary = {}
	for i in _offered_items:
		if i.get("id", "") == item_id:
			item = i
			break
	if item.is_empty():
		_purchasing = false
		return

	# Disable all Buy buttons while processing to prevent double-clicks
	for card in item_list.get_children():
		for child in card.get_children():
			if child is Button and child.text == "Buy":
				child.disabled = true

	var cost: int = int(item.get("cost", 0))
	if GameState.banked_loot < cost:
		# Re-enable buttons on failure
		for card in item_list.get_children():
			for child in card.get_children():
				if child is Button and child.text == "Buy":
					child.disabled = false
		_purchasing = false
		_show_feedback("Not enough loot!")
		return

	GameState.banked_loot -= cost
	GameState.apply_shop_item(item)
	_purchasing = false
	SaveSystem.save_state(GameState.to_save_state())
	_refresh_loot_label()
	_populate_item_list()
	_show_feedback("Purchased: %s" % str(item.get("name", "")))

func _on_buy_prestige_pressed(item_id: String) -> void:
	if GameState.has_purchased(item_id):
		return
	if _purchasing:
		return
	_purchasing = true

	var item: Dictionary = {}
	for i in _all_items:
		if i.get("id", "") == item_id and i.get("type", "") == "permanent_xp":
			item = i
			break
	if item.is_empty():
		_purchasing = false
		return

	var cost_xp: int = int(item.get("cost_xp", 0))
	if GameState.banked_xp < cost_xp:
		_purchasing = false
		_show_feedback("Not enough XP!")
		return

	GameState.banked_xp -= cost_xp
	GameState.permanent_purchases.append(str(item_id))
	GameState.telemetry.log_event("shop_item_purchased", {
		"item_id": item_id,
		"type": "permanent_xp",
		"effect": item.get("effect", ""),
	})
	_purchasing = false
	SaveSystem.save_state(GameState.to_save_state())
	_refresh_loot_label()
	_populate_item_list()
	_show_feedback("Purchased: %s" % str(item.get("name", "")))

func _show_feedback(message: String) -> void:
	feedback_label.text = message
	feedback_label.visible = true
	# Cancel any existing feedback timer to prevent stacking hide callbacks
	_feedback_timer = get_tree().create_timer(2.0)
	var captured_timer := _feedback_timer
	captured_timer.timeout.connect(func():
		if captured_timer == _feedback_timer:
			feedback_label.visible = false
	)

func _on_close_pressed() -> void:
	closed.emit()
