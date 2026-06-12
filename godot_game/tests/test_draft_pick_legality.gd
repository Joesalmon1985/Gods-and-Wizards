class_name TestDraftPickLegality
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_legal_draft_pick_action(test_assert)
	_test_illegal_draft_pick_rejected(test_assert)


static func _test_legal_draft_pick_action(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	_begin_draft(state)
	var legal := LegalActionQuery.get_legal_draft_actions_for_player(state, 0)
	test_assert.check(not legal.is_empty(), "human draft actions should exist")
	var action := legal[0]
	var recorded := ActionRules.apply(state, action)
	test_assert.check(state.draft_pending_picks.has(0), "legal draft pick should be recorded")
	var events := DraftRules.complete_automatic_draft_for_bots(state)
	test_assert.check(not events.is_empty(), "draft step should finalize after all picks")


static func _test_illegal_draft_pick_rejected(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(43)
	GameStartRules.start_game(state)
	_begin_draft(state)
	var bad := GameAction.new(9999, ActionKind.Kind.DRAFT_PICK)
	bad.draft_player_id = 0
	bad.development_id = "not_a_real_card"
	var events := ActionRules.apply(state, bad)
	test_assert.eq(events.size(), 0, "illegal draft pick should be rejected")


static func _begin_draft(state: GameState) -> void:
	var end_turn := state.action_space.get_action(0)
	for _i in state.players.size():
		ActionRules.apply(state, end_turn)
