class_name LegalActionQuery
extends RefCounted

static func get_view(state: GameState) -> LegalActionView:
	var view := LegalActionView.new(state.action_space)
	var active_player := TurnRules.get_active_player(state)

	for action in state.action_space.all_actions_sorted():
		view.legal_mask[action.action_id] = _is_legal(state, active_player, action)

	return view


static func get_legal_actions_sorted(state: GameState) -> Array[GameAction]:
	var legal: Array[GameAction] = []
	var view := get_view(state)
	for action in state.action_space.all_actions_sorted():
		if view.legal_mask[action.action_id]:
			legal.append(action)
	return legal


static func _is_legal(state: GameState, active_player: Player, action: GameAction) -> bool:
	if active_player == null:
		return false

	match action.kind:
		ActionKind.Kind.END_TURN:
			return true
		ActionKind.Kind.BUILD_CITY:
			if action.vertex == null:
				return false
			if not state.board.has_vertex(action.vertex):
				return false
			if state.cities_by_vertex.has(action.vertex.to_key()):
				return false
			return BuildCosts.can_afford(active_player, BuildCosts.BUILD_CITY)
		_:
			return false
