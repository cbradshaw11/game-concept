extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var rings_data: Array = DataStore.rings.get("rings", [])
	var combat_ring_ids: Array = ["inner", "mid", "outer"]

	for ring_id in combat_ring_ids:
		var found: bool = false
		for r in rings_data:
			if r.get("id", "") == ring_id:
				found = true
				var briefing: String = r.get("briefing", "")
				if briefing.is_empty():
					failures.append("Ring '%s': briefing is missing or empty" % ring_id)
				var flavor: String = r.get("extraction_flavor", "")
				if flavor.is_empty():
					failures.append("Ring '%s': extraction_flavor is missing or empty" % ring_id)
				break
		if not found:
			failures.append("Ring '%s': not found in rings.json" % ring_id)

	if failures.is_empty():
		print("PASS: test_ring_narrative")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
