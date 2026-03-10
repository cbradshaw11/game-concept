extends RefCounted
class_name ContractSystem

const STATE_IDLE := "idle"
const STATE_ACTIVE := "active"
const STATE_COMPLETED := "completed"
const STATE_FAILED := "failed"

var active_contract: Dictionary = {}

func start_contract(contract_id: String, ring_id: String, target_encounters: int) -> Dictionary:
	active_contract = {
		"id": contract_id,
		"ring": ring_id,
		"target": max(1, target_encounters),
		"progress": 0,
		"state": STATE_ACTIVE,
	}
	return active_contract.duplicate(true)

func has_active_contract() -> bool:
	return str(active_contract.get("state", STATE_IDLE)) == STATE_ACTIVE

func record_encounter_completed() -> Dictionary:
	if not has_active_contract():
		return active_contract.duplicate(true)

	active_contract["progress"] = int(active_contract.get("progress", 0)) + 1
	if int(active_contract.get("progress", 0)) >= int(active_contract.get("target", 1)):
		active_contract["state"] = STATE_COMPLETED
	return active_contract.duplicate(true)

func can_extract() -> bool:
	if active_contract.is_empty():
		return true
	var state := str(active_contract.get("state", STATE_IDLE))
	return state == STATE_COMPLETED

func fail_active_contract() -> Dictionary:
	if has_active_contract():
		active_contract["state"] = STATE_FAILED
	return active_contract.duplicate(true)

func reset() -> void:
	active_contract = {}

func get_contract() -> Dictionary:
	return active_contract.duplicate(true)
