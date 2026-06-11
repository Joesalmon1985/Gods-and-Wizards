class_name TestGameStateSummary
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_session_summary_fields(test_assert)
	_test_all_players_and_resources(test_assert)
	_test_optional_systems_absent(test_assert)


static func _test_session_summary_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.advance_one_player_turn()
	var summary := GameStateSummary.build(session.state, session)

	test_assert.eq(summary.get("seed", -1), 42, "summary should include seed")
	test_assert.eq(summary.get("round_number", -1), session.state.round_number, "summary should include round")
	test_assert.eq(summary.get("turn_number", -1), session.player_turn_count, "summary should include turn count")
	test_assert.check(
		str(summary.get("active_player_name", "")).length() > 0,
		"summary should include active player name"
	)

	var header := GameStateSummary.format_header(summary)
	test_assert.check("Seed 42" in header, "header text should mention seed")
	test_assert.check("Round" in header, "header text should mention round")
	test_assert.check("Turn" in header, "header text should mention turn")


static func _test_all_players_and_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(7)
	var summary := GameStateSummary.build(state)
	var players: Array = summary.get("players", [])

	test_assert.eq(players.size(), 4, "summary should include all players")
	for row in players:
		test_assert.check(str(row.get("name", "")).length() > 0, "player row should include name")
		test_assert.check(row.has("victory_points"), "player row should include victory points")
		test_assert.check(row.has("city_count"), "player row should include city count")
		test_assert.check(row.has("road_count"), "player row should include road count")
		test_assert.check(row.has("hero_status"), "player row should include hero status placeholder")
		test_assert.check(int(row.get("wood", -1)) >= 0, "wood count should be readable")
		test_assert.check(int(row.get("brick", -1)) >= 0, "brick count should be readable")
		test_assert.check(int(row.get("wheat", -1)) >= 0, "wheat count should be readable")
		test_assert.check(int(row.get("sheep", -1)) >= 0, "sheep count should be readable")
		test_assert.check(int(row.get("ore", -1)) >= 0, "ore count should be readable")

	test_assert.eq(int(players[0].get("wood", -1)), 4, "fresh scenario should expose starting wood")
	test_assert.eq(int(players[0].get("brick", -1)), 2, "fresh scenario should expose starting brick")

	var scoreboard := GameStateSummary.format_scoreboard(summary)
	test_assert.check("Alice" in scoreboard, "scoreboard should list Alice")
	test_assert.check("Wood" in scoreboard, "scoreboard should list Wood resources")


static func _test_optional_systems_absent(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(99)
	var summary := GameStateSummary.build(state)

	test_assert.eq(summary.get("total_demons", -1), 0, "summary should report zero demons when absent")
	test_assert.eq(summary.get("total_roads", -1), 0, "summary should report zero roads when absent")
	for row in summary.get("players", []):
		test_assert.eq(str(row.get("hero_status", "")), "—", "hero status should use placeholder when absent")

	var header := GameStateSummary.format_header(summary)
	test_assert.check(header.length() > 0, "header should render without optional systems")
