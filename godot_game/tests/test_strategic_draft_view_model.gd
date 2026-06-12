class_name TestStrategicDraftViewModel
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_pack_and_hand_fields(test_assert)
	_test_draft_waiting_flag(test_assert)
	_test_pack_summary_format(test_assert)


static func _test_pack_and_hand_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	var model := StrategicDraftViewModel.build(session, 0)
	test_assert.check(model.has("pack_cards"), "draft model should expose pack_cards")
	test_assert.check(model.has("hand_cards"), "draft model should expose hand_cards")
	test_assert.eq(int(model.get("pack_size", 0)), 8, "fresh game should deal 8-card pack")
	test_assert.eq(str(model.get("phase", "")), "active_player", "initial phase should be active_player")
	test_assert.check(model.has("infection_rate"), "draft model should expose infection_rate")


static func _test_draft_waiting_flag(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	_advance_to_draft(session)
	var model := StrategicDraftViewModel.build(session, 0)
	test_assert.check(session.waiting_for_draft, "session should be waiting for draft")
	test_assert.check(bool(model.get("waiting_for_draft", false)), "model should mirror waiting_for_draft")


static func _test_pack_summary_format(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(7, 0)
	var model := StrategicDraftViewModel.build(session, 0)
	var summary := StrategicDraftViewModel.format_pack_summary(model)
	test_assert.check(summary.contains("Draft pack"), "pack summary should have heading")
	test_assert.check(summary.contains("age"), "pack summary should mention age")


static func _advance_to_draft(session: BotGameSession) -> void:
	while not session.finished and not session.waiting_for_draft:
		if session.is_waiting_for_human() and not session.waiting_for_draft:
			var legal := session.get_legal_human_actions()
			if legal.is_empty():
				break
			session.submit_human_action(legal[0])
		else:
			session.advance_one_player_turn()
