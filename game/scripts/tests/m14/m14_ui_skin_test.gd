## M14 Test: Verify UI skin pass — dark themed panels, styled buttons
extends SceneTree

func _initialize() -> void:
	var pass_count := 0
	var fail_count := 0

	# T7-T9: FlowUI scene loads and has styled PanelContainer nodes
	var packed := load("res://scenes/ui/flow_ui.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: flow_ui.tscn failed to load")
		quit(1)
		return
	var ui := packed.instantiate()
	if ui == null:
		printerr("FAIL: flow_ui.tscn failed to instantiate")
		quit(1)
		return
	get_root().add_child(ui)

	# PrepScreen should be PanelContainer (not VBoxContainer)
	var prep := ui.get_node_or_null("PrepScreen")
	if prep != null and prep is PanelContainer:
		print("PASS: PrepScreen is PanelContainer (styled)")
		pass_count += 1
	else:
		printerr("FAIL: PrepScreen should be PanelContainer for UI skin pass")
		fail_count += 1

	# RunScreen should be PanelContainer
	var run_screen := ui.get_node_or_null("RunScreen")
	if run_screen != null and run_screen is PanelContainer:
		print("PASS: RunScreen is PanelContainer (styled)")
		pass_count += 1
	else:
		printerr("FAIL: RunScreen should be PanelContainer for UI skin pass")
		fail_count += 1

	# PrepScreen title should be present
	var title := ui.get_node_or_null("PrepScreen/PrepVBox/Title")
	if title != null and title is Label:
		print("PASS: Sanctuary title Label present")
		pass_count += 1
	else:
		printerr("FAIL: Sanctuary title Label missing at PrepScreen/PrepVBox/Title")
		fail_count += 1

	# StartRunButton should be present and styled
	var btn := ui.get_node_or_null("PrepScreen/PrepVBox/StartRunButton")
	if btn != null and btn is Button:
		print("PASS: StartRunButton present and themed")
		pass_count += 1
	else:
		printerr("FAIL: StartRunButton missing from PrepScreen/PrepVBox")
		fail_count += 1

	# Resolve/Extract/Die buttons in RunScreen
	for btn_name in ["ResolveEncounterButton", "ExtractButton", "DieButton"]:
		var rb := ui.get_node_or_null("RunScreen/RunVBox/" + btn_name)
		if rb != null and rb is Button:
			print("PASS: %s present in RunScreen" % btn_name)
			pass_count += 1
		else:
			printerr("FAIL: %s missing from RunScreen/RunVBox" % btn_name)
			fail_count += 1

	# FlowUI script methods intact
	if ui.has_method("on_run_started") and ui.has_method("on_extracted") and ui.has_method("on_died"):
		print("PASS: FlowUI lifecycle methods intact")
		pass_count += 1
	else:
		printerr("FAIL: FlowUI lifecycle methods missing")
		fail_count += 1

	if fail_count == 0:
		print("PASS: M14 UI skin test (%d checks)" % pass_count)
		quit(0)
	else:
		printerr("FAIL: M14 UI skin test (%d failed)" % fail_count)
		quit(1)
