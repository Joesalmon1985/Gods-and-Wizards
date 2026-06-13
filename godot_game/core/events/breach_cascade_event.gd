class_name BreachCascadeEvent
extends GameEvent

var round_number: int
var breach_source_node: BoardNode
var spread_from_node: BoardNode
var breach_count: int


func _init(
	p_round_number: int,
	p_breach_source: BoardNode,
	p_spread_from: BoardNode,
	p_breach_count: int
) -> void:
	round_number = p_round_number
	breach_source_node = p_breach_source
	spread_from_node = p_spread_from
	breach_count = p_breach_count
	event_type = "breach_cascade"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"breach_source_node": breach_source_node.to_dict(),
		"spread_from_node": spread_from_node.to_dict(),
		"breach_count": breach_count,
	}
