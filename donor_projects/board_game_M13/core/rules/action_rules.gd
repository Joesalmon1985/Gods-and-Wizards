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


static func _apply_end_turn(state: GameState) -> Array:
	var player := TurnRules.get_active_player(state)
	var events: Array = [TurnEndedEvent.new(state.round_number, player.id)]

	state.active_player_index = (state.active_player_index + 1) % TurnRules.player_count(state)
	if state.active_player_index == 0:
		state.round_number += 1
		events.append(RoundStartedEvent.new(state.round_number))
		events.append_array(ProductionRules.resolve_round_production(state))

	return events
