class_name City
extends RefCounted

var player_id: int
var vertex: BoardNode
var developments: Array[String] = []


var development_id: String:
	get:
		return developments[0] if developments.size() > 0 else ""
	set(value):
		developments.clear()
		if value != "":
			developments.append(value)


func _init(p_player_id: int, p_vertex: BoardNode) -> void:
	player_id = p_player_id
	vertex = p_vertex
