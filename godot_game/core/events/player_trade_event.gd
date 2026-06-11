class_name PlayerTradeEvent
extends GameEvent

var turn: int
var player_id: int
var partner_player_id: int
var give_resource: ResourceType.Type
var receive_resource: ResourceType.Type
var amount: int


func _init(
	p_turn: int,
	p_player_id: int,
	p_partner_player_id: int,
	p_give_resource: ResourceType.Type,
	p_receive_resource: ResourceType.Type,
	p_amount: int
) -> void:
	event_type = "player_trade"
	turn = p_turn
	player_id = p_player_id
	partner_player_id = p_partner_player_id
	give_resource = p_give_resource
	receive_resource = p_receive_resource
	amount = p_amount


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"turn": turn,
		"player_id": player_id,
		"partner_player_id": partner_player_id,
		"give_resource": ResourceType.to_key(give_resource),
		"receive_resource": ResourceType.to_key(receive_resource),
		"amount": amount,
	}
