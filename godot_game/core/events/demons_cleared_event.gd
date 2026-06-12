class_name DemonsClearedEvent
extends GameEvent

var round_number: int
var node: BoardNode
var cleared_count: int
var hero_id: int = -1


func _init(p_round_number: int, p_node: BoardNode, p_cleared_count: int, p_hero_id: int = -1) -> void:
	round_number = p_round_number
	node = p_node
	cleared_count = p_cleared_count
	hero_id = p_hero_id
	event_type = "demons_cleared"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"node": node.to_dict(),
		"cleared_count": cleared_count,
		"hero_id": hero_id,
	}
