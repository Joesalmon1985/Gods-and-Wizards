class_name TestRuleContractInfection
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_first_player_end_turn_spreads(test_assert)
	_test_second_player_end_turn_spreads(test_assert)
	_test_initial_infection_rate_two(test_assert)
	_test_deterministic_draw_order(test_assert)
	_test_discard_reshuffle_continues_draw(test_assert)


static func _test_first_player_end_turn_spreads(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	test_assert.eq(state.active_player_index, 0, "game should start with player 0 active")
	var demons_before := _total_demons(state)
	var events := ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.check(_has_spread(events), "player 0 END_TURN should run infection spread")
	test_assert.check(_total_demons(state) >= demons_before, "first END_TURN should add demons via infection deck")


static func _test_second_player_end_turn_spreads(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(43)
	GameStartRules.start_game(state)
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.active_player_index, 1, "after first END_TURN player 1 should be active")
	var demons_before := _total_demons(state)
	var events := ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.check(_has_spread(events), "player 1 END_TURN should also run infection spread")
	test_assert.check(
		_total_demons(state) >= demons_before or RuleContractFixtures.has_breach_event(events),
		"second END_TURN should add demons or breach via infection deck"
	)


static func _test_initial_infection_rate_two(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(5)
	SpreadRules.initialize_deck(state)
	test_assert.eq(state.infection_rate, SpreadRules.INITIAL_INFECTION_RATE, "initial infection rate should be 2")


static func _test_deterministic_draw_order(test_assert: TestAssert) -> void:
	var first := _spread_signature(77)
	var second := _spread_signature(77)
	test_assert.eq(first, second, "infection spread should be deterministic with fixed seed")


static func _test_discard_reshuffle_continues_draw(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(88)
	SpreadRules.initialize_deck(state)
	var all_keys: Array[String] = []
	for node in state.board.get_all_nodes_sorted():
		all_keys.append(node.to_key())
	state.infection_discard_pile = all_keys.duplicate()
	state.infection_draw_pile.clear()
	state.infection_rate = 1
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.check(
		_has_spread(events) or RuleContractFixtures.has_breach_event(events),
		"reshuffle from discard should allow continued infection draw"
	)
	test_assert.check(state.infection_draw_pile.size() + state.infection_discard_pile.size() > 0, "deck state should remain consistent after reshuffle draw")


static func _spread_signature(seed: int) -> String:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	state.rng.seed(seed)
	SpreadRules.initialize_deck(state)
	var events := SpreadRules.resolve_player_turn_end(state)
	var parts: Array[String] = []
	for event in events:
		if event is DemonSpreadEvent:
			var spread: DemonSpreadEvent = event
			parts.append("%s:%d" % [spread.to_node.to_key(), spread.amount])
		elif event is BreachEvent:
			var breach: BreachEvent = event
			parts.append("breach:%d" % breach.breach_count)
	return "|".join(parts)


static func _has_spread(events: Array) -> bool:
	for event in events:
		if event is DemonSpreadEvent:
			return true
	return false


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
