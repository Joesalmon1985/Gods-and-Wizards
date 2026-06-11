class_name VictoryPointsChangedEvent
extends GameEvent

const SCHEMA_VERSION := 1

var player_id: int
var delta: int
var total: int
var reason: String


func _init(p_player_id: int, p_delta: int, p_total: int, p_reason: String) -> void:
	event_type = "victory_points_changed"
	player_id = p_player_id
	delta = p_delta
	total = p_total
	reason = p_reason


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"type": event_type,
		"player_id": player_id,
		"delta": delta,
		"total": total,
		"reason": reason,
	}
