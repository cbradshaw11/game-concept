extends SceneTree

## M36 — Player Attack Feedback Tests
## Verifies: player attack flash timer var, swing/heavy_swing SFX entries

func _init() -> void:
	var pass_count := 0
	var fail_count := 0

	# ── Test 1: _player_attack_flash_timer exists on CombatArena ─────────────
	var arena_script: GDScript = load("res://scenes/combat/combat_arena.gd")
	if arena_script == null:
		print("FAIL: could not load combat_arena.gd")
		fail_count += 1
	else:
		var props := arena_script.get_script_property_list()
		var found_timer := false
		for prop in props:
			if prop["name"] == "_player_attack_flash_timer":
				found_timer = true
				break
		if found_timer:
			print("PASS: _player_attack_flash_timer exists on CombatArena")
			pass_count += 1
		else:
			print("FAIL: _player_attack_flash_timer not found on CombatArena")
			fail_count += 1

	# ── Test 2: PLAYER_ATTACK_FLASH_COLOR constant exists ────────────────────
	var has_color := "PLAYER_ATTACK_FLASH_COLOR" in arena_script
	if has_color:
		print("PASS: PLAYER_ATTACK_FLASH_COLOR constant exists")
		pass_count += 1
	else:
		print("FAIL: PLAYER_ATTACK_FLASH_COLOR constant not found")
		fail_count += 1

	# ── Test 3: AudioManager has "swing" SFX entry ──────────────────────────
	var am_script: GDScript = load("res://autoload/audio_manager.gd")
	if am_script == null:
		print("FAIL: could not load audio_manager.gd")
		fail_count += 1
	else:
		var sfx_reg: Dictionary = am_script.SFX_REGISTRY
		if sfx_reg.has("swing"):
			print("PASS: AudioManager SFX_REGISTRY has 'swing'")
			pass_count += 1
		else:
			print("FAIL: AudioManager SFX_REGISTRY missing 'swing'")
			fail_count += 1

		# ── Test 4: AudioManager has "heavy_swing" SFX entry ─────────────────
		if sfx_reg.has("heavy_swing"):
			print("PASS: AudioManager SFX_REGISTRY has 'heavy_swing'")
			pass_count += 1
		else:
			print("FAIL: AudioManager SFX_REGISTRY missing 'heavy_swing'")
			fail_count += 1

	# ── Test 5: Flash constants have sensible values ─────────────────────────
	var hold_val: float = arena_script.get("PLAYER_ATTACK_FLASH_HOLD")
	var lerp_val: float = arena_script.get("PLAYER_ATTACK_FLASH_LERP")
	if hold_val != null and lerp_val != null and hold_val > 0.0 and lerp_val > 0.0:
		print("PASS: flash hold=%.3f lerp=%.3f both positive" % [hold_val, lerp_val])
		pass_count += 1
	else:
		print("FAIL: flash constants missing or non-positive (hold=%s, lerp=%s)" % [str(hold_val), str(lerp_val)])
		fail_count += 1

	print("")
	print("M36 attack feedback: %d passed, %d failed" % [pass_count, fail_count])
	if fail_count > 0:
		quit(1)
	else:
		quit(0)
