class_name TradeOffer
extends RefCounted

var offer_id: int = -1
var from_player_id: int = -1
var to_player_id: int = -1
var give_resource: ResourceType.Type = ResourceType.Type.WOOD
var give_amount: int = 1
var receive_resource: ResourceType.Type = ResourceType.Type.BRICK
var receive_amount: int = 1
var created_turn_number: int = 1


func _init(
	p_offer_id: int = -1,
	p_from_player_id: int = -1,
	p_to_player_id: int = -1,
	p_give_resource: ResourceType.Type = ResourceType.Type.WOOD,
	p_give_amount: int = 1,
	p_receive_resource: ResourceType.Type = ResourceType.Type.BRICK,
	p_receive_amount: int = 1,
	p_created_turn_number: int = 1
) -> void:
	offer_id = p_offer_id
	from_player_id = p_from_player_id
	to_player_id = p_to_player_id
	give_resource = p_give_resource
	give_amount = p_give_amount
	receive_resource = p_receive_resource
	receive_amount = p_receive_amount
	created_turn_number = p_created_turn_number
