class_name TestGameOver
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var events: Array = []
	var log := EventLog.new()
	ScoreRules.grant_victory_points(state, 1, GameConstants.VP_TO_WIN, "test_grant")
	var finished := GameSimulator._append_game_over_if_needed(state, events, log)
	test_assert.check(finished, "simulator hook should finish when VP threshold is reached")
	test_assert.eq(state.winner_id, 1, "simulator should record winning player")
	test_assert.check(events[0] is GameOverEvent, "simulator hook should emit GameOverEvent")

	var short_run := GameSimulator.run(42, 3)
	test_assert.check(not short_run["finished"], "short capped sim should not reach 21 VP")

	var breach_state := ScenarioBuilder.build_bot_ready_game(9)
	breach_state.breach_count = GameConstants.BREACH_LIMIT - 1
	test_assert.check(
		GameOverRules.evaluate(breach_state) == null,
		"breach count below limit should not end game"
	)
