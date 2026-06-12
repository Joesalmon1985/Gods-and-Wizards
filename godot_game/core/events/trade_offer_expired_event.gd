class_name TradeOfferExpiredEvent
extends GameEvent

var round_number: int
var offer_id: int
var from_player_id: int
var to_player_id: int


func _init(p_round_number: int, p_offer_id: int, p_from: int, p_to: int) -> void:
	round_number = p_round_number
	offer_id = p_offer_id
	from_player_id = p_from
	to_player_id = p_to
	event_type = "trade_offer_expired"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"offer_id": offer_id,
		"from_player_id": from_player_id,
		"to_player_id": to_player_id,
	}
