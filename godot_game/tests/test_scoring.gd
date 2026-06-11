class_name TestScoring
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	test_assert.eq(state.players[0].victory_points, 0, "players should start at 0 VP")

	var build_action := _first_legal_build(state)
	test_assert.check(build_action != null, "scenario should expose a legal build action")
	var applied := ActionRules.apply(state, build_action)
	test_assert.check(not applied.is_empty(), "legal build should apply")
	test_assert.eq(state.players[0].victory_points, 1, "building a city should award 1 VP")

	var low_vp_state := ScenarioBuilder.build_bot_ready_game(7)
	test_assert.check(
		GameOverRules.evaluate(low_vp_state) == null,
		"game should continue below VP threshold"
	)

	var grant_state := ScenarioBuilder.build_bot_ready_game(8)
	var events := ScoreRules.grant_victory_points(grant_state, 0, GameConstants.VP_TO_WIN, "test_grant")
	test_assert.eq(grant_state.players[0].victory_points, GameConstants.VP_TO_WIN, "grant should reach win threshold")
	test_assert.eq(events.size(), 1, "grant should emit VP event")

	var game_over := GameOverRules.evaluate(grant_state)
	test_assert.check(game_over != null, "21 VP should trigger game over")
	test_assert.eq(game_over.winner_id, 0, "granted player should win")


static func _first_legal_build(state: GameState) -> GameAction:
	var view := LegalActionQuery.get_view(state)
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_CITY:
			continue
		if view.legal_mask[action.action_id]:
			return action
	return null
