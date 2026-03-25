## M19 Test: Hit feedback — verify hit stop duration range, shake magnitude
## constants, hit flash colors, and poise break flash color.
extends SceneTree

const CombatArenaScript = preload("res://scenes/combat/combat_arena.gd")

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	# ── T1: HIT_STOP_DURATION is in range 50-80ms ──────────────────────────
	var hs_dur: float = CombatArenaScript.HIT_STOP_DURATION
	if hs_dur >= 0.050 and hs_dur <= 0.080:
		print("PASS: HIT_STOP_DURATION %.3f is in [0.050, 0.080]" % hs_dur)
		checks_passed += 1
	else:
		printerr("FAIL: HIT_STOP_DURATION %.3f not in [0.050, 0.080]" % hs_dur)
		checks_failed += 1

	# ── T2: HIT_STOP_TIME_SCALE is ~0.05 ───────────────────────────────────
	var hs_ts: float = CombatArenaScript.HIT_STOP_TIME_SCALE
	if hs_ts >= 0.01 and hs_ts <= 0.10:
		print("PASS: HIT_STOP_TIME_SCALE %.2f is near 0.05" % hs_ts)
		checks_passed += 1
	else:
		printerr("FAIL: HIT_STOP_TIME_SCALE %.2f not in [0.01, 0.10]" % hs_ts)
		checks_failed += 1

	# ── T3: SHAKE_MAGNITUDE_SMALL is 4-6 ───────────────────────────────────
	var sm: float = CombatArenaScript.SHAKE_MAGNITUDE_SMALL
	if sm >= 4.0 and sm <= 6.0:
		print("PASS: SHAKE_MAGNITUDE_SMALL %.1f in [4, 6]" % sm)
		checks_passed += 1
	else:
		printerr("FAIL: SHAKE_MAGNITUDE_SMALL %.1f not in [4, 6]" % sm)
		checks_failed += 1

	# ── T4: SHAKE_MAGNITUDE_MEDIUM is ~8 ───────────────────────────────────
	var mm: float = CombatArenaScript.SHAKE_MAGNITUDE_MEDIUM
	if mm >= 7.0 and mm <= 10.0:
		print("PASS: SHAKE_MAGNITUDE_MEDIUM %.1f in [7, 10]" % mm)
		checks_passed += 1
	else:
		printerr("FAIL: SHAKE_MAGNITUDE_MEDIUM %.1f not in [7, 10]" % mm)
		checks_failed += 1

	# ── T5: SHAKE_MAGNITUDE_LARGE is 16-20 ─────────────────────────────────
	var lg: float = CombatArenaScript.SHAKE_MAGNITUDE_LARGE
	if lg >= 16.0 and lg <= 20.0:
		print("PASS: SHAKE_MAGNITUDE_LARGE %.1f in [16, 20]" % lg)
		checks_passed += 1
	else:
		printerr("FAIL: SHAKE_MAGNITUDE_LARGE %.1f not in [16, 20]" % lg)
		checks_failed += 1

	# ── T6: HIT_FLASH_COLOR red channel > 1.0 (bright flash) ──────────────
	var hfc: Color = CombatArenaScript.HIT_FLASH_COLOR
	if hfc.r > 1.0 and hfc.g < 1.0:
		print("PASS: HIT_FLASH_COLOR is bright red (r=%.1f, g=%.1f)" % [hfc.r, hfc.g])
		checks_passed += 1
	else:
		printerr("FAIL: HIT_FLASH_COLOR not bright red: %s" % str(hfc))
		checks_failed += 1

	# ── T7: POISE_BREAK_FLASH_COLOR has blue > 1.0 ────────────────────────
	var pbfc: Color = CombatArenaScript.POISE_BREAK_FLASH_COLOR
	if pbfc.b > 1.0 and pbfc.r < 1.0:
		print("PASS: POISE_BREAK_FLASH_COLOR is blue-white (b=%.1f, r=%.1f)" % [pbfc.b, pbfc.r])
		checks_passed += 1
	else:
		printerr("FAIL: POISE_BREAK_FLASH_COLOR not blue-white: %s" % str(pbfc))
		checks_failed += 1

	# ── T8: HIT_FLASH_LERP_DURATION is ~0.15s ─────────────────────────────
	var hfld: float = CombatArenaScript.HIT_FLASH_LERP_DURATION
	if hfld >= 0.10 and hfld <= 0.20:
		print("PASS: HIT_FLASH_LERP_DURATION %.2f in [0.10, 0.20]" % hfld)
		checks_passed += 1
	else:
		printerr("FAIL: HIT_FLASH_LERP_DURATION %.2f not in [0.10, 0.20]" % hfld)
		checks_failed += 1

	# ── T9: WARDEN_PHASE_FLASH_HOLD is 0.3s ───────────────────────────────
	var wpfh: float = CombatArenaScript.WARDEN_PHASE_FLASH_HOLD
	if absf(wpfh - 0.3) < 0.01:
		print("PASS: WARDEN_PHASE_FLASH_HOLD is 0.3s")
		checks_passed += 1
	else:
		printerr("FAIL: WARDEN_PHASE_FLASH_HOLD should be 0.3, got %.2f" % wpfh)
		checks_failed += 1

	# ── T10: POISE_BREAK_FLASH_DURATION is 0.2s ───────────────────────────
	var pbfd: float = CombatArenaScript.POISE_BREAK_FLASH_DURATION
	if absf(pbfd - 0.2) < 0.01:
		print("PASS: POISE_BREAK_FLASH_DURATION is 0.2s")
		checks_passed += 1
	else:
		printerr("FAIL: POISE_BREAK_FLASH_DURATION should be 0.2, got %.2f" % pbfd)
		checks_failed += 1

	# ── Summary ──────────────────────────────────────────────────────────────
	if checks_failed == 0:
		print("PASS: M19 hit feedback test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M19 hit feedback test (%d failed, %d passed)" % [
			checks_failed, checks_passed
		])
		quit(1)
