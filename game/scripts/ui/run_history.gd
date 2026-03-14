extends CanvasLayer
class_name RunHistoryScreen

signal closed

@onready var run_list: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/RunList
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton
@onready var stats_label: Label = $PanelContainer/VBoxContainer/StatsLabel

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_populate()

func _compute_lifetime_stats() -> Dictionary:
	var history: Array = GameState.run_history
	var ring_rank := {"sanctuary": 0, "inner": 1, "mid": 2, "outer": 3}
	var total_runs: int = history.size()
	var warden_defeats: int = 0
	var deepest_ring: String = ""
	var deepest_rank: int = -1
	var total_loot: int = 0
	var total_xp: int = 0
	var total_encounters: int = 0
	for record in history:
		if record.get("outcome", "") == "warden_defeated":
			warden_defeats += 1
		var ring: String = str(record.get("ring_reached", ""))
		var rank: int = ring_rank.get(ring, -1)
		if rank > deepest_rank:
			deepest_rank = rank
			deepest_ring = ring
		total_loot += int(record.get("loot_banked", 0))
		total_xp += int(record.get("xp_banked", 0))
		total_encounters += int(record.get("encounters_cleared", 0))
	return {
		"total_runs": total_runs,
		"warden_defeats": warden_defeats,
		"deepest_ring": deepest_ring,
		"total_loot": total_loot,
		"total_xp": total_xp,
		"total_encounters": total_encounters,
	}

func _populate_stats(stats: Dictionary) -> void:
	if stats.get("total_runs", 0) == 0:
		stats_label.text = "No runs recorded yet."
		return
	var ring_names := {"sanctuary": "Sanctuary", "inner": "Ring 1", "mid": "Ring 2", "outer": "Ring 3"}
	var deepest: String = ring_names.get(stats.get("deepest_ring", ""), str(stats.get("deepest_ring", "?")))
	stats_label.text = "Lifetime Stats  |  Runs: %d  |  Warden Defeats: %d  |  Deepest: %s  |  Total Loot: %d  |  Total XP: %d  |  Encounters: %d" % [
		stats.get("total_runs", 0),
		stats.get("warden_defeats", 0),
		deepest,
		stats.get("total_loot", 0),
		stats.get("total_xp", 0),
		stats.get("total_encounters", 0),
	]

func _populate() -> void:
	_populate_stats(_compute_lifetime_stats())
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
		var ring_names := {"sanctuary": "Sanctuary", "inner": "Ring 1", "mid": "Ring 2", "outer": "Ring 3"}
		var ring_display: String = ring_names.get(record.get("ring_reached", ""), record.get("ring_reached", "?"))
		var outcome: String = str(record.get("outcome", "?")).replace("_", " ").capitalize()
		var loot: int = int(record.get("loot_banked", 0))
		var xp: int = int(record.get("xp_banked", 0))
		var run_num: int = int(record.get("run_number", i + 1))
		var mod_names: Array = []
		var all_mods: Array = []
		if DataStore.modifiers is Dictionary:
			all_mods = DataStore.modifiers.get("modifiers", [])
		for mod_id in record.get("modifiers", []):
			var mod_id_str: String = str(mod_id)
			for m in all_mods:
				if m.get("id") == mod_id_str:
					mod_names.append(str(m.get("name", mod_id_str)))
					break
		var mod_text := "" if mod_names.is_empty() else " | Mod: " + ", ".join(mod_names)
		label.text = "Run %d | %s | %s | Loot: %d | XP: %d" % [run_num, ring_display, outcome, loot, xp] + mod_text
		run_list.add_child(label)

func _on_close_pressed() -> void:
	closed.emit()
