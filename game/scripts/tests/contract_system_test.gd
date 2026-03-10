extends SceneTree

const ContractSystem = preload("res://scripts/systems/contract_system.gd")

func _initialize() -> void:
	var contract_system := ContractSystem.new()
	var contract := contract_system.start_contract("ring1_scout", "inner", 2)

	if str(contract.get("state", "")) != ContractSystem.STATE_ACTIVE:
		_fail("new contract should start in active state")
		return

	if contract_system.can_extract():
		_fail("extract should be blocked while contract is active")
		return

	contract = contract_system.record_encounter_completed()
	if int(contract.get("progress", 0)) != 1:
		_fail("progress should increment after encounter completion")
		return
	if str(contract.get("state", "")) != ContractSystem.STATE_ACTIVE:
		_fail("contract should remain active before target is met")
		return

	contract = contract_system.record_encounter_completed()
	if str(contract.get("state", "")) != ContractSystem.STATE_COMPLETED:
		_fail("contract should complete at target")
		return
	if not contract_system.can_extract():
		_fail("extract should unlock when contract completes")
		return

	contract_system.start_contract("ring1_hunt", "inner", 3)
	contract = contract_system.fail_active_contract()
	if str(contract.get("state", "")) != ContractSystem.STATE_FAILED:
		_fail("failed contract should transition to failed state")
		return
	if contract_system.can_extract():
		_fail("failed contract should not allow extraction")
		return

	contract_system.reset()
	if not contract_system.can_extract():
		_fail("empty contract state should allow extraction")
		return

	print("PASS: contract objective system test")
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
