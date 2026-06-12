class_name TestDraftDeterminism
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_full_draft_hands_deterministic(test_assert)
	_test_twenty_four_cards_per_player(test_assert)


static func _test_full_draft_hands_deterministic(test_assert: TestAssert) -> void:
	var hands_a := _drafted_hands_for_seed(42)
	var hands_b := _drafted_hands_for_seed(42)
	test_assert.eq(hands_a, hands_b, "full 3-age draft should be deterministic from seed")


static func _test_twenty_four_cards_per_player(test_assert: TestAssert) -> void:
	var hands := _drafted_hands_for_seed(55)
	for player_id in hands.keys():
		test_assert.eq(hands[player_id].size(), 24, "player %d should draft 24 cards" % player_id)


static func _drafted_hands_for_seed(game_seed: int) -> Dictionary:
	var state := ScenarioBuilder.build_four_player_bot_game(game_seed)
	GameStartRules.start_game(state)
	var total_steps := DraftRules.PACK_SIZE * DraftRules.MAX_AGES
	for _step in total_steps:
		_simulate_round_wrap(state)
	var hands: Dictionary = {}
	for player in state.players:
		hands[player.id] = player.development_hand.duplicate()
	return hands


static func _simulate_round_wrap(state: GameState) -> void:
	var end_turn := state.action_space.get_action(0)
	for _i in state.players.size():
		ActionRules.apply(state, end_turn)
	DraftRules.complete_automatic_draft_for_bots(state)
