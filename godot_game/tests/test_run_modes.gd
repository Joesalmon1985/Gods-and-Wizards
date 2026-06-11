class_name TestRunModes
extends RefCounted

const EXPECTED_HEADER := (
	"seed,turn_number,round_number,active_player_id,active_player_name,action_type,"
	+ "action_details,event_type,event_details,event_summary,player_resources,city_count,road_count,"
	+ "demon_breach_info,score"
)


static func run(test_assert: TestAssert) -> void:
	_test_four_player_session(test_assert)
	_test_headless_csv_export(test_assert)
	_test_shared_game_state(test_assert)
	_test_wizard_mode_script_boundaries(test_assert)
	_test_csv_event_summary_column(test_assert)
	_test_wizard_mode_uses_reporting_helpers(test_assert)


static func _test_four_player_session(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	test_assert.eq(session.state.players.size(), 4, "four-player session should create 4 players")
	test_assert.eq(session.state.cities.size(), 4, "four-player session should start with 4 cities")
	test_assert.check(not session.finished, "session should not start finished")


static func _test_headless_csv_export(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(7)
	session.run_until_finished(12)
	var rows := PlaythroughCsvExporter.build_rows(session)
	test_assert.check(not rows.is_empty(), "playthrough export should produce rows")

	var csv := PlaythroughCsvExporter.render_csv(rows)
	var lines := csv.split("\n", false)
	test_assert.eq(lines[0], EXPECTED_HEADER, "playthrough CSV header should be stable")
	test_assert.check(lines.size() > 1, "playthrough CSV should include data rows")

	var temp_path := "user://test_playthrough_export.csv"
	var written := PlaythroughCsvExporter.write_session(session, 7, temp_path)
	test_assert.check(written != "", "playthrough CSV should write to disk")
	test_assert.check(FileAccess.file_exists(temp_path), "written CSV path should exist")


static func _test_shared_game_state(test_assert: TestAssert) -> void:
	var session_a := BotGameSession.start_four_player(99)
	var session_b := BotGameSession.start_four_player(99)
	session_a.run_until_finished(5)
	session_b.run_until_finished(5)
	test_assert.eq(
		JSON.stringify(session_a.to_result()["event_log"].to_dict()),
		JSON.stringify(session_b.to_result()["event_log"].to_dict()),
		"same seed should produce identical shared-session event logs"
	)


static func _test_wizard_mode_script_boundaries(test_assert: TestAssert) -> void:
	var path := "res://run_modes/wizard_world_mode.gd"
	var lines := ArchitectureScanner.read_code_lines(path)
	for line in lines:
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		test_assert.check(
			not ArchitectureScanner.line_contains_token(line, "SetupRules.place_city"),
			"wizard mode must not mutate state via SetupRules.place_city"
		)
		test_assert.check(
			not ArchitectureScanner.line_contains_token(line, "ActionRules.apply"),
			"wizard mode must advance via BotGameSession, not ActionRules.apply directly"
		)
		test_assert.check(
			not ArchitectureScanner.line_contains_token(line, "GameState.new"),
			"wizard mode must not construct a second GameState"
		)


static func _test_csv_event_summary_column(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(3)
	session.advance_one_player_turn()
	var rows := PlaythroughCsvExporter.build_rows(session)
	test_assert.check(not rows.is_empty(), "CSV rows should exist for event summary test")

	var has_readable_summary := false
	for row in rows:
		test_assert.check(row.has("event_summary"), "each CSV row should include event_summary")
		var summary := str(row.get("event_summary", ""))
		if summary != "" and not summary.begins_with("{"):
			has_readable_summary = true
	test_assert.check(has_readable_summary, "CSV should include at least one human-readable event summary")


static func _test_wizard_mode_uses_reporting_helpers(test_assert: TestAssert) -> void:
	var text := FileAccess.get_file_as_string("res://run_modes/wizard_world_mode.gd")
	test_assert.check("GameStateSummary" in text, "wizard mode should use GameStateSummary")
	test_assert.check("TurnReport" in text, "wizard mode should use TurnReport")
	test_assert.check("JSON.stringify" not in text, "wizard mode should not dump raw JSON in overlay")
