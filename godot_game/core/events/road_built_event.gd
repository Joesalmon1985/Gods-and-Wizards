class_name RoadBuiltEvent
extends GameEvent

var round_number: int
var player_id: int
var edge: EdgeCoord


func _init(p_round_number: int, p_player_id: int, p_edge: EdgeCoord) -> void:
	round_number = p_round_number
	player_id = p_player_id
	edge = p_edge
	event_type = "road_built"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"player_id": player_id,
		"edge": edge.to_dict(),
	}
