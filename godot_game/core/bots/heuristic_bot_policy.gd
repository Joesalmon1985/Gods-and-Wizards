class_name HeuristicBotPolicy
extends RefCounted

static func choose_action(state: GameState) -> GameAction:
	var legal := LegalActionQuery.get_legal_actions_sorted(state)
	var best_build: GameAction = null
	var best_score := -1

	for action in legal:
		if action.kind != ActionKind.Kind.BUILD_CITY:
			continue
		var score := _vertex_production_score(state, action.vertex)
		if score > best_score or (score == best_score and (best_build == null or action.action_id < best_build.action_id)):
			best_score = score
			best_build = action

	if best_build != null:
		return best_build
	return state.action_space.get_action(0)


static func _vertex_production_score(state: GameState, vertex: BoardNode) -> int:
	var total := 0
	for hex in state.board.get_hexes_for_vertex(vertex):
		var tile := state.board.get_tile(hex)
		for resource in ResourceType.all():
			total += tile.get_production_chance(resource)
	return total
