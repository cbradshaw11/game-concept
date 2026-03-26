extends Node
# class_name omitted — autoload singleton accessed via "ChallengeManager" globally

signal challenge_selected(id: String)
signal challenge_cleared

var active_challenge: String = ""
var _challenge_data: Array = []

func _ready() -> void:
	_challenge_data = DataStore.modifiers.get("challenge_runs", [])

# ── Public API ────────────────────────────────────────────────────────────────

func get_all_challenges() -> Array:
	return _challenge_data.duplicate(true)

func get_challenge(id: String) -> Dictionary:
	for ch in _challenge_data:
		if str(ch.get("id", "")) == id:
			return ch.duplicate(true)
	return {}

func get_available_challenges() -> Array:
	## Returns challenges the player has unlocked based on GameState stats.
	var result: Array = []
	for ch in _challenge_data:
		if _is_unlocked(ch):
			result.append(ch.duplicate(true))
	return result

func select_challenge(id: String) -> void:
	if id == "":
		clear_challenge()
		return
	var ch := get_challenge(id)
	if ch.is_empty():
		return
	if not _is_unlocked(ch):
		return
	active_challenge = id
	challenge_selected.emit(id)

func clear_challenge() -> void:
	active_challenge = ""
	challenge_cleared.emit()

func has_challenge(id: String) -> bool:
	return active_challenge == id

func is_challenge_active() -> bool:
	return active_challenge != ""

func get_shard_bonus() -> int:
	if active_challenge == "":
		return 0
	var ch := get_challenge(active_challenge)
	return int(ch.get("shard_bonus", 0))

func get_active_challenge_data() -> Dictionary:
	if active_challenge == "":
		return {}
	return get_challenge(active_challenge)

func end_run() -> void:
	## Called at end of run to clear the active challenge.
	active_challenge = ""

# ── Internal ──────────────────────────────────────────────────────────────────

func _is_unlocked(ch: Dictionary) -> bool:
	var unlock_type := str(ch.get("unlock_type", ""))
	var threshold := int(ch.get("unlock_threshold", 0))
	match unlock_type:
		"total_runs":
			return GameState.total_runs >= threshold
		"artifact_retrievals":
			return GameState.artifact_retrievals >= threshold
	return false
