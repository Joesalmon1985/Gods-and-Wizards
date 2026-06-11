class_name SyncController
extends RefCounted

var state: GameState


func _init(p_state: GameState) -> void:
	state = p_state


func get_node_world_positions() -> Dictionary:
	var positions := {}
	for node in state.board.get_all_nodes_sorted():
		positions[node.to_key()] = BoardNodeAnchors.node_to_world(node, state.board)
	return positions


func get_read_only_snapshot() -> Dictionary:
	return GameSnapshot.snapshot(state, [])
