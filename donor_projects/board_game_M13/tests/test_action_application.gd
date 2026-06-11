class_name TestActionApplication
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_illegal_action_rejected(test_assert)
	_test_build_city(test_assert)
	_test_end_turn_advances(test_assert)
	_test_round_wrap_runs_production(test_assert)


static func _test_illegal_action_rejected(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(42)
	var occupied_action := _find_build_at_vertex(state, VertexCoord.from_hex_corner(HexCoord.new(0, 0), 0))
	var wood_before := state.players[0].get_resource(ResourceType.Type.WOOD)

	var events := ActionRules.apply(state, occupied_action)
	test_assert.check(events.is_empty(), "illegal action should return no events")
	test_assert.eq(
		state.players[0].get_resource(ResourceType.Type.WOOD),
		wood_before,
		"illegal action should not change resources"
	)


static func _test_build_city(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)
	var build_action := _first_legal_build(state)
	var wood_before := TurnRules.get_active_player(state).get_resource(ResourceType.Type.WOOD)
	var city_count_before := state.cities.size()

	var events := ActionRules.apply(state, build_action)
	test_assert.check(not events.is_empty(), "legal BUILD_CITY should emit events")

	var built := false
	for event in events:
		if event is CityBuiltEvent:
			built = true
	test_assert.check(built, "BUILD_CITY should emit CityBuiltEvent")
	test_assert.eq(state.cities.size(), city_count_before + 1, "BUILD_CITY should add a city")
	test_assert.check(
		TurnRules.get_active_player(state).get_resource(ResourceType.Type.WOOD) < wood_before,
		"BUILD_CITY should deduct resources"
	)


static func _test_end_turn_advances(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)
	test_assert.eq(state.active_player_index, 0, "should start on player 0")

	var end_turn := state.action_space.get_action(0)
	var events := ActionRules.apply(state, end_turn)

	var ended := false
	for event in events:
		if event is TurnEndedEvent:
			ended = true
	test_assert.check(ended, "END_TURN should emit TurnEndedEvent")
	test_assert.eq(state.active_player_index, 1, "END_TURN should advance to next player")
	test_assert.eq(state.round_number, 1, "first END_TURN should not advance round")


static func _test_round_wrap_runs_production(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)
	var end_turn := state.action_space.get_action(0)

	ActionRules.apply(state, end_turn)
	test_assert.eq(state.active_player_index, 1, "player 1 turn after player 0 ends")

	var events := ActionRules.apply(state, end_turn)
	test_assert.eq(state.active_player_index, 0, "should wrap to player 0")
	test_assert.eq(state.round_number, 2, "round should advance after all players end turn")

	var production_found := false
	for event in events:
		if event is ProductionCheckEvent:
			production_found = true
			break
	test_assert.check(production_found, "round wrap should run production")


static func _first_legal_build(state: GameState) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.BUILD_CITY:
			return action
	return null


static func _find_build_at_vertex(state: GameState, vertex: VertexCoord) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY and action.vertex.equals(vertex):
			return action
	return null
