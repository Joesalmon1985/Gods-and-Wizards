class_name BreachEvent
extends GameEvent

var round_number: int
var breach_count: int


func _init(p_round_number: int, p_breach_count: int) -> void:
	round_number = p_round_number
	breach_count = p_breach_count
	event_type = "breach"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"breach_count": breach_count,
	}
