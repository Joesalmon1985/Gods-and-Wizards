class_name DraftCardPickedEvent
extends GameEvent

var round_number: int
var player_id: int
var development_id: String
var draft_age: int


func _init(p_round_number: int, p_player_id: int, p_development_id: String, p_draft_age: int) -> void:
	round_number = p_round_number
	player_id = p_player_id
	development_id = p_development_id
	draft_age = p_draft_age
	event_type = "draft_card_picked"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"player_id": player_id,
		"development_id": development_id,
		"draft_age": draft_age,
	}
