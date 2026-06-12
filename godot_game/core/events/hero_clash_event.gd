class_name HeroClashEvent
extends GameEvent

var round_number: int
var node_key: String
var hero_id_a: int
var hero_id_b: int


func _init(p_round_number: int, p_node: BoardNode, p_hero_a: int, p_hero_b: int) -> void:
	round_number = p_round_number
	node_key = p_node.to_key()
	hero_id_a = p_hero_a
	hero_id_b = p_hero_b
	event_type = "hero_clash"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"node_key": node_key,
		"hero_id_a": hero_id_a,
		"hero_id_b": hero_id_b,
	}
