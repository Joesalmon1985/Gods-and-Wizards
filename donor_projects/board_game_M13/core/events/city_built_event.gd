class_name CityBuiltEvent
extends GameEvent

var round: int
var player_id: int
var vertex: VertexCoord


func _init(p_round: int, p_player_id: int, p_vertex: VertexCoord) -> void:
	event_type = "city_built"
	round = p_round
	player_id = p_player_id
	vertex = p_vertex


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round": round,
		"player_id": player_id,
		"vertex": vertex.to_dict(),
	}
