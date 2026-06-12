class_name TestDraftAgeAdvance
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_eight_steps_advance_age(test_assert)
	_test_age_advance_bumps_infection(test_assert)


static func _test_eight_steps_advance_age(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	test_assert.eq(state.draft_age, 1, "starts age 1")
	for _step in DraftRules.PACK_SIZE:
		_simulate_round_wrap(state)
	test_assert.eq(state.draft_age, 2, "after 8 draft steps age should advance to 2")
	test_assert.eq(state.draft_rounds_in_age, 0, "draft rounds reset on age advance")


static func _test_age_advance_bumps_infection(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(43)
	GameStartRules.start_game(state)
	var infection_before := state.infection_rate
	for _step in DraftRules.PACK_SIZE:
		_simulate_round_wrap(state)
	test_assert.eq(state.infection_rate, infection_before + 1, "age end should increase infection rate")


static func _simulate_round_wrap(state: GameState) -> void:
	var end_turn := state.action_space.get_action(0)
	for _i in state.players.size():
		ActionRules.apply(state, end_turn)
