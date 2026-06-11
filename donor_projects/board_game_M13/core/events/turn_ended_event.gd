class_name TurnEndedEvent
extends GameEvent

var round: int
var player_id: int


func _init(p_round: int, p_player_id: int) -> void:
	event_type = "turn_ended"
	round = p_round
	player_id = p_player_id


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round": round,
		"player_id": player_id,
	}
