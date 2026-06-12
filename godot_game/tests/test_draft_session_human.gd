class_name TestDraftSessionHuman
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_human_draft_pick_through_session(test_assert)
	_test_bot_draft_pick_on_round_wrap(test_assert)


static func _test_human_draft_pick_through_session(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	_advance_to_draft(session)
	test_assert.check(session.waiting_for_draft, "session should wait for human draft")
	var legal := session.get_legal_human_actions()
	test_assert.check(not legal.is_empty(), "human should have draft pick options")
	var events := session.submit_human_action(legal[0])
	test_assert.check(not events.is_empty(), "human draft pick should apply")
	test_assert.check(not session.waiting_for_draft, "draft should complete after all picks")


static func _test_bot_draft_pick_on_round_wrap(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(99)
	for _i in 4:
		session.advance_one_player_turn()
	test_assert.check(session.state.players[0].development_hand.size() >= 1, "bots should draft on round wrap")


static func _advance_to_draft(session: BotGameSession) -> void:
	while not session.finished and not session.waiting_for_draft:
		if session.is_waiting_for_human() and not session.waiting_for_draft:
			var legal := session.get_legal_human_actions()
			if legal.is_empty():
				break
			session.submit_human_action(legal[0])
		else:
			session.advance_one_player_turn()
