extends CanvasLayer

signal modifier_selected(modifier: Dictionary)

@onready var modifier_card_0: Button = $PanelContainer/VBoxContainer/HBoxContainer/ModifierCard0
@onready var modifier_card_1: Button = $PanelContainer/VBoxContainer/HBoxContainer/ModifierCard1

var _draws: Array = []

func populate(draws: Array) -> void:
	if draws.size() < 2:
		push_error("modifier_draw: populate() requires at least 2 entries, got %d" % draws.size())
		queue_free()
		return
	_draws = draws
	modifier_card_0.text = draws[0].get("name", "?") + "\n\n" + draws[0].get("description", "")
	modifier_card_1.text = draws[1].get("name", "?") + "\n\n" + draws[1].get("description", "")
	modifier_card_0.disabled = false
	modifier_card_1.disabled = false

func _on_modifier_card_0_pressed() -> void:
	_select(0)

func _on_modifier_card_1_pressed() -> void:
	_select(1)

func _select(index: int) -> void:
	modifier_card_0.disabled = true
	modifier_card_1.disabled = true
	modifier_selected.emit(_draws[index])
	queue_free()
