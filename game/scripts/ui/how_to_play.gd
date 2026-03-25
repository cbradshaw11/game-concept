extends CanvasLayer

signal dismissed

func _ready() -> void:
	var overlay := PanelContainer.new()
	overlay.name = "HowToPlayOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := Label.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.text = _build_content()
	scroll.add_child(content)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		dismissed.emit()
		queue_free()
	)
	vbox.add_child(close_btn)

func _build_content() -> String:
	var lines: PackedStringArray = [
		"Move:       Arrow keys / WASD",
		"Dodge:      Shift (costs stamina, 220ms i-frames)",
		"Attack:     Space or Z",
		"Guard:      Hold X (absorbs damage, breaks at 30 damage taken while guarding)",
		"Extract:    E key or Extract button (only available after contract complete)",
		"",
		"RINGS",
		"Each ring requires completing a contract (set number of encounters) before extraction.",
		"",
		"DEATH",
		"You lose unbanked XP and loot. Banked progress is kept.",
	]
	return "\n".join(lines)
