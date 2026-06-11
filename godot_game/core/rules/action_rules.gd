class_name ActionRules
extends RefCounted

static func apply(state: GameState, action: GameAction) -> Array:
	var view := LegalActionQuery.get_view(state)
	if not view.legal_mask[action.action_id]:
		return []

	match action.kind:
		ActionKind.Kind.END_TURN:
			return _apply_end_turn(state)
		ActionKind.Kind.BUILD_CITY:
			return _apply_build_city(state, action)
		ActionKind.Kind.BUILD_ROAD:
			return _apply_build_road(state, action)
		ActionKind.Kind.MOVE_HERO:
			return _apply_move_hero(state, action)
		ActionKind.Kind.BUILD_DEVELOPMENT:
			return _apply_build_development(state, action)
		_:
			return []


static func _apply_build_city(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	player.pay_cost(BuildCosts.BUILD_CITY)

	var city := SetupRules.place_city(state, player.id, action.vertex)
	if city == null:
		return []

	var events: Array = [CityBuiltEvent.new(state.round_number, player.id, action.vertex)]
	events.append_array(ScoreRules.apply_city_victory_points(state, player.id))
	return events


static func _apply_build_road(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	player.pay_cost(BuildCosts.BUILD_ROAD)
	var road := SetupRules.place_road(state, player.id, action.edge)
	if road == null:
		return []
	return [RoadBuiltEvent.new(state.round_number, player.id, action.edge)]


static func _apply_move_hero(state: GameState, action: GameAction) -> Array:
	var hero := MoveRules.get_hero(state, action.hero_id)
	if hero == null:
		return []
	var from_node := hero.node
	state.heroes_by_node.erase(from_node.to_key())
	hero.node = action.target_node
	state.heroes_by_node[action.target_node.to_key()] = hero
	return [HeroMovedEvent.new(state.round_number, hero.id, from_node, action.target_node)]


static func _apply_build_development(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	return DevelopmentRules.apply(state, player.id, action.vertex)


static func _apply_end_turn(state: GameState) -> Array:
	var player := TurnRules.get_active_player(state)
	var events: Array = [TurnEndedEvent.new(state.round_number, player.id)]

	state.active_player_index = (state.active_player_index + 1) % TurnRules.player_count(state)
	if state.active_player_index == 0:
		state.round_number += 1
		events.append(RoundStartedEvent.new(state.round_number))
		events.append_array(ProductionRules.resolve_round_production(state))
		events.append_array(SpreadRules.resolve_spread(state))
		var game_over := GameOverRules.evaluate(state)
		if game_over != null:
			state.game_finished = true
			state.winner_id = game_over.winner_id
			events.append(game_over)

	return events
