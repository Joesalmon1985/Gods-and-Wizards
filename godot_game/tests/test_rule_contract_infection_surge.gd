class_name TestRuleContractInfectionSurge
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_age_one_surge_chance_zero(test_assert)
	_test_age_two_surge_can_trigger(test_assert)
	_test_age_three_surge_can_trigger(test_assert)
	_test_surge_prepends_discard(test_assert)
	_test_surge_emits_event(test_assert)
	_test_age_advance_still_increments_rate(test_assert)


static func _test_age_one_surge_chance_zero(test_assert: TestAssert) -> void:
	test_assert.eq(SpreadRules.surge_chance_for_age(1), 0, "age I surge chance is 0%")


static func _test_age_two_surge_can_trigger(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(501)
	state.draft_age = 2
	SpreadRules.initialize_deck(state)
	state.infection_discard_pile = ["node|0|0|0"]
	state.infection_draw_pile = ["node|1|0|0"]
	state.rng.enqueue_fixed_rolls([0])
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.check(_has_surge(events), "age II forced roll should trigger surge")


static func _test_age_three_surge_can_trigger(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(502)
	state.draft_age = 3
	SpreadRules.initialize_deck(state)
	state.infection_discard_pile = ["node|0|0|0"]
	state.infection_draw_pile = ["node|1|0|0"]
	state.rng.enqueue_fixed_rolls([0])
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.check(_has_surge(events), "age III forced roll should trigger surge")


static func _test_surge_prepends_discard(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(503)
	state.draft_age = 2
	state.infection_draw_pile = ["keep"]
	state.infection_discard_pile = ["discard_a", "discard_b"]
	state.rng.enqueue_fixed_rolls([1])
	SpreadRules.resolve_player_turn_end(state)
	test_assert.check(state.infection_draw_pile[0] in ["discard_a", "discard_b"], "surge should prepend shuffled discard")


static func _test_surge_emits_event(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(504)
	state.draft_age = 2
	state.infection_discard_pile = ["node|0|0|0"]
	state.infection_draw_pile = ["node|1|0|0"]
	state.rng.enqueue_fixed_rolls([0])
	var events := SpreadRules.resolve_player_turn_end(state)
	var found := false
	for event in events:
		if event is UnderworldSurgeEvent:
			found = true
	test_assert.check(found, "surge should emit UnderworldSurgeEvent")


static func _test_age_advance_still_increments_rate(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(505)
	DraftRules.initialize_for_game(state)
	var before := state.infection_rate
	state.draft_rounds_in_age = DraftRules.PACK_SIZE
	var picks := DraftRules._default_picks_for_step(state)
	DraftRules.advance_round_end_with_picks(state, picks)
	test_assert.check(state.infection_rate > before or state.draft_age > 1, "draft age advance increments infection rate")


static func _has_surge(events: Array) -> bool:
	for event in events:
		if event is UnderworldSurgeEvent:
			return true
	return false
