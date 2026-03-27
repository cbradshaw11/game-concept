extends CanvasLayer

## Settings screen — modal overlay for audio, display, and controls reference.
## Opened from title screen or sanctuary. Dismisses on "Save & Close".

signal closed

func _ready() -> void:
	layer = 20
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		SettingsManager.save_settings()
		closed.emit()
		queue_free()

func _build_ui() -> void:
	# Semi-transparent background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer_vbox)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# ── Title ────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# ── AUDIO Section ────────────────────────────────────────────────────
	_add_section_label(vbox, "AUDIO")

	var master_slider := _add_volume_slider(vbox, "Master Volume", SettingsManager.master_volume_db)
	master_slider.value_changed.connect(func(val: float):
		SettingsManager.master_volume_db = val
		SettingsManager.apply_audio()
	)

	var sfx_slider := _add_volume_slider(vbox, "SFX Volume", SettingsManager.sfx_volume_db)
	sfx_slider.value_changed.connect(func(val: float):
		SettingsManager.sfx_volume_db = val
		SettingsManager.apply_audio()
	)

	var music_slider := _add_volume_slider(vbox, "Music Volume", SettingsManager.music_volume_db)
	music_slider.value_changed.connect(func(val: float):
		SettingsManager.music_volume_db = val
		SettingsManager.apply_audio()
	)

	vbox.add_child(HSeparator.new())

	# ── DISPLAY Section ──────────────────────────────────────────────────
	_add_section_label(vbox, "DISPLAY")

	var fs_row := HBoxContainer.new()
	var fs_label := Label.new()
	fs_label.text = "Fullscreen"
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_row.add_child(fs_label)

	var fs_check := CheckBox.new()
	fs_check.name = "FullscreenCheck"
	fs_check.button_pressed = SettingsManager.fullscreen
	fs_check.toggled.connect(func(on: bool):
		SettingsManager.fullscreen = on
		SettingsManager.apply_display()
	)
	fs_row.add_child(fs_check)
	vbox.add_child(fs_row)

	var res_note := Label.new()
	res_note.text = "Window can be resized freely"
	res_note.add_theme_font_size_override("font_size", 12)
	res_note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(res_note)

	vbox.add_child(HSeparator.new())

	# ── CONTROLS Section ─────────────────────────────────────────────────
	_add_section_label(vbox, "CONTROLS")

	var controls_grid := GridContainer.new()
	controls_grid.name = "ControlsGrid"
	controls_grid.columns = 2
	controls_grid.add_theme_constant_override("h_separation", 24)
	controls_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(controls_grid)

	# Action name → InputMap action(s) to read bindings from
	var control_actions := [
		["Move", ["ui_left", "ui_right", "ui_up", "ui_down"]],
		["Attack", ["attack"]],
		["Dodge", ["dodge"]],
		["Guard", ["guard"]],
		["Interact", ["interact"]],
		["Pause", ["ui_cancel"]],
	]

	for entry in control_actions:
		var action_label := Label.new()
		action_label.text = entry[0]
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.custom_minimum_size.x = 120
		controls_grid.add_child(action_label)

		var binding_label := Label.new()
		binding_label.name = "Binding_" + entry[0]
		binding_label.text = _get_bindings_text(entry[0], entry[1])
		binding_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		controls_grid.add_child(binding_label)

	var remap_note := Label.new()
	remap_note.text = "Bindings read from project InputMap."
	remap_note.add_theme_font_size_override("font_size", 11)
	remap_note.add_theme_color_override("font_color", Color(0.45, 0.42, 0.55, 0.8))
	vbox.add_child(remap_note)

	# ── Bottom Buttons (outside scroll, always visible) ─────────────────
	outer_vbox.add_child(HSeparator.new())

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)

	var reset_btn := Button.new()
	reset_btn.name = "ResetDefaultsButton"
	reset_btn.text = "Reset to Defaults"
	reset_btn.pressed.connect(func():
		_play_click()
		SettingsManager.reset_to_defaults()
		# Refresh UI by rebuilding
		_clear_and_rebuild()
	)
	btn_row.add_child(reset_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var save_btn := Button.new()
	save_btn.name = "SaveCloseButton"
	save_btn.text = "Save & Close"
	save_btn.pressed.connect(func():
		_play_click()
		SettingsManager.save_settings()
		closed.emit()
		queue_free()
	)
	btn_row.add_child(save_btn)

	outer_vbox.add_child(btn_row)

# ── Helpers ──────────────────────────────────────────────────────────────────

func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	parent.add_child(lbl)

func _add_volume_slider(parent: VBoxContainer, label_text: String, current_value: float) -> HSlider:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.custom_minimum_size.x = 140
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = -40.0
	slider.max_value = 0.0
	slider.step = 1.0
	slider.value = current_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 200
	row.add_child(slider)

	var db_label := Label.new()
	db_label.text = "%d dB" % int(current_value)
	db_label.custom_minimum_size.x = 60
	db_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(db_label)

	slider.value_changed.connect(func(val: float):
		db_label.text = "%d dB" % int(val)
	)

	parent.add_child(row)
	return slider

func _get_bindings_text(display_name: String, actions: Array) -> String:
	## Read key bindings from InputMap at runtime for the given action(s).
	if display_name == "Move":
		# Combine directional actions into a compact display
		var keys: Array = []
		for action_name in actions:
			if not InputMap.has_action(action_name):
				continue
			for event in InputMap.action_get_events(action_name):
				if event is InputEventKey:
					var label := OS.get_keycode_string(event.physical_keycode) if event.physical_keycode != 0 else OS.get_keycode_string(event.keycode)
					if label != "" and not keys.has(label):
						keys.append(label)
		return ", ".join(keys) if not keys.is_empty() else "Not bound"

	# Single-action entries: list all key events
	var keys: Array = []
	for action_name in actions:
		if not InputMap.has_action(action_name):
			continue
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey:
				var label := OS.get_keycode_string(event.physical_keycode) if event.physical_keycode != 0 else OS.get_keycode_string(event.keycode)
				if label != "" and not keys.has(label):
					keys.append(label)
	return " / ".join(keys) if not keys.is_empty() else "Not bound"

func _clear_and_rebuild() -> void:
	for child in get_children():
		child.queue_free()
	# Defer rebuild to next frame after children are freed
	call_deferred("_build_ui")

func _play_click() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
