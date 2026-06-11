class_name GameOverEvent
extends GameEvent

const SCHEMA_VERSION := 1

var winner_id: int
var reason: String


func _init(p_winner_id: int, p_reason: String) -> void:
	event_type = "game_over"
	winner_id = p_winner_id
	reason = p_reason


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"type": event_type,
		"winner_id": winner_id,
		"reason": reason,
	}
