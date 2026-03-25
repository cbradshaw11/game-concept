extends SceneTree
## M20 T5 — How to Play screen tests
## Validates:
## - how_to_play.tscn scene file exists
## - how_to_play.gd script exists and has expected content
## - flow_ui.gd has How to Play button setup and show method
## - how_to_play.gd contains all expected control instructions

func _init() -> void:
	var passed := 0
	var failed := 0

	# ── Scene file exists ────────────────────────────────────────────────────
	if FileAccess.file_exists("res://scenes/ui/how_to_play.tscn"):
		print("PASS: how_to_play.tscn exists")
		passed += 1
	else:
		printerr("FAIL: how_to_play.tscn not found")
		failed += 1

	# ── Script file exists ───────────────────────────────────────────────────
	var htp_src := FileAccess.get_file_as_string("res://scripts/ui/how_to_play.gd")
	if htp_src.length() > 0:
		print("PASS: how_to_play.gd exists and is not empty")
		passed += 1
	else:
		printerr("FAIL: how_to_play.gd is missing or empty")
		failed += 1

	# ── Has dismissed signal ─────────────────────────────────────────────────
	if "dismissed" in htp_src:
		print("PASS: how_to_play.gd has dismissed signal")
		passed += 1
	else:
		printerr("FAIL: how_to_play.gd should have dismissed signal")
		failed += 1

	# ── Contains expected control instructions ───────────────────────────────
	var expected_controls := ["Move:", "Dodge:", "Attack:", "Guard:", "Extract:"]
	var all_found := true
	for ctrl in expected_controls:
		if ctrl not in htp_src:
			all_found = false
			printerr("FAIL: how_to_play.gd missing control instruction '%s'" % ctrl)
			failed += 1
	if all_found:
		print("PASS: how_to_play.gd contains all 5 control instructions")
		passed += 1

	# ── Contains gameplay rules ──────────────────────────────────────────────
	if "contract" in htp_src and "unbanked" in htp_src.to_lower():
		print("PASS: how_to_play.gd explains rings/contracts and death penalty")
		passed += 1
	else:
		printerr("FAIL: how_to_play.gd should explain ring contracts and death penalty")
		failed += 1

	# ── Close/dismiss button exists ──────────────────────────────────────────
	if "Close" in htp_src and "queue_free" in htp_src:
		print("PASS: how_to_play.gd has close button that dismisses overlay")
		passed += 1
	else:
		printerr("FAIL: how_to_play.gd should have a close button")
		failed += 1

	# ── flow_ui.gd has How to Play button ────────────────────────────────────
	var flow_src := FileAccess.get_file_as_string("res://scripts/ui/flow_ui.gd")
	if "HowToPlayButton" in flow_src and "_setup_how_to_play_button" in flow_src:
		print("PASS: flow_ui.gd sets up How to Play button in sanctuary")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd should setup HowToPlayButton")
		failed += 1

	if "_show_how_to_play" in flow_src:
		print("PASS: flow_ui.gd has _show_how_to_play method")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd should have _show_how_to_play method")
		failed += 1

	# ── flow_ui.gd has return toast ──────────────────────────────────────────
	if "_show_return_toast" in flow_src and "ReturnToast" in flow_src:
		print("PASS: flow_ui.gd has sanctuary return toast")
		passed += 1
	else:
		printerr("FAIL: flow_ui.gd should have _show_return_toast for sanctuary greeting")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if failed == 0:
		print("PASS: M20 how to play test (%d checks)" % passed)
	else:
		printerr("FAIL: M20 how to play test (%d failed, %d passed)" % [failed, passed])
	quit()
