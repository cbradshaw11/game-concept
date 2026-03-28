extends Node

signal zone_changed(old_zone: String, new_zone: String)
signal player_distance_changed(distance: float)

const SANCTUARY_RADIUS := 150.0  # home base safe zone
const INNER_START := 150.0
const MID_START := 800.0
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
