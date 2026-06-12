class_name TradeRejectedEvent
extends GameEvent

var round_number: int
var offer_id: int
var from_player_id: int
var to_player_id: int


func _init(
	p_round_number: int,
	p_offer_id: int,
	p_from_player_id: int,
	p_to_player_id: int
) -> void:
	round_number = p_round_number
	offer_id = p_offer_id
	from_player_id = p_from_player_id
	to_player_id = p_to_player_id
	event_type = "trade_rejected"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"offer_id": offer_id,
		"from_player_id": from_player_id,
		"to_player_id": to_player_id,
	}
