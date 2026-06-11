class_name BuildRules
extends RefCounted

static func can_build_road(state: GameState, player_id: int, edge: EdgeCoord) -> bool:
	if not state.board.has_edge(edge):
		return false
	if state.roads_by_edge.has(edge.to_key()):
		return false
	return _has_connectivity(state, player_id, edge)


static func _has_connectivity(state: GameState, player_id: int, edge: EdgeCoord) -> bool:
	for node in [edge.node_a, edge.node_b]:
		if _player_owns_city_at(state, player_id, node):
			return true
		for adjacent_edge in state.board.get_edges_for_node(node):
			var road: Road = state.roads_by_edge.get(adjacent_edge.to_key())
			if road != null and road.player_id == player_id:
				return true
	return false


static func _player_owns_city_at(state: GameState, player_id: int, node: BoardNode) -> bool:
	var city: City = state.cities_by_vertex.get(node.to_key())
	return city != null and city.player_id == player_id
