class_name TestTurnOrder
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(42)

	test_assert.eq(state.active_player_index, 0, "active player should start at index 0")
	test_assert.eq(state.round_number, 1, "round should start at 1 before production fires")

	var active := TurnRules.get_active_player(state)
	test_assert.check(active != null, "active player should exist")
	test_assert.eq(active.id, 0, "active player should be player 0")
	test_assert.eq(active.display_name, "Alice", "active player should be Alice")

	test_assert.eq(TurnRules.get_active_player_id(state), 0, "active player id should be 0")
	test_assert.eq(TurnRules.player_count(state), 2, "player count should match setup")

	var empty_state := SetupRules.create_game(7)
	test_assert.check(
		TurnRules.get_active_player(empty_state) == null,
		"empty player list should return no active player"
	)
