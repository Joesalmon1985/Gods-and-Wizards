class_name MoveRules
extends RefCounted

static func can_move_hero(state: GameState, player_id: int, hero: Hero, target: BoardNode) -> bool:
	if hero == null or target == null:
		return false
	if hero.player_id != player_id:
		return false
	if not state.board.has_node(target):
		return false
	if hero.node.equals(target):
		return false
	if state.heroes_by_node.has(target.to_key()):
		return false
	for adjacent in state.board.get_adjacent_nodes(hero.node):
		if adjacent.equals(target):
			return true
	return false


static func get_hero(state: GameState, hero_id: int) -> Hero:
	return state.heroes_by_id.get(hero_id)
