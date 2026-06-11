class_name Road
extends RefCounted

var player_id: int
var edge: EdgeCoord


func _init(p_player_id: int, p_edge: EdgeCoord) -> void:
	player_id = p_player_id
	edge = p_edge
