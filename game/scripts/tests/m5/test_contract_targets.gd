extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	var f = FileAccess.open("res://data/rings.json", FileAccess.READ)
	if f == null:
		failures.append("Could not open res://data/rings.json")
		print("FAIL: " + failures[0])
		quit(1)
		return

	var rings_data = JSON.parse_string(f.get_as_text()).get("rings", [])

	var targets := {}
	for r in rings_data:
		targets[r.get("id")] = r.get("contract_target", null)

	# Test 1: inner has contract_target == 3
	if targets.get("inner") != 3:
		failures.append("inner contract_target expected 3, got %s" % str(targets.get("inner")))

	# Test 2: mid has contract_target == 4
	if targets.get("mid") != 4:
		failures.append("mid contract_target expected 4, got %s" % str(targets.get("mid")))

	# Test 3: outer has contract_target == 4
	if targets.get("outer") != 4:
		failures.append("outer contract_target expected 4, got %s" % str(targets.get("outer")))

	# Test 4: sanctuary does NOT have contract_target
	if targets.get("sanctuary") != null:
		failures.append("sanctuary should not have contract_target, got %s" % str(targets.get("sanctuary")))

	if failures.is_empty():
		print("PASS: test_contract_targets")
		quit(0)
	else:
		for msg in failures:
			print("FAIL: " + msg)
		quit(1)
