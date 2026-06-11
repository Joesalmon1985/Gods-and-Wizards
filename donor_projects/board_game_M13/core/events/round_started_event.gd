class_name RoundStartedEvent
extends GameEvent

var round: int


func _init(p_round: int) -> void:
	event_type = "round_started"
	round = p_round


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round": round,
	}
