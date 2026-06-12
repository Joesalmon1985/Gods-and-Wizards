class_name TestRuleContractProductionTiming
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_active_player_production_at_turn_start(test_assert)
	_test_production_not_only_on_round_wrap(test_assert)
	_test_non_active_players_no_production(test_assert)
	_test_occupied_city_produces_zero(test_assert)
	_test_production_phase_event(test_assert)


static func _test_active_player_production_at_turn_start(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(801)
	state.rng.enqueue_fixed_rolls([0, 0, 0, 0, 0])
	var events := GameStartRules.start_game(state)
	test_assert.check(_has_production(events), "game start should run active player production")


static func _test_production_not_only_on_round_wrap(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(802)
	GameStartRules.start_game(state)
	var events := ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.check(_has_production(events), "next player turn start should run production")


static func _test_non_active_players_no_production(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(803)
	GameStartRules.start_game(state)
	var p0_wood := state.players[0].get_resource(ResourceType.Type.WOOD)
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	var p0_after := state.players[0].get_resource(ResourceType.Type.WOOD)
	test_assert.eq(p0_wood, p0_after, "non-active player should not receive production on other turn start")


static func _test_occupied_city_produces_zero(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(804)
	var city := state.cities[0]
	SetupRules.set_demon_count(state, city.vertex, 1)
	state.rng.enqueue_fixed_rolls([0])
	var wood_before := state.players[city.player_id].get_resource(ResourceType.Type.WOOD)
	var events := ProductionRules.resolve_active_player_turn_start_production(state)
	var gained := 0
	for event in events:
		if event is ResourceGainedEvent:
			var gain: ResourceGainedEvent = event
			if gain.resource == ResourceType.Type.WOOD and gain.player_id == city.player_id:
				gained += gain.amount
	test_assert.eq(gained, 0, "demon-occupied active-player city produces 0")


static func _test_production_phase_event(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(805)
	var events := GameStartRules.start_game(state)
	var found := false
	for event in events:
		if event is ProductionPhaseEvent:
			found = true
	test_assert.check(found, "production phase event emitted")


static func _has_production(events: Array) -> bool:
	for event in events:
		if event is ProductionPhaseEvent or event is ProductionCheckEvent or event is ResourceGainedEvent:
			return true
	return false
