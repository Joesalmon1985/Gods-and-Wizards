class_name HeroMovedEvent
extends GameEvent

var round_number: int
var hero_id: int
var from_node: BoardNode
var to_node: BoardNode


func _init(p_round_number: int, p_hero_id: int, p_from: BoardNode, p_to: BoardNode) -> void:
	round_number = p_round_number
	hero_id = p_hero_id
	from_node = p_from
	to_node = p_to
	event_type = "hero_moved"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"hero_id": hero_id,
		"from_node": from_node.to_dict(),
		"to_node": to_node.to_dict(),
	}
