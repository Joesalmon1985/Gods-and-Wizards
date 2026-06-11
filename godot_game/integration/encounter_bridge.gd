class_name EncounterBridge
extends RefCounted

static func submit_hero_vs_demon(
	state: GameState,
	hero_id: int,
	node: BoardNode,
	hero_moves: Array[StringName],
	demon_moves: Array[StringName]
) -> Array:
	var hero := MoveRules.get_hero(state, hero_id)
	if hero == null:
		return []
	return EncounterRules.resolve_hero_vs_demon(state, hero, node, hero_moves, demon_moves)
