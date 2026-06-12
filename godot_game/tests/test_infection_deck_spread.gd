class_name TestInfectionDeckSpread
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_end_turn_triggers_infection_not_only_round_wrap(test_assert)
	_test_infection_rate_initial_two(test_assert)
	_test_hero_node_draw_cleared(test_assert)


static func _test_end_turn_triggers_infection_not_only_round_wrap(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	var end_turn := state.action_space.get_action(0)
	var demons_before := _total_demons(state)
	var events := ActionRules.apply(state, end_turn)
	var spread_found := false
	for event in events:
		if event is DemonSpreadEvent:
			spread_found = true
	test_assert.check(spread_found, "first END_TURN should run infection spread")
	test_assert.check(_total_demons(state) >= demons_before, "END_TURN should add demons via infection deck")


static func _test_infection_rate_initial_two(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(5)
	SpreadRules.initialize_deck(state)
	test_assert.eq(state.infection_rate, SpreadRules.INITIAL_INFECTION_RATE, "initial infection rate should be 2")
	var events := SpreadRules.resolve_player_turn_end(state)
	var spread_count := 0
	for event in events:
		if event is DemonSpreadEvent:
			spread_count += 1
	test_assert.eq(spread_count, 2, "infection rate 2 should draw two placements per turn end")


static func _test_hero_node_draw_cleared(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(88)
	SpreadRules.initialize_deck(state)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	state.infection_draw_pile = [hero.node.to_key()]
	state.infection_discard_pile.clear()
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.eq(
		SetupRules.get_demon_count(state, hero.node),
		0,
		"infection draw onto hero node should be cleared by contact resolution"
	)
	var cleared := false
	for event in events:
		if event is DemonsClearedEvent:
			cleared = true
	test_assert.check(cleared, "hero node infection should emit DemonsClearedEvent")


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
