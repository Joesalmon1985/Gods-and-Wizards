class_name TestRuleContractBreach
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_demon_count_ladder(test_assert)
	_test_forced_end_turn_breach_core(test_assert)
	_test_forced_end_turn_breach_session(test_assert)
	_test_multi_draw_double_breach(test_assert)
	_test_breach_loss_at_ten_not_nine(test_assert)
	_test_reporting_after_breach(test_assert)


static func _test_demon_count_ladder(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(101)
	SpreadRules.initialize_deck(state)
	var node := RuleContractFixtures.pick_infection_target_node(state)
	for before in [0, 1, 2]:
		SetupRules.set_demon_count(state, node, before)
		state.breach_count = 0
		var events := SpreadRules.try_add_demon(state, node)
		test_assert.eq(
			SetupRules.get_demon_count(state, node),
			before + 1,
			"node with %d demons should gain 1 demon" % before
		)
		test_assert.eq(state.breach_count, 0, "sub-cap placement should not breach")
		var spread_found := false
		for event in events:
			if event is DemonSpreadEvent:
				spread_found = true
		test_assert.check(spread_found, "sub-cap placement should emit DemonSpreadEvent")

	SetupRules.set_demon_count(state, node, 3)
	state.breach_count = 0
	var cap_events := SpreadRules.try_add_demon(state, node)
	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "node at cap should stay at 3")
	test_assert.eq(state.breach_count, 1, "4th demon attempt should increment breach")
	test_assert.check(RuleContractFixtures.has_breach_event(cap_events), "cap breach should emit BreachEvent")


static func _test_forced_end_turn_breach_core(test_assert: TestAssert) -> void:
	var setup := RuleContractFixtures.forced_breach_setup(5551)
	var state: GameState = setup["state"]
	var node: BoardNode = setup["node"]
	var breach_before := state.breach_count
	var events := ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "capped node should stay at 3 demons after END_TURN")
	test_assert.eq(state.breach_count, breach_before + 1, "breach_count should increment by exactly 1")
	test_assert.check(RuleContractFixtures.has_breach_event(events), "END_TURN spread should emit BreachEvent")


static func _test_forced_end_turn_breach_session(test_assert: TestAssert) -> void:
	var session := RuleContractFixtures.session_after_forced_breach_end_turn(test_assert, 5552)
	test_assert.eq(session.state.breach_count, 1, "session state should reflect breach increment")
	test_assert.check(RuleContractFixtures.has_breach_event(session.events), "session event log should include breach")


static func _test_multi_draw_double_breach(test_assert: TestAssert) -> void:
	var setup := RuleContractFixtures.forced_breach_setup(5553)
	var state: GameState = setup["state"]
	var node: BoardNode = setup["node"]
	var key := node.to_key()
	state.infection_rate = 2
	state.infection_draw_pile = [key, key]
	state.infection_discard_pile.clear()
	state.breach_count = 0
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "capped node should remain at 3 after two over-cap draws")
	test_assert.eq(state.breach_count, 2, "two over-cap draws should increment breach twice")
	var breach_count := 0
	for event in events:
		if event is BreachEvent:
			breach_count += 1
	test_assert.eq(breach_count, 2, "two BreachEvents should be emitted for two over-cap draws")


static func _test_breach_loss_at_ten_not_nine(test_assert: TestAssert) -> void:
	var at_nine := ScenarioBuilder.build_bot_ready_game(60)
	at_nine.breach_count = GameConstants.BREACH_LIMIT - 1
	test_assert.check(GameOverRules.evaluate(at_nine) == null, "breach count 9 should not end game")

	var at_ten := ScenarioBuilder.build_bot_ready_game(61)
	at_ten.breach_count = GameConstants.BREACH_LIMIT
	var game_over := GameOverRules.evaluate(at_ten)
	test_assert.check(game_over != null, "breach count 10 should trigger game over")
	test_assert.eq(game_over.reason, "breach", "breach loss should use breach reason")


static func _test_reporting_after_breach(test_assert: TestAssert) -> void:
	var setup := RuleContractFixtures.forced_breach_setup(5554)
	var state: GameState = setup["state"]
	var events := ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	var lines := EventSummary.summarize_events(events, state)
	var found_summary := false
	for line in lines:
		if "underworld breach" in str(line) and "total breaches: 1" in str(line):
			found_summary = true
	test_assert.check(found_summary, "event summary should describe breach total")

	var session := RuleContractFixtures.session_after_forced_breach_end_turn(test_assert, 5554)
	var rows := PlaythroughCsvExporter.build_rows(session)
	var breach_row_found := false
	for row in rows:
		if str(row.get("event_type", "")) == "breach":
			breach_row_found = true
			test_assert.check(
				str(row.get("event_summary", "")).contains("underworld breach"),
				"playthrough breach row should have readable summary"
			)
	test_assert.check(breach_row_found, "playthrough should include breach row")
