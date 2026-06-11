class_name City
extends RefCounted

var player_id: int
var vertex: BoardNode
var development_id: String = ""


func _init(p_player_id: int, p_vertex: BoardNode) -> void:
	player_id = p_player_id
	vertex = p_vertex
