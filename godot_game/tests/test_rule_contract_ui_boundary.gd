class_name TestRuleContractUiBoundary
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_game_state_summary_breach_after_session_end_turn(test_assert)
	_test_play_status_line_shows_breach(test_assert)
	_test_infection_rate_in_summary(test_assert)
	_test_development_view_model_occupation(test_assert)
	_test_draft_view_model_fields(test_assert)
	_test_audit_view_model_breach_after_forced_scenario(test_assert)


static func _test_game_state_summary_breach_after_session_end_turn(test_assert: TestAssert) -> void:
	var session := RuleContractFixtures.session_after_forced_breach_end_turn(test_assert, 6001)
	var summary := GameStateSummary.build(session.state, session)
	test_assert.eq(int(summary.get("breach_count", -1)), 1, "summary should expose breach_count after forced breach")
	test_assert.eq(
		int(summary.get("breach_limit", -1)),
		GameConstants.BREACH_LIMIT,
		"summary should expose breach_limit"
	)


static func _test_play_status_line_shows_breach(test_assert: TestAssert) -> void:
	var session := RuleContractFixtures.session_after_forced_breach_end_turn(test_assert, 6002)
	var summary := GameStateSummary.build(session.state, session)
	var status := RuleContractFixtures.play_status_line(summary, 0)
	test_assert.check(status.contains("breach=1"), "play status line should show breach count")
	test_assert.check(status.contains("infection="), "play status line should show infection rate")

	var play_source := FileAccess.get_file_as_string("res://run_modes/strategic_play_2d_mode.gd")
	test_assert.check("breach=%d" in play_source, "play mode should format breach in status label")


static func _test_infection_rate_in_summary(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(6003, 0)
	var summary := GameStateSummary.build(session.state, session)
	test_assert.check(summary.has("infection_rate"), "summary should include infection_rate")
	test_assert.eq(
		int(summary.get("infection_rate", -1)),
		session.state.infection_rate,
		"summary infection_rate should match state"
	)


static func _test_development_view_model_occupation(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(6004, 0)
	var city := session.state.cities[0]
	SetupRules.set_demon_count(session.state, city.vertex, 1)
	var model := StrategicDevelopmentViewModel.build(session, 0)
	var slots: Array = model.get("city_slots", [])
	var occupied_found := false
	for entry in slots:
		if entry.get("node_id", "") == city.vertex.to_key() and entry.get("occupied", false):
			occupied_found = true
	test_assert.check(occupied_found, "development view-model should mark demon-occupied city")


static func _test_draft_view_model_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(6005, 0)
	var model := StrategicDraftViewModel.build(session, 0)
	test_assert.check(model.has("draft_age"), "draft view-model should expose draft_age")
	test_assert.check(model.has("infection_rate"), "draft view-model should expose infection_rate")
	test_assert.check(model.has("hand_cards"), "draft view-model should expose hand cards")


static func _test_audit_view_model_breach_after_forced_scenario(test_assert: TestAssert) -> void:
	var session := RuleContractFixtures.session_after_forced_breach_end_turn(test_assert, 6006)
	var model := StrategicAuditViewModel.build(session)
	test_assert.eq(int(model.get("breach_count", -1)), 1, "audit view-model should expose updated breach_count")
	var header: String = str(model.get("header_text", ""))
	test_assert.check(header.contains("Breach: 1"), "audit header should show breach count")
