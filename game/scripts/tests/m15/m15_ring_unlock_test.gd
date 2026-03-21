## M15 Test: Ring unlock conditions via rings.json data (M15 T9)
## Tests unlock logic directly from JSON without relying on GameState autoload.
extends SceneTree

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	return JSON.parse_string(raw)

func _is_ring_unlocked(ring_id: String, rings_data: Dictionary, extractions: Dictionary) -> bool:
	"""Mirrors GameState.is_ring_unlocked() logic for test isolation."""
	for ring in rings_data.get("rings", []):
		if str(ring.get("id", "")) == ring_id:
			var condition := str(ring.get("unlock_condition", ""))
			if condition == "":
				return true
			if condition == "extracted_inner_once":
				return int(extractions.get("inner", 0)) > 0
			if condition.begins_with("extracted_") and condition.ends_with("_once"):
				var req_ring := condition.substr(10, condition.length() - 15)
				return int(extractions.get(req_ring, 0)) > 0
			return false
	return false

func _initialize() -> void:
	var checks_passed := 0
	var checks_failed := 0

	var rings_data: Variant = _load_json("res://data/rings.json")
	if rings_data == null or typeof(rings_data) != TYPE_DICTIONARY:
		printerr("FAIL: rings.json missing or invalid")
		quit(1)
		return

	var no_extractions: Dictionary = {}
	var one_inner_extraction: Dictionary = {"inner": 1}

	# Sanctuary should always be unlocked
	if _is_ring_unlocked("sanctuary", rings_data, no_extractions):
		print("PASS: sanctuary always unlocked")
		checks_passed += 1
	else:
		printerr("FAIL: sanctuary should be unlocked")
		checks_failed += 1

	# Inner ring always unlocked
	if _is_ring_unlocked("inner", rings_data, no_extractions):
		print("PASS: inner ring always unlocked")
		checks_passed += 1
	else:
		printerr("FAIL: inner ring should be unlocked by default")
		checks_failed += 1

	# Mid ring locked before any inner extraction
	if not _is_ring_unlocked("mid", rings_data, no_extractions):
		print("PASS: mid ring locked before first inner extraction")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring should be locked initially")
		checks_failed += 1

	# Mid ring unlocked after one inner extraction
	if _is_ring_unlocked("mid", rings_data, one_inner_extraction):
		print("PASS: mid ring unlocks after inner extraction")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring should unlock after 1 inner extraction")
		checks_failed += 1

	# Verify mid ring has the correct unlock_condition in data
	var rings: Array = rings_data.get("rings", [])
	var mid_ring: Dictionary = {}
	for ring in rings:
		if str(ring.get("id", "")) == "mid":
			mid_ring = ring
			break

	if str(mid_ring.get("unlock_condition", "")) == "extracted_inner_once":
		print("PASS: mid ring unlock_condition = 'extracted_inner_once'")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring unlock_condition should be 'extracted_inner_once', got '%s'" % mid_ring.get("unlock_condition", ""))
		checks_failed += 1

	# Multiple extractions still work
	var many_extractions: Dictionary = {"inner": 5}
	if _is_ring_unlocked("mid", rings_data, many_extractions):
		print("PASS: mid ring stays unlocked with multiple extractions")
		checks_passed += 1
	else:
		printerr("FAIL: mid ring should remain unlocked with multiple extractions")
		checks_failed += 1

	if checks_failed == 0:
		print("PASS: M15 ring unlock test (%d checks)" % checks_passed)
		quit(0)
	else:
		printerr("FAIL: M15 ring unlock test (%d failed)" % checks_failed)
		quit(1)
