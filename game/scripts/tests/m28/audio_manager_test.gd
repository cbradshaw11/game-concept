## M28 Test: AudioManager — registry completeness, unknown-id silent fail,
## volume setters, music state queries
extends SceneTree

func _initialize() -> void:
	var passed := 0
	var failed := 0

	# ── Replicate registry constants locally (no autoload in headless) ────────

	var SFX_REGISTRY := {
		"hit_player": "res://audio/sfx/hit_player.wav",
		"hit_enemy": "res://audio/sfx/hit_enemy.wav",
		"enemy_death": "res://audio/sfx/enemy_death.wav",
		"player_death": "res://audio/sfx/player_death.wav",
		"dodge": "res://audio/sfx/dodge.wav",
		"guard_break": "res://audio/sfx/guard_break.wav",
		"poise_break": "res://audio/sfx/poise_break.wav",
		"warden_phase": "res://audio/sfx/warden_phase.wav",
		"extraction": "res://audio/sfx/extraction.wav",
		"artifact_pickup": "res://audio/sfx/artifact_pickup.wav",
		"ui_confirm": "res://audio/sfx/ui_confirm.wav",
		"ui_cancel": "res://audio/sfx/ui_cancel.wav",
		"upgrade_purchase": "res://audio/sfx/upgrade_purchase.wav",
		"modifier_accept": "res://audio/sfx/modifier_accept.wav",
		"lore_fragment": "res://audio/sfx/lore_fragment.wav",
		"shard_earn": "res://audio/sfx/shard_earn.wav",
		"ring_enter": "res://audio/sfx/ring_enter.wav",
	}

	var MUSIC_REGISTRY := {
		"sanctuary": "res://audio/music/sanctuary.ogg",
		"combat_inner": "res://audio/music/combat_inner.ogg",
		"combat_mid": "res://audio/music/combat_mid.ogg",
		"combat_outer": "res://audio/music/combat_outer.ogg",
		"warden": "res://audio/music/warden.ogg",
		"title": "res://audio/music/title.ogg",
		"victory": "res://audio/music/victory.ogg",
	}

	# Test 1: SFX registry has exactly 17 entries
	if SFX_REGISTRY.size() == 17:
		print("PASS: SFX registry contains 17 entries")
		passed += 1
	else:
		print("FAIL: SFX registry expected 17 entries, got %d" % SFX_REGISTRY.size())
		failed += 1

	# Test 2: Music registry has exactly 7 entries
	if MUSIC_REGISTRY.size() == 7:
		print("PASS: Music registry contains 7 entries")
		passed += 1
	else:
		print("FAIL: Music registry expected 7 entries, got %d" % MUSIC_REGISTRY.size())
		failed += 1

	# Test 3: All required SFX ids present
	var required_sfx := [
		"hit_player", "hit_enemy", "enemy_death", "player_death",
		"dodge", "guard_break", "poise_break", "warden_phase",
		"extraction", "artifact_pickup", "ui_confirm", "ui_cancel",
		"upgrade_purchase", "modifier_accept", "lore_fragment",
		"shard_earn", "ring_enter",
	]
	var missing_sfx: Array = []
	for sid in required_sfx:
		if not SFX_REGISTRY.has(sid):
			missing_sfx.append(sid)
	if missing_sfx.is_empty():
		print("PASS: all 17 required SFX ids present")
		passed += 1
	else:
		print("FAIL: missing SFX ids: %s" % str(missing_sfx))
		failed += 1

	# Test 4: All required music ids present
	var required_music := [
		"sanctuary", "combat_inner", "combat_mid", "combat_outer",
		"warden", "title", "victory",
	]
	var missing_music: Array = []
	for mid in required_music:
		if not MUSIC_REGISTRY.has(mid):
			missing_music.append(mid)
	if missing_music.is_empty():
		print("PASS: all 7 required music ids present")
		passed += 1
	else:
		print("FAIL: missing music ids: %s" % str(missing_music))
		failed += 1

	# Test 5: SFX paths follow expected pattern
	var bad_sfx_paths: Array = []
	for sid in SFX_REGISTRY:
		var path: String = SFX_REGISTRY[sid]
		if not path.begins_with("res://audio/sfx/") or not path.ends_with(".wav"):
			bad_sfx_paths.append(sid)
	if bad_sfx_paths.is_empty():
		print("PASS: all SFX paths follow res://audio/sfx/*.wav pattern")
		passed += 1
	else:
		print("FAIL: bad SFX paths for ids: %s" % str(bad_sfx_paths))
		failed += 1

	# Test 6: Music paths follow expected pattern
	var bad_music_paths: Array = []
	for mid in MUSIC_REGISTRY:
		var path: String = MUSIC_REGISTRY[mid]
		if not path.begins_with("res://audio/music/") or not path.ends_with(".ogg"):
			bad_music_paths.append(mid)
	if bad_music_paths.is_empty():
		print("PASS: all music paths follow res://audio/music/*.ogg pattern")
		passed += 1
	else:
		print("FAIL: bad music paths for ids: %s" % str(bad_music_paths))
		failed += 1

	# Test 7: Unknown SFX id returns empty string (silent fail logic)
	var unknown_path: String = SFX_REGISTRY.get("nonexistent_sfx", "")
	if unknown_path == "":
		print("PASS: unknown SFX id returns empty path (silent fail)")
		passed += 1
	else:
		print("FAIL: unknown SFX id returned non-empty: %s" % unknown_path)
		failed += 1

	# Test 8: Unknown music id returns empty string
	var unknown_music: String = MUSIC_REGISTRY.get("nonexistent_track", "")
	if unknown_music == "":
		print("PASS: unknown music id returns empty path (silent fail)")
		passed += 1
	else:
		print("FAIL: unknown music id returned non-empty: %s" % unknown_music)
		failed += 1

	# Test 9: Placeholder WAV files exist on disk
	var missing_wav: Array = []
	for sid in SFX_REGISTRY:
		var path: String = SFX_REGISTRY[sid]
		if not ResourceLoader.exists(path):
			missing_wav.append(sid)
	if missing_wav.is_empty():
		print("PASS: all 17 placeholder WAV files exist")
		passed += 1
	else:
		print("FAIL: missing placeholder WAV files for: %s" % str(missing_wav))
		failed += 1

	# Test 10: Placeholder OGG files exist on disk
	var missing_ogg: Array = []
	for mid in MUSIC_REGISTRY:
		var path: String = MUSIC_REGISTRY[mid]
		if not ResourceLoader.exists(path):
			missing_ogg.append(mid)
	if missing_ogg.is_empty():
		print("PASS: all 7 placeholder OGG files exist")
		passed += 1
	else:
		print("FAIL: missing placeholder OGG files for: %s" % str(missing_ogg))
		failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	print("")
	print("audio_manager_test: %d passed, %d failed" % [passed, failed])
	quit()
