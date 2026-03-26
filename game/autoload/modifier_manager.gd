extends Node
# class_name omitted — autoload singleton accessed via "ModifierManager" globally

signal modifier_added(modifier: Dictionary)
signal modifiers_cleared

var active_modifiers: Array = []
var _run_modifier_data: Array = []

func _ready() -> void:
	_run_modifier_data = DataStore.modifiers.get("run_modifiers", [])
	GameState.run_started.connect(_on_run_started)

func _on_run_started(_seed: int) -> void:
	clear_run_modifiers()

# ── Public API ────────────────────────────────────────────────────────────────

func add_modifier(id: String) -> void:
	var mod := _find_modifier(id)
	if mod.is_empty():
		return
	active_modifiers.append(mod)
	# Sync to GameState for run stats display
	GameState.set_active_modifiers(active_modifiers)
	modifier_added.emit(mod)

func has_modifier(id: String) -> bool:
	for mod in active_modifiers:
		if str(mod.get("id", "")) == id:
			return true
	return false

func get_active_modifiers() -> Array:
	return active_modifiers.duplicate(true)

func clear_run_modifiers() -> void:
	active_modifiers.clear()
	modifiers_cleared.emit()

func get_all_run_modifiers() -> Array:
	return _run_modifier_data.duplicate(true)

## Returns the combined additive bonus for a given stat key across all active modifiers.
## Example: get_stat_bonus("damage_pct") returns the sum of all damage_pct effects.
func get_stat_bonus(stat: String) -> float:
	var total: float = 0.0
	for mod in active_modifiers:
		var effects: Variant = mod.get("effects", {})
		if typeof(effects) == TYPE_DICTIONARY and effects.has(stat):
			total += float(effects[stat])
	return total

## Returns true if any active modifier has a boolean flag set to true.
func has_flag(flag: String) -> bool:
	for mod in active_modifiers:
		var effects: Variant = mod.get("effects", {})
		if typeof(effects) == TYPE_DICTIONARY:
			if bool(effects.get(flag, false)):
				return true
	return false

## Weighted random pick of one modifier not already active. Excludes already-held ids.
## Returns the modifier Dictionary or {} if none available.
func roll_modifier_offer(rng_seed: int) -> Dictionary:
	var available: Array = []
	for mod in _run_modifier_data:
		if not has_modifier(str(mod.get("id", ""))):
			available.append(mod)
	if available.is_empty():
		return {}
	# Weighted selection
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var total_weight: float = 0.0
	for mod in available:
		total_weight += float(mod.get("weight", 1))
	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for mod in available:
		cumulative += float(mod.get("weight", 1))
		if roll <= cumulative:
			return mod
	return available[available.size() - 1]

# ── Internal ──────────────────────────────────────────────────────────────────

func _find_modifier(id: String) -> Dictionary:
	for mod in _run_modifier_data:
		if str(mod.get("id", "")) == id:
			return mod.duplicate(true)
	return {}
