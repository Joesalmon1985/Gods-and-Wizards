class_name MacroBoardFeaturizer
extends RefCounted

## Fixed board tensor for radius-3 hex boards (GD-012).
## Per sorted node: demon_norm, hero_owner_norm, city_owner_norm, road_adjacent_flag.

const MAX_NODES := 60
const PER_NODE_FEATURES := 4
const BOARD_FEATURE_SIZE := MAX_NODES * PER_NODE_FEATURES


static func extract(state: GameState) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	values.resize(BOARD_FEATURE_SIZE)
	for i in range(BOARD_FEATURE_SIZE):
		values[i] = 0.0
	if state == null or state.board == null:
		return values
	var nodes := state.board.get_all_nodes_sorted()
	for index in range(mini(nodes.size(), MAX_NODES)):
		var node: BoardNode = nodes[index]
		var base := index * PER_NODE_FEATURES
		values[base] = float(SetupRules.get_demon_count(state, node)) / float(SpreadRules.MAX_DEMONS_PER_NODE)
		values[base + 1] = _hero_owner_norm(state, node)
		values[base + 2] = _city_owner_norm(state, node)
		values[base + 3] = 1.0 if _has_road_touch(state, node) else 0.0
	return values


static func to_json_array(state: GameState) -> Array:
	var packed := extract(state)
	var out: Array = []
	for value in packed:
		out.append(value)
	return out


static func _hero_owner_norm(state: GameState, node: BoardNode) -> float:
	var key := node.to_key()
	if not state.heroes_by_node.has(key):
		return 0.0
	var hero: Hero = state.heroes_by_node[key]
	return float(hero.player_id + 1) / 4.0


static func _city_owner_norm(state: GameState, node: BoardNode) -> float:
	var key := node.to_key()
	if not state.cities_by_vertex.has(key):
		return 0.0
	var city: City = state.cities_by_vertex[key]
	return float(city.player_id + 1) / 4.0


static func _has_road_touch(state: GameState, node: BoardNode) -> bool:
	for edge in state.board.get_edges_for_node(node):
		var edge_key := edge.to_key()
		if state.roads_by_edge.has(edge_key):
			return true
	return false
