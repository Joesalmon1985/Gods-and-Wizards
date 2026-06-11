class_name DevelopmentBuiltEvent
extends GameEvent

var round_number: int
var player_id: int
var vertex: BoardNode
var development_id: String


func _init(p_round_number: int, p_player_id: int, p_vertex: BoardNode, p_development_id: String) -> void:
	round_number = p_round_number
	player_id = p_player_id
	vertex = p_vertex
	development_id = p_development_id
	event_type = "development_built"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"player_id": player_id,
		"vertex": vertex.to_dict(),
		"development_id": development_id,
	}
