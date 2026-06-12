class_name TestStrategicDevelopmentViewModel
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_city_slots_for_human(test_assert)
	_test_hand_rules_text(test_assert)
	_test_audit_view_model_includes_development_fields(test_assert)


static func _test_city_slots_for_human(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(11, 0)
	var model := StrategicDevelopmentViewModel.build(session, 0)
	var slots: Array = model.get("city_slots", [])
	test_assert.check(slots.size() >= 1, "human should have at least one city slot row")
	test_assert.check(int(slots[0].get("max_slots", 0)) >= 1, "city row should include max slots")


static func _test_hand_rules_text(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(13, 0)
	session.state.players[0].development_hand.append("lumber_camp_a1")
	var model := StrategicDevelopmentViewModel.build(session, 0)
	var rules: Array = model.get("hand_rules_text", [])
	test_assert.check(rules.size() >= 1, "hand with catalog card should produce rules text")
	var formatted := StrategicDevelopmentViewModel.format_hand_rules(model)
	test_assert.check(formatted.contains("Card rules"), "formatted hand rules should have heading")


static func _test_audit_view_model_includes_development_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(5)
	var audit := StrategicAuditViewModel.build(session)
	test_assert.check(audit.has("development_slots_summary"), "audit model should include development slots")
	test_assert.check(audit.has("draft_pack_summary"), "audit model should include draft pack summary")
