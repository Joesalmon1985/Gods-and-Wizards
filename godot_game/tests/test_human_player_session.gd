class_name TestHumanPlayerSession
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_one_human_three_bots_scenario(test_assert)
	_test_advance_bots_until_human(test_assert)
	_test_human_active_waits_without_auto_resolve(test_assert)
	_test_exposes_legal_actions(test_assert)
	_test_illegal_action_rejected(test_assert)
	_test_legal_action_applies_through_rules(test_assert)
	_test_bots_continue_after_human_turn(test_assert)
	_test_deterministic_human_action_sequence(test_assert)


static func _test_one_human_three_bots_scenario(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	test_assert.eq(session.state.players.size(), 4, "human session should have 4 players")
	test_assert.check(session.is_human_player(0), "player 0 should be configured as human")
	test_assert.check(not session.is_human_player(1), "player 1 should remain a bot")
	test_assert.check(not session.is_human_player(2), "player 2 should remain a bot")
	test_assert.check(not session.is_human_player(3), "player 3 should remain a bot")


static func _test_advance_bots_until_human(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 1)
	test_assert.check(
		not session.is_waiting_for_human(),
		"should not wait while a bot is active at game start"
	)
	test_assert.eq(session.get_active_player_id(), 0, "game should start on player 0")

	session.advance_until_human_or_game_over()
	test_assert.check(session.is_waiting_for_human(), "should pause when human player becomes active")
	test_assert.eq(session.get_active_player_id(), 1, "human seat should be active after bot advance")


static func _test_human_active_waits_without_auto_resolve(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(99, 0)
	test_assert.check(session.is_waiting_for_human(), "human player 0 should wait at game start")
	var turns_before := session.player_turn_count
	var events := session.advance_one_player_turn()
	test_assert.check(events.is_empty(), "human turn should not auto-resolve")
	test_assert.check(session.is_waiting_for_human(), "session should still wait for human input")
	test_assert.eq(session.player_turn_count, turns_before, "human turn should not increment until END_TURN")


static func _test_exposes_legal_actions(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(7, 0)
	var legal := session.get_legal_human_actions()
	test_assert.check(not legal.is_empty(), "human turn should expose legal actions")

	var view := LegalActionQuery.get_view(session.state)
	for action in legal:
		test_assert.check(
			view.legal_mask[action.action_id],
			"exposed human actions should come from the legal-action system"
		)


static func _test_illegal_action_rejected(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	var occupied := BoardNode.from_hex_corner(HexCoord.new(0, 0), 0)
	var illegal := _find_build_at_vertex(session.state, occupied)
	test_assert.check(illegal != null, "fixture should find a build action at an occupied vertex")

	var fingerprint := JSON.stringify(_state_fingerprint(session.state))
	var log_size_before := session.event_log.entries.size()
	var events := session.submit_human_action(illegal)
	test_assert.check(events.is_empty(), "illegal human action should be rejected")

	var fingerprint_after := JSON.stringify(_state_fingerprint(session.state))
	test_assert.eq(fingerprint, fingerprint_after, "illegal human action should not mutate authoritative state")
	test_assert.eq(
		session.event_log.entries.size(),
		log_size_before,
		"illegal human action should not append events"
	)


static func _test_legal_action_applies_through_rules(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	var end_turn := _end_turn_action(session.state)
	test_assert.check(end_turn != null, "human turn should include END_TURN")

	var expected_state := ScenarioBuilder.build_four_player_bot_game(42)
	for event in GameStartRules.start_game(expected_state):
		pass
	var expected := ActionRules.apply(expected_state, end_turn)
	var applied := session.submit_human_action(end_turn)
	test_assert.check(not applied.is_empty(), "legal human END_TURN should apply")

	var ended := false
	for event in applied:
		if event is TurnEndedEvent:
			ended = true
	test_assert.check(ended, "human END_TURN should emit TurnEndedEvent")
	test_assert.eq(
		_event_types(applied),
		_event_types(expected),
		"human action should produce the same events as ActionRules.apply"
	)
	test_assert.check(not session.is_waiting_for_human(), "human turn should close after END_TURN")


static func _test_bots_continue_after_human_turn(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	var end_turn := _end_turn_action(session.state)
	session.submit_human_action(end_turn)
	test_assert.eq(session.get_active_player_id(), 1, "human END_TURN should pass play to the next player")

	var turns_before := session.player_turn_count
	session.advance_until_human_or_game_over()
	test_assert.check(
		session.player_turn_count > turns_before,
		"bot turns should advance after the human ends turn"
	)
	test_assert.check(session.is_waiting_for_human(), "control should return to the human player")
	test_assert.eq(session.get_active_player_id(), 0, "human player should be active again after bot round")


static func _test_deterministic_human_action_sequence(test_assert: TestAssert) -> void:
	var first := _run_human_script(42)
	var second := _run_human_script(42)
	test_assert.eq(
		JSON.stringify(first.event_log.to_dict()),
		JSON.stringify(second.event_log.to_dict()),
		"same seed and human action sequence should produce identical event logs"
	)


static func _run_human_script(game_seed: int) -> BotGameSession:
	var session := BotGameSession.start_one_human_three_bots(game_seed, 0)
	var end_turn := _end_turn_action(session.state)
	session.submit_human_action(end_turn)
	session.advance_until_human_or_game_over()
	session.submit_human_action(end_turn)
	session.advance_until_human_or_game_over()
	return session


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


static func _state_fingerprint(state: GameState) -> Dictionary:
	var resources: Array = []
	for player in state.players:
		resources.append(
			player.get_resource(ResourceType.Type.WOOD) + player.get_resource(ResourceType.Type.BRICK)
		)
	return {
		"active": state.active_player_index,
		"round": state.round_number,
		"cities": state.cities.size(),
		"roads": state.roads.size(),
		"resources": resources,
	}
