class_name Hero
extends RefCounted

var id: int
var player_id: int
var node: BoardNode
var health: int = 10


func _init(p_id: int, p_player_id: int, p_node: BoardNode, p_health: int = 10) -> void:
	id = p_id
	player_id = p_player_id
	node = p_node
	health = p_health
