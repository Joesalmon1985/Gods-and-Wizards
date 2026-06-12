class_name ContactResolutionRules
extends RefCounted

static func resolve_after_hero_enters(state: GameState, node: BoardNode, hero_id: int = -1) -> Array:
	return _clear_demons_on_node(state, node, hero_id)


static func resolve_hostile_hero_clash(
	state: GameState,
	moving_hero: Hero,
	defender: Hero,
	node: BoardNode
) -> Array:
	if moving_hero == null or defender == null:
		return []
	var moving_key := moving_hero.node.to_key()
	state.heroes_by_node.erase(moving_key)
	state.heroes_by_node.erase(node.to_key())
	_remove_hero(state, moving_hero.id)
	_remove_hero(state, defender.id)
	var remaining := int(state.hero_actions_remaining.get(moving_hero.id, GameConstants.HERO_ACTIONS_PER_TURN))
	state.hero_actions_remaining[moving_hero.id] = maxi(0, remaining - 1)
	SetupRules.rebuild_action_space(state)
	return [
		HeroClashEvent.new(state.round_number, node, moving_hero.id, defender.id),
	]


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


static func _remove_hero(state: GameState, hero_id: int) -> void:
	var hero: Hero = state.heroes_by_id.get(hero_id)
	if hero == null:
		return
	state.heroes_by_node.erase(hero.node.to_key())
	state.heroes_by_id.erase(hero_id)
	state.hero_actions_remaining.erase(hero_id)
	for i in range(state.heroes.size()):
		if state.heroes[i].id == hero_id:
			state.heroes.remove_at(i)
			break
