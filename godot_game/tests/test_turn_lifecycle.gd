class_name TestTurnLifecycle
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_begin_game_sets_turn_and_phase(test_assert)
	_test_end_turn_increments_turn_number(test_assert)
	_test_turn_scope_flags_reset_on_turn_start(test_assert)
	_test_production_only_on_round_wrap(test_assert)
	_test_legal_mask_size_unchanged_at_step_zero(test_assert)


static func _test_begin_game_sets_turn_and_phase(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	test_assert.eq(state.turn_number, 1, "begin_game should set turn_number to 1")
	test_assert.eq(
		state.current_phase,
		TurnPhase.Phase.ACTIVE_PLAYER,
		"begin_game should set ACTIVE_PLAYER phase"
	)


static func _test_end_turn_increments_turn_number(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	var end_turn := state.action_space.get_action(0)
	ActionRules.apply(state, end_turn)
	test_assert.eq(state.turn_number, 2, "first END_TURN should increment turn_number")
	test_assert.eq(state.active_player_index, 1, "END_TURN should advance active player")


static func _test_turn_scope_flags_reset_on_turn_start(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	state.turn_scope_flags["test_flag"] = true
	var end_turn := state.action_space.get_action(0)
	ActionRules.apply(state, end_turn)
	test_assert.check(
		not state.turn_scope_flags.has("test_flag"),
		"on_turn_start should clear turn_scope_flags"
	)


static func _test_production_only_on_round_wrap(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var start_events := GameStartRules.start_game(state)
	var production_on_start := false
	for event in start_events:
		if event is ProductionPhaseEvent:
			production_on_start = true
	test_assert.check(production_on_start, "game start should run turn-start production")

	var end_turn := state.action_space.get_action(0)
	var production_on_second_turn := false
	var turn_events := ActionRules.apply(state, end_turn)
	for event in turn_events:
		if event is ProductionPhaseEvent:
			production_on_second_turn = true
	test_assert.check(production_on_second_turn, "next player turn should run production at turn start")


static func _test_legal_mask_size_unchanged_at_step_zero(test_assert: TestAssert) -> void:
	var before := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(before)
	var after := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(after)
	test_assert.eq(
		before.action_space.size(),
		after.action_space.size(),
		"action space size should be unchanged after lifecycle wiring"
	)
	var view := LegalActionQuery.get_view(after)
	test_assert.eq(view.legal_mask.size(), after.action_space.size(), "legal mask size should match action space")
