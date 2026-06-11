class_name City
extends RefCounted

var player_id: int
var vertex: VertexCoord


func _init(p_player_id: int, p_vertex: VertexCoord) -> void:
	player_id = p_player_id
	vertex = p_vertex
