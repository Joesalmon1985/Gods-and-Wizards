class_name BoardWorldMapper
extends RefCounted

const PLAYER_COLORS: Array[Color] = [
	Color(0.85, 0.25, 0.25),
	Color(0.25, 0.45, 0.9),
	Color(0.25, 0.75, 0.35),
	Color(0.95, 0.75, 0.2),
]


static func build_snapshot(state: GameState, recent_events: Array = []) -> Dictionary:
	return {
		"seed": state.seed,
		"round_number": state.round_number,
		"active_player_index": state.active_player_index,
		"active_player_name": _active_player_name(state),
		"player_turn_hint": state.active_player_index,
		"breach_count": state.breach_count,
		"total_demons": _total_demons(state),
		"game_finished": state.game_finished,
		"winner_id": state.winner_id,
		"recent_events": _recent_event_summaries(recent_events, state),
		"hexes": _map_hexes(state),
		"nodes": _map_nodes(state),
		"edges": _map_edges(state),
		"cities": _map_cities(state),
		"roads": _map_roads(state),
		"heroes": _map_heroes(state),
		"demons": _map_demons(state),
	}


static func hex_to_world(hex: HexCoord) -> Vector3:
	var x := BoardNodeAnchors.HEX_SIZE * (sqrt(3.0) * hex.q + sqrt(3.0) / 2.0 * hex.r)
	var z := BoardNodeAnchors.HEX_SIZE * (3.0 / 2.0 * hex.r)
	return Vector3(x, 0.0, z)


static func node_to_world(node: BoardNode, board: HexBoard) -> Vector3:
	return BoardNodeAnchors.node_to_world(node, board)


static func player_color(player_id: int) -> Color:
	if player_id < 0 or player_id >= PLAYER_COLORS.size():
		return Color(0.6, 0.6, 0.6)
	return PLAYER_COLORS[player_id]


static func _map_hexes(state: GameState) -> Array:
	var hexes: Array = []
	for coord in state.board.get_all_coords_sorted():
		var tile := state.board.get_tile(coord)
		var world := hex_to_world(coord)
		var max_chance := 0
		var dominant_resource := ""
		for resource in ResourceType.all():
			var chance := tile.get_production_chance(resource)
			max_chance = maxi(max_chance, chance)
			if chance >= max_chance and chance > 0:
				dominant_resource = ResourceType.to_key(resource)
		hexes.append({
			"id": coord.to_key(),
			"q": coord.q,
			"r": coord.r,
			"world": {"x": world.x, "y": world.y, "z": world.z},
			"max_production_chance": max_chance,
			"dominant_resource": dominant_resource,
		})
	return hexes


static func _map_nodes(state: GameState) -> Array:
	var nodes: Array = []
	for node in state.board.get_all_nodes_sorted():
		var world := node_to_world(node, state.board)
		var node_key := node.to_key()
		nodes.append({
			"id": node_key,
			"world": {"x": world.x, "y": world.y, "z": world.z},
			"has_city": state.cities_by_vertex.has(node_key),
		})
	return nodes


static func _map_edges(state: GameState) -> Array:
	var edges: Array = []
	for edge in state.board.get_all_edges_sorted():
		var world_a := node_to_world(edge.node_a, state.board)
		var world_b := node_to_world(edge.node_b, state.board)
		var edge_key := edge.to_key()
		edges.append({
			"id": edge_key,
			"node_a_id": edge.node_a.to_key(),
			"node_b_id": edge.node_b.to_key(),
			"world_a": {"x": world_a.x, "y": world_a.y, "z": world_a.z},
			"world_b": {"x": world_b.x, "y": world_b.y, "z": world_b.z},
			"has_road": state.roads_by_edge.has(edge_key),
			"road_owner_id": _road_owner(state, edge_key),
		})
	return edges


static func _map_cities(state: GameState) -> Array:
	var cities: Array = []
	for city in state.cities:
		cities.append({
			"id": "city:%s" % city.vertex.to_key(),
			"node_id": city.vertex.to_key(),
			"player_id": city.player_id,
			"development_id": city.development_id,
		})
	return cities


static func _map_roads(state: GameState) -> Array:
	var roads: Array = []
	for road in state.roads:
		roads.append({
			"id": "road:%s" % road.edge.to_key(),
			"edge_id": road.edge.to_key(),
			"player_id": road.player_id,
		})
	return roads


static func _map_heroes(state: GameState) -> Array:
	var heroes: Array = []
	for hero in state.heroes:
		heroes.append({
			"id": "hero:%d" % hero.id,
			"hero_id": hero.id,
			"player_id": hero.player_id,
			"node_id": hero.node.to_key(),
		})
	return heroes


static func _map_demons(state: GameState) -> Array:
	var demons: Array = []
	for node in state.board.get_all_nodes_sorted():
		var count := int(state.demon_counts_by_node.get(node.to_key(), 0))
		if count <= 0:
			continue
		demons.append({
			"id": "demon:%s" % node.to_key(),
			"node_id": node.to_key(),
			"count": count,
		})
	return demons


static func _road_owner(state: GameState, edge_key: String) -> int:
	var road: Road = state.roads_by_edge.get(edge_key)
	if road == null:
		return -1
	return road.player_id


static func _active_player_name(state: GameState) -> String:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return ""
	return player.display_name


static func _recent_event_summaries(events: Array, state: GameState) -> Array:
	if events.is_empty():
		return []
	var start := maxi(0, events.size() - 30)
	return EventSummary.summarize_events(events.slice(start), state)


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
