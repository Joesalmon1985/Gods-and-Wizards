class_name TestMacroTrainingEnv
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_reset_observation_deterministic(test_assert)
	_test_legal_actions_match_query(test_assert)
	_test_inactive_player_has_no_legal_actions(test_assert)
	_test_illegal_step_rejected(test_assert)
	_test_legal_end_turn_through_rules(test_assert)
	_test_same_seed_action_sequence_summary(test_assert)
	_test_rewards_stable_per_player(test_assert)


static func _test_reset_observation_deterministic(test_assert: TestAssert) -> void:
	var env_a := MacroTrainingEnv.new()
	var env_b := MacroTrainingEnv.new()
	var obs_a := env_a.reset(42)
	var obs_b := env_b.reset(42)
	test_assert.eq(JSON.stringify(obs_a), JSON.stringify(obs_b), "same seed should produce identical initial observation")


static func _test_legal_actions_match_query(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var active_id := env.session.get_active_player_id()
	var env_actions := env.get_legal_actions(active_id)
	var query_actions := LegalActionQuery.get_legal_actions_sorted(env.session.state)
	test_assert.eq(env_actions.size(), query_actions.size(), "legal action count should match LegalActionQuery")
	for i in range(env_actions.size()):
		test_assert.eq(env_actions[i].action_id, query_actions[i].action_id, "legal actions should match LegalActionQuery order")


static func _test_inactive_player_has_no_legal_actions(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var inactive_id := (env.session.get_active_player_id() + 1) % 4
	test_assert.eq(env.get_legal_actions(inactive_id).size(), 0, "inactive player should have no legal actions")


static func _test_illegal_step_rejected(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var occupied := BoardNode.from_hex_corner(HexCoord.new(0, 0), 0)
	var illegal := _find_build_at_vertex(env.session.state, occupied)
	test_assert.check(illegal != null, "fixture should locate occupied BUILD_CITY action")

	var cities_before := env.session.state.cities.size()
	var result := env.step(illegal)
	test_assert.check(result["events"].is_empty(), "illegal step should return no events")
	test_assert.eq(env.session.state.cities.size(), cities_before, "illegal step should not mutate city count")


static func _test_legal_end_turn_through_rules(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var active_id := env.session.get_active_player_id()
	var end_turn := _end_turn_action(env.session.state)
	test_assert.check(end_turn != null, "active player should have END_TURN")

	var probe_state := ScenarioBuilder.build_four_player_bot_game(42)
	for event in GameStartRules.start_game(probe_state):
		pass
	var expected := ActionRules.apply(probe_state, end_turn)

	var result := env.step(end_turn)
	test_assert.check(not result["events"].is_empty(), "legal END_TURN should apply")
	test_assert.eq(_event_types(result["events"]), _event_types(expected), "step should match ActionRules events")
	test_assert.eq(env.session.get_active_player_id(), probe_state.active_player_index, "active player should advance like ActionRules")


static func _test_same_seed_action_sequence_summary(test_assert: TestAssert) -> void:
	var first := _run_end_turn_script(7)
	var second := _run_end_turn_script(7)
	test_assert.eq(JSON.stringify(first), JSON.stringify(second), "same seed and action sequence should produce identical summary")


static func _test_rewards_stable_per_player(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var rewards := env.get_rewards()
	test_assert.eq(rewards.size(), 4, "rewards should include all four players")
	for player_id in rewards.keys():
		test_assert.check(rewards[player_id] is float, "reward values should be floats")


static func _run_end_turn_script(game_seed: int) -> Dictionary:
	var env := MacroTrainingEnv.new()
	env.reset(game_seed)
	for _i in range(4):
		var end_turn := _end_turn_action(env.session.state)
		env.step(end_turn)
	return env.get_summary()


static func _end_turn_action(state: GameState) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.END_TURN:
			return action
	return null


static func _find_build_at_vertex(state: GameState, vertex: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY and action.vertex.equals(vertex):
			return action
	return null


static func _event_types(events: Array) -> Array:
	var types: Array = []
	for event in events:
		if event is GameEvent:
			types.append(event.event_type)
	return types
