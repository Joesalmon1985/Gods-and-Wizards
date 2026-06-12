class_name DraftAgeAdvancedEvent
extends GameEvent

var round_number: int
var draft_age: int


func _init(p_round_number: int, p_draft_age: int) -> void:
	round_number = p_round_number
	draft_age = p_draft_age
	event_type = "draft_age_advanced"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"draft_age": draft_age,
	}
