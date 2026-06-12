class_name TestDraftBotPolicy
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_bot_pick_deterministic(test_assert)
	_test_bot_picks_one_card(test_assert)


static func _test_bot_pick_deterministic(test_assert: TestAssert) -> void:
	var state_a := ScenarioBuilder.build_four_player_bot_game(42)
	var state_b := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state_a)
	GameStartRules.start_game(state_b)
	test_assert.eq(
		DraftBotPolicy.choose_card_id(state_a, 0),
		DraftBotPolicy.choose_card_id(state_b, 0),
		"bot draft pick should be deterministic"
	)


static func _test_bot_picks_one_card(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(77)
	GameStartRules.start_game(state)
	var pack: Array = state.draft_packs_by_player[1].duplicate()
	var pick := DraftBotPolicy.choose_card_id(state, 1)
	test_assert.check(pick in pack, "bot should pick from current pack")
