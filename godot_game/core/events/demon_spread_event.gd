class_name DemonSpreadEvent
extends GameEvent

var round_number: int
var from_node: BoardNode
var to_node: BoardNode
var amount: int


func _init(p_round_number: int, p_from: BoardNode, p_to: BoardNode, p_amount: int) -> void:
	round_number = p_round_number
	from_node = p_from
	to_node = p_to
	amount = p_amount
	event_type = "demon_spread"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"from_node": from_node.to_dict(),
		"to_node": to_node.to_dict(),
		"amount": amount,
	}
