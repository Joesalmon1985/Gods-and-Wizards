class_name EncounterPresenter
extends RefCounted

## Routes embodied encounter UI requests through the integration bridge.

static func resolve_and_apply(
	state: GameState,
	hero_id: int,
	node: BoardNode,
	hero_moves: Array[StringName],
	demon_moves: Array[StringName]
) -> Array:
	return EncounterBridge.submit_hero_vs_demon(state, hero_id, node, hero_moves, demon_moves)
