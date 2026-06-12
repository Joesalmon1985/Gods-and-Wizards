class_name UnderworldSurgeEvent
extends GameEvent

var round_number: int
var draft_age: int
var discard_count: int


func _init(p_round_number: int, p_draft_age: int, p_discard_count: int) -> void:
	round_number = p_round_number
	draft_age = p_draft_age
	discard_count = p_discard_count
	event_type = "underworld_surge"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"draft_age": draft_age,
		"discard_count": discard_count,
	}
