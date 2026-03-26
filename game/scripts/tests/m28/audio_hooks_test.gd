## M28 Test: Audio hooks — verify AudioManager.play_sfx/play_music calls exist
## at all required hook points in combat_arena.gd, main.gd, and flow_ui.gd
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ── Strategy: read source files and verify hook strings are present ───────

	# Test 1: AudioManager autoload is registered in project.godot
	var proj := FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_text := proj.get_as_text() if proj != null else ""
	if proj != null:
		proj.close()
	if proj_text.find("AudioManager") != -1:
		print("PASS: AudioManager registered in project.godot")
		passed += 1
	else:
		print("FAIL: AudioManager not found in project.godot")
		failed += 1

	# Test 2: combat_arena.gd contains hit_player hook
	var arena := _read_file("res://scenes/combat/combat_arena.gd")
	if arena.find('play_sfx("hit_player")') != -1:
		print("PASS: combat_arena has hit_player SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing hit_player SFX hook")
		failed += 1

	# Test 3: combat_arena.gd contains hit_enemy hook
	if arena.find('play_sfx("hit_enemy")') != -1:
		print("PASS: combat_arena has hit_enemy SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing hit_enemy SFX hook")
		failed += 1

	# Test 4: combat_arena.gd contains enemy_death hook
	if arena.find('play_sfx("enemy_death")') != -1:
		print("PASS: combat_arena has enemy_death SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing enemy_death SFX hook")
		failed += 1

	# Test 5: combat_arena.gd contains dodge hook
	if arena.find('play_sfx("dodge")') != -1:
		print("PASS: combat_arena has dodge SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing dodge SFX hook")
		failed += 1

	# Test 6: combat_arena.gd contains poise_break hook
	if arena.find('play_sfx("poise_break")') != -1:
		print("PASS: combat_arena has poise_break SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing poise_break SFX hook")
		failed += 1

	# Test 7: combat_arena.gd contains warden_phase hook
	if arena.find('play_sfx("warden_phase")') != -1:
		print("PASS: combat_arena has warden_phase SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing warden_phase SFX hook")
		failed += 1

	# Test 8: combat_arena.gd contains player_death hook
	if arena.find('play_sfx("player_death")') != -1:
		print("PASS: combat_arena has player_death SFX hook")
		passed += 1
	else:
		print("FAIL: combat_arena missing player_death SFX hook")
		failed += 1

	# Test 9: main.gd contains extraction hook
	var main := _read_file("res://scripts/main.gd")
	if main.find('play_sfx("extraction")') != -1:
		print("PASS: main has extraction SFX hook")
		passed += 1
	else:
		print("FAIL: main missing extraction SFX hook")
		failed += 1

	# Test 10: main.gd contains artifact_pickup hook
	if main.find('play_sfx("artifact_pickup")') != -1:
		print("PASS: main has artifact_pickup SFX hook")
		passed += 1
	else:
		print("FAIL: main missing artifact_pickup SFX hook")
		failed += 1

	# Test 11: main.gd contains ring_enter hook
	if main.find('play_sfx("ring_enter")') != -1:
		print("PASS: main has ring_enter SFX hook")
		passed += 1
	else:
		print("FAIL: main missing ring_enter SFX hook")
		failed += 1

	# Test 12: main.gd contains lore_fragment hook
	if main.find('play_sfx("lore_fragment")') != -1:
		print("PASS: main has lore_fragment SFX hook")
		passed += 1
	else:
		print("FAIL: main missing lore_fragment SFX hook")
		failed += 1

	# Test 13: main.gd contains upgrade_purchase hook
	if main.find('play_sfx("upgrade_purchase")') != -1:
		print("PASS: main has upgrade_purchase SFX hook")
		passed += 1
	else:
		print("FAIL: main missing upgrade_purchase SFX hook")
		failed += 1

	# Test 14: flow_ui.gd contains ui_confirm hook
	var flow := _read_file("res://scripts/ui/flow_ui.gd")
	if flow.find('play_sfx("ui_confirm")') != -1:
		print("PASS: flow_ui has ui_confirm SFX hook")
		passed += 1
	else:
		print("FAIL: flow_ui missing ui_confirm SFX hook")
		failed += 1

	# Test 15: flow_ui.gd contains ui_cancel hook
	if flow.find('play_sfx("ui_cancel")') != -1:
		print("PASS: flow_ui has ui_cancel SFX hook")
		passed += 1
	else:
		print("FAIL: flow_ui missing ui_cancel SFX hook")
		failed += 1

	# Test 16: flow_ui.gd contains modifier_accept hook
	if flow.find('play_sfx("modifier_accept")') != -1:
		print("PASS: flow_ui has modifier_accept SFX hook")
		passed += 1
	else:
		print("FAIL: flow_ui missing modifier_accept SFX hook")
		failed += 1

	# Test 17: flow_ui.gd contains shard_earn hook
	if flow.find('play_sfx("shard_earn")') != -1:
		print("PASS: flow_ui has shard_earn SFX hook")
		passed += 1
	else:
		print("FAIL: flow_ui missing shard_earn SFX hook")
		failed += 1

	# ── Music transition hooks ───────────────────────────────────────────────

	# Test 18: main.gd contains title music
	if main.find('play_music("title")') != -1:
		print("PASS: main has title music transition")
		passed += 1
	else:
		print("FAIL: main missing title music transition")
		failed += 1

	# Test 19: flow_ui.gd contains sanctuary music
	if flow.find('play_music("sanctuary")') != -1:
		print("PASS: flow_ui has sanctuary music transition")
		passed += 1
	else:
		print("FAIL: flow_ui missing sanctuary music transition")
		failed += 1

	# Test 20: main.gd contains combat music references
	var has_combat := main.find("combat_inner") != -1 and main.find("combat_mid") != -1 and main.find("combat_outer") != -1
	if has_combat:
		print("PASS: main has ring-specific combat music transitions")
		passed += 1
	else:
		print("FAIL: main missing ring-specific combat music")
		failed += 1

	# Test 21: main.gd contains warden music
	if main.find('play_music("warden")') != -1:
		print("PASS: main has warden music transition")
		passed += 1
	else:
		print("FAIL: main missing warden music transition")
		failed += 1

	# Test 22: main.gd contains victory music
	if main.find('play_music("victory")') != -1:
		print("PASS: main has victory music transition")
		passed += 1
	else:
		print("FAIL: main missing victory music transition")
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	print("")
	print("audio_hooks_test: %d passed, %d failed" % [passed, failed])
	quit()

func _read_file(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Could not open %s" % path)
		return ""
	var text := f.get_as_text()
	f.close()
	return text
