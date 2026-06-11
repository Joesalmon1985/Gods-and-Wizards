class_name TestBreachEnd
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	state.breach_count = GameConstants.BREACH_LIMIT
	var game_over := GameOverRules.evaluate(state)
	test_assert.check(game_over != null, "breach limit should trigger game over")
	test_assert.eq(game_over.reason, "breach", "breach end should use breach reason")
	test_assert.eq(game_over.winner_id, -1, "breach loss should have no winner")
