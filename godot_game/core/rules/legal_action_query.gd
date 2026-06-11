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
		ActionKind.Kind.BUILD_ROAD:
			if action.edge == null:
				return false
			if not BuildCosts.can_afford(active_player, BuildCosts.BUILD_ROAD):
				return false
			return BuildRules.can_build_road(state, active_player.id, action.edge)
		ActionKind.Kind.MOVE_HERO:
			var hero := MoveRules.get_hero(state, action.hero_id)
			return MoveRules.can_move_hero(state, active_player.id, hero, action.target_node)
		ActionKind.Kind.BUILD_DEVELOPMENT:
			if action.vertex == null:
				return false
			if not BuildCosts.can_afford(active_player, BuildCosts.BUILD_DEVELOPMENT):
				return false
			return DevelopmentRules.can_build(state, active_player.id, action.vertex)
		_:
			return false
