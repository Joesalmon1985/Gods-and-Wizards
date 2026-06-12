class_name ProductionPhaseEvent
extends GameEvent

var turn_number: int
var player_id: int


func _init(p_turn_number: int, p_player_id: int) -> void:
	turn_number = p_turn_number
	player_id = p_player_id
	event_type = "production_phase"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"turn_number": turn_number,
		"player_id": player_id,
	}
