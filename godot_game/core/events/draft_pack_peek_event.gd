class_name DraftPackPeekEvent
extends GameEvent

var round_number: int
var player_id: int
var card_id: String


func _init(p_round_number: int, p_player_id: int, p_card_id: String) -> void:
	round_number = p_round_number
	player_id = p_player_id
	card_id = p_card_id
	event_type = "draft_pack_peek"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"player_id": player_id,
		"card_id": card_id,
	}
