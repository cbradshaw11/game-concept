extends PanelContainer
class_name RunSummary

## M21 — Run summary screen shown after death, extraction, or artifact retrieval.
## Built programmatically (no .tscn needed) and populated via populate().

signal return_to_sanctuary
signal return_to_title

var _outcome: String = ""  # "death" | "extraction" | "artifact"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 10

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "SummaryVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header
	var header := Label.new()
	header.name = "Header"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	vbox.add_child(HSeparator.new())

	# Stats block
	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_label)

	vbox.add_child(HSeparator.new())

	# All-time stats
	var alltime_label := Label.new()
	alltime_label.name = "AlltimeLabel"
	alltime_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alltime_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(alltime_label)

	# Personal best badges
	var badges_label := Label.new()
	badges_label.name = "BadgesLabel"
	badges_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	badges_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badges_label.visible = false
	vbox.add_child(badges_label)

	# M23 — Lore fragment counter
	var frag_label := Label.new()
	frag_label.name = "FragmentLabel"
	frag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frag_label.visible = false
	frag_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))
	vbox.add_child(frag_label)

	vbox.add_child(HSeparator.new())

	# Flavor text
	var flavor_label := Label.new()
	flavor_label.name = "FlavorLabel"
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(flavor_label)

	# Buttons
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)

	var run_again_btn := Button.new()
	run_again_btn.name = "RunAgainBtn"
	run_again_btn.text = "Run Again"
	run_again_btn.pressed.connect(func():
		if AudioManager:
			AudioManager.play_sfx("ui_confirm")
		return_to_sanctuary.emit()
	)
	btn_box.add_child(run_again_btn)

	var title_btn := Button.new()
	title_btn.name = "TitleBtn"
	title_btn.text = "Title"
	title_btn.pressed.connect(func():
		if AudioManager:
			AudioManager.play_sfx("ui_confirm")
		return_to_title.emit()
	)
	btn_box.add_child(title_btn)

func populate(outcome: String) -> void:
	_outcome = outcome
	var vbox := find_child("SummaryVBox", true, false)
	if vbox == null:
		return

	# Header
	var header := find_child("Header", true, false) as Label
	if header:
		match outcome:
			"artifact":
				header.text = "ARTIFACT RETRIEVED"
			"extraction":
				header.text = "EXTRACTED"
			_:
				header.text = "RUN COMPLETE"
		# M27 — Legacy title cosmetic
		if GameState.has_permanent_unlock("itinerant_legacy"):
			header.text += "\n[Legacy]"

	# Stats
	var stats_label := find_child("StatsLabel", true, false) as Label
	if stats_label:
		var rs: Dictionary = GameState.current_run_stats
		var lines: PackedStringArray = []
		var ring_reached := str(rs.get("extraction_ring", ""))
		if ring_reached == "death":
			# Use the ring from run history
			if not GameState.run_history.is_empty():
				ring_reached = str(GameState.run_history[-1].get("ring", "inner"))
			else:
				ring_reached = "inner"
		lines.append("Ring reached:      %s" % ring_reached.to_upper())
		lines.append("Enemies killed:    %d" % int(rs.get("enemies_killed", 0)))
		lines.append("Damage dealt:      %d" % int(rs.get("damage_dealt", 0)))
		lines.append("Damage taken:      %d" % int(rs.get("damage_taken", 0)))
		lines.append("Silver earned:     %d" % int(rs.get("silver_earned", 0)))
		var duration := float(rs.get("run_duration_seconds", 0.0))
		var minutes := int(duration) / 60
		var seconds := int(duration) % 60
		lines.append("Run duration:      %dm %02ds" % [minutes, seconds])
		lines.append("XP banked:         %d" % GameState.run_total_xp)
		# M27 — Show resonance shards earned this run
		if GameState.last_run_shards_earned > 0:
			lines.append("Shards earned:     +%d" % GameState.last_run_shards_earned)
		stats_label.text = "\n".join(lines)

	# All-time stats
	var alltime_label := find_child("AlltimeLabel", true, false) as Label
	if alltime_label:
		var lines: PackedStringArray = []
		lines.append("ALL-TIME STATS")
		lines.append("Total runs:        %d" % GameState.total_runs)
		lines.append("Extractions:       %d" % GameState.total_extractions)
		lines.append("Deaths:            %d" % GameState.total_deaths)
		var deepest := GameState.deepest_ring_reached
		lines.append("Deepest ring:      %s" % (deepest.to_upper() if deepest != "" else "---"))
		lines.append("Artifacts:         %d" % GameState.artifact_retrievals)
		alltime_label.text = "\n".join(lines)

	# Personal best badges (T4)
	var badges_label := find_child("BadgesLabel", true, false) as Label
	if badges_label:
		var bests := GameState.get_personal_bests(outcome)
		if not bests.is_empty():
			badges_label.text = "\n".join(PackedStringArray(bests))
			badges_label.visible = true
		else:
			badges_label.visible = false

	# M23 — Lore fragment counter
	var frag_label := find_child("FragmentLabel", true, false) as Label
	if frag_label:
		var total := GameState.collected_fragments.size()
		var lines_frag: PackedStringArray = []
		lines_frag.append("Notes Recovered:   %d / 5" % total)
		# "First Note!" badge if this run collected fragment 1
		if GameState.current_run_fragments.has("fragment_001"):
			lines_frag.append("First Note!")
		frag_label.text = "\n".join(lines_frag)
		frag_label.visible = total > 0

	# Flavor text
	var flavor_label := find_child("FlavorLabel", true, false) as Label
	if flavor_label:
		var ring_id := str(GameState.current_run_stats.get("extraction_ring", "inner"))
		if ring_id == "death":
			if not GameState.run_history.is_empty():
				ring_id = str(GameState.run_history[-1].get("ring", "inner"))
			else:
				ring_id = "inner"
		var flavor := ""
		match outcome:
			"death":
				flavor = NarrativeManager.get_ring_text(ring_id, "death")
			"artifact":
				flavor = NarrativeManager.get_artifact_text()
			_:
				flavor = NarrativeManager.get_ring_text(ring_id, "extraction")
		if flavor != "":
			flavor_label.text = flavor
		else:
			flavor_label.visible = false

static func format_duration(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%dm %02ds" % [m, s]
