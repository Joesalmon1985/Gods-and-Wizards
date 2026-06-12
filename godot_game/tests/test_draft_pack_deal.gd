class_name TestDraftPackDeal
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_deal_four_packs_of_eight(test_assert)
	_test_deal_consumes_thirty_two_cards(test_assert)


static func _test_deal_four_packs_of_eight(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	for player in state.players:
		var pack: Array = state.draft_packs_by_player.get(player.id, [])
		test_assert.eq(pack.size(), DraftRules.PACK_SIZE, "player %d should have 8-card pack" % player.id)


static func _test_deal_consumes_thirty_two_cards(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(77)
	GameStartRules.start_game(state)
	var seen: Dictionary = {}
	for player in state.players:
		for card_id in state.draft_packs_by_player.get(player.id, []):
			test_assert.check(not seen.has(card_id), "card %s dealt twice in age I" % card_id)
			seen[card_id] = true
	test_assert.eq(seen.size(), 32, "age I deal should consume exactly 32 unique cards")
