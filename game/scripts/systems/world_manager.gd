extends Node

signal zone_changed(old_zone: String, new_zone: String)
signal player_distance_changed(distance: float)

const SANCTUARY_RADIUS := 150.0  # home base safe zone
const INNER_START := 150.0
const MID_START := 1200.0
const OUTER_START := 2000.0
const WORLD_EDGE := 4000.0

var player_distance: float = 0.0:
	set(value):
		var old_d := player_distance
		player_distance = maxf(value, 0.0)
		if player_distance != old_d:
			player_distance_changed.emit(player_distance)
			var old_zone := get_zone_for_distance(old_d)
			var new_zone := get_zone_for_distance(player_distance)
			if old_zone != new_zone:
				current_zone = new_zone
				zone_changed.emit(old_zone, new_zone)

var current_zone: String = "sanctuary"

# Ring gate lock state — only inner_gate (at MID_START) and mid_gate (at OUTER_START)
var rings_unlocked: Dictionary = { "inner_gate": false, "mid_gate": false }

func unlock_ring(gate_id: String) -> void:
	rings_unlocked[gate_id] = true

func is_ring_locked(gate_id: String) -> bool:
	return not rings_unlocked.get(gate_id, false)

func get_gate_radius(gate_id: String) -> float:
	match gate_id:
		"inner_gate":
			return MID_START
		"mid_gate":
			return OUTER_START
		_:
			return 0.0

func get_zone_for_distance(d: float) -> String:
	if d >= OUTER_START:
		return "outer"
	elif d >= MID_START:
		return "mid"
	elif d >= INNER_START:
		return "inner"
	else:
		return "sanctuary"

func get_zone_boundary(zone: String) -> float:
	match zone:
		"sanctuary":
			return SANCTUARY_RADIUS
		"inner":
			return INNER_START
		"mid":
			return MID_START
		"outer":
			return OUTER_START
		_:
			return 0.0
