class_name TestPlaythroughCsvExporter
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_road_count_replayed_per_step(test_assert)
	_test_production_check_has_event_summary(test_assert)
	_test_deterministic_csv_bytes(test_assert)


static func _test_road_count_replayed_per_step(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.run_until_finished(40)
	var rows := PlaythroughCsvExporter.build_rows(session)
	test_assert.check(not rows.is_empty(), "playthrough should produce rows")

	var road_count_before := -1
	var road_count_at_build := -1
	for row in rows:
		var count := int(row.get("road_count", -1))
		if str(row.get("action_type", "")) == ActionKind.to_key(ActionKind.Kind.BUILD_ROAD):
			if road_count_at_build < 0:
				road_count_at_build = count
			break
		road_count_before = count

	test_assert.check(road_count_at_build >= 0, "simulation should build at least one road by turn 40")

	var final_road_count := session.state.roads.size()
	test_assert.check(final_road_count > 1, "session should have multiple roads after 40 turns")
	test_assert.check(
		road_count_at_build < final_road_count,
		"road_count on build row should reflect replayed count, not final session total"
	)
	if road_count_before >= 0:
		test_assert.eq(
			road_count_at_build,
			road_count_before + 1,
			"road_count should increment by one at road_built step"
		)


static func _test_production_check_has_event_summary(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.run_until_finished(8)
	var rows := PlaythroughCsvExporter.build_rows(session)

	var production_rows: Array = []
	for row in rows:
		if str(row.get("event_type", "")) == "production_check":
			production_rows.append(row)

	test_assert.check(not production_rows.is_empty(), "playthrough should include production_check rows")

	var readable_count := 0
	for row in production_rows:
		var summary := str(row.get("event_summary", ""))
		test_assert.check(not summary.begins_with("{"), "production_check summary should not be JSON")
		if summary != "":
			readable_count += 1

	test_assert.check(readable_count > 0, "at least one production_check row should have readable event_summary")


static func _test_deterministic_csv_bytes(test_assert: TestAssert) -> void:
	var session_a := BotGameSession.start_four_player(11)
	session_a.run_until_finished(10)
	var session_b := BotGameSession.start_four_player(11)
	session_b.run_until_finished(10)
	var csv_a := PlaythroughCsvExporter.render_csv(PlaythroughCsvExporter.build_rows(session_a))
	var csv_b := PlaythroughCsvExporter.render_csv(PlaythroughCsvExporter.build_rows(session_b))
	test_assert.eq(csv_a, csv_b, "same seed and turns should produce identical playthrough CSV")
