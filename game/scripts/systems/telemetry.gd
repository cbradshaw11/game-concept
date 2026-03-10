extends RefCounted
class_name Telemetry

var enabled: bool = true
var events: Array[Dictionary] = []

func log_event(event_name: String, payload: Dictionary) -> void:
	if not enabled:
		return

	var record := {
		"event": event_name,
		"seed": int(payload.get("seed", 0)),
		"ring": str(payload.get("ring", "unknown")),
		"timestamp": int(Time.get_unix_time_from_system()),
		"payload": payload.duplicate(true),
	}
	events.append(record)
	print("TELEMETRY %s seed=%d ring=%s" % [record["event"], record["seed"], record["ring"]])

func clear() -> void:
	events.clear()

func latest() -> Dictionary:
	if events.is_empty():
		return {}
	return events[events.size() - 1].duplicate(true)
