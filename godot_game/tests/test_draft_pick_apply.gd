class_name TestDraftPickApply
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_explicit_pick_updates_hand(test_assert)
	_test_illegal_pick_rejected(test_assert)


static func _test_explicit_pick_updates_hand(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	var pack0: Array = state.draft_packs_by_player[0].duplicate()
	var pick_id: String = pack0[2]
	var picks: Dictionary = {}
	for player in state.players:
		var pack: Array = state.draft_packs_by_player[player.id]
		picks[player.id] = str(pack[0])
	picks[0] = pick_id
	var events := DraftRules.advance_round_end_with_picks(state, picks)
	test_assert.check(not events.is_empty(), "draft step should emit events")
	test_assert.check(pick_id in state.players[0].development_hand, "picked card should be in hand")
	test_assert.check(pick_id not in state.draft_packs_by_player[0], "picked card should leave pack")


static func _test_illegal_pick_rejected(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	var picks: Dictionary = {}
	for player in state.players:
		var pack: Array = state.draft_packs_by_player[player.id]
		picks[player.id] = str(pack[0])
	picks[0] = "not_in_pack_card"
	var events := DraftRules.advance_round_end_with_picks(state, picks)
	test_assert.eq(events.size(), 0, "illegal pick should not resolve draft step")
