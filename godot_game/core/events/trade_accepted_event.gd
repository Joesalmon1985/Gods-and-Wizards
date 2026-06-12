class_name TradeAcceptedEvent
extends GameEvent

var round_number: int
var offer_id: int
var from_player_id: int
var to_player_id: int
var give_resource: ResourceType.Type
var give_amount: int
var receive_resource: ResourceType.Type
var receive_amount: int


func _init(
	p_round_number: int,
	p_offer_id: int,
	p_from_player_id: int,
	p_to_player_id: int,
	p_give_resource: ResourceType.Type,
	p_give_amount: int,
	p_receive_resource: ResourceType.Type,
	p_receive_amount: int
) -> void:
	round_number = p_round_number
	offer_id = p_offer_id
	from_player_id = p_from_player_id
	to_player_id = p_to_player_id
	give_resource = p_give_resource
	give_amount = p_give_amount
	receive_resource = p_receive_resource
	receive_amount = p_receive_amount
	event_type = "trade_accepted"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"offer_id": offer_id,
		"from_player_id": from_player_id,
		"to_player_id": to_player_id,
		"give_resource": ResourceType.to_key(give_resource),
		"give_amount": give_amount,
		"receive_resource": ResourceType.to_key(receive_resource),
		"receive_amount": receive_amount,
	}
