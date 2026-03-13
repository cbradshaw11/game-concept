extends CanvasLayer
class_name RunHistoryScreen

signal closed

@onready var run_list: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/RunList
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_populate()

func _populate() -> void:
	for child in run_list.get_children():
		child.queue_free()
	var history: Array = GameState.run_history
	if history.is_empty():
		var label := Label.new()
		label.text = "No runs yet. Start your first run!"
		run_list.add_child(label)
		return
	# Show newest first
	for i in range(history.size() - 1, -1, -1):
		var record: Dictionary = history[i]
		var label := Label.new()
		var ring_names := {"inner": "Ring 1", "mid": "Ring 2", "outer": "Ring 3"}
		var ring_display: String = ring_names.get(record.get("ring_reached", ""), record.get("ring_reached", "?"))
		var outcome: String = str(record.get("outcome", "?")).capitalize()
		var loot: int = int(record.get("loot_banked", 0))
		var xp: int = int(record.get("xp_banked", 0))
		var run_num: int = int(record.get("run_number", i + 1))
		label.text = "Run %d | %s | %s | Loot: %d | XP: %d" % [run_num, ring_display, outcome, loot, xp]
		run_list.add_child(label)

func _on_close_pressed() -> void:
	closed.emit()
