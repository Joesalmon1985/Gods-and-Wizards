class_name ContactResolutionRules
extends RefCounted

static func resolve_after_hero_enters(state: GameState, node: BoardNode, hero_id: int = -1) -> Array:
	return _clear_demons_on_node(state, node, hero_id)


static func resolve_hero_node_after_demon_placement(state: GameState, node: BoardNode) -> Array:
	if not state.heroes_by_node.has(node.to_key()):
		return []
	var hero: Hero = state.heroes_by_node[node.to_key()]
	return _clear_demons_on_node(state, node, hero.id)


static func _clear_demons_on_node(state: GameState, node: BoardNode, hero_id: int) -> Array:
	var count := SetupRules.get_demon_count(state, node)
	if count <= 0:
		return []
	SetupRules.set_demon_count(state, node, 0)
	return [DemonsClearedEvent.new(state.round_number, node, count, hero_id)]
