class_name TestEventSummary
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_production_aggregation(test_assert)
	_test_action_event_lines(test_assert)
	_test_unknown_event_degrades(test_assert)
	_test_log_entry_summaries(test_assert)


static func _test_production_aggregation(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(42)
	var events := TestScenario.run_production_rounds(state, 1)
	var lines := EventSummary.summarize_events(events, state)

	for line in lines:
		test_assert.check(not line.contains("production_check"), "production checks should not appear as raw JSON lines")
		test_assert.check(not line.begins_with("{"), "summaries should not dump JSON payloads")

	var production_lines: Array[String] = []
	for line in lines:
		if str(line).begins_with("Production:"):
			production_lines.append(line)
	test_assert.eq(production_lines.size(), 1, "production should aggregate into one summary line")
	test_assert.check(
		production_lines[0].contains("gained") or production_lines[0].contains("no resources"),
		"production summary should describe gains or none"
	)


static func _test_action_event_lines(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(5)
	var alice_vertex := BoardNode.from_hex_corner(HexCoord.new(0, 0), 0)
	var events: Array = [
		CityBuiltEvent.new(1, 0, alice_vertex),
		RoadBuiltEvent.new(1, 0, state.board.get_all_edges_sorted()[0]),
		TurnEndedEvent.new(1, 0),
	]
	var lines := EventSummary.summarize_events(events, state)

	test_assert.check(_lines_contain(lines, "built a city"), "city events should be readable")
	test_assert.check(_lines_contain(lines, "built a road"), "road events should be readable")
	test_assert.check(_lines_contain(lines, "ended their turn"), "turn end events should be readable")


static func _test_unknown_event_degrades(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(1)
	var line := EventSummary.summarize_event_entry("mystery_future_event", {"foo": 1}, state)
	test_assert.eq(line, "Event: mystery_future_event.", "unknown events should degrade safely")


static func _test_log_entry_summaries(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(3)
	var line := EventSummary.summarize_log_entry(
		{
			"type": "production_check",
			"payload": {
				"hex": {"q": 0, "r": 0},
				"resource": "wood",
				"roll": 4,
				"produced": true,
			},
		},
		state
	)
	test_assert.check("Production check:" in line, "production_check log entries should be readable")
	test_assert.check("Wood" in line, "production_check summary should name the resource")

	var gain_line := EventSummary.summarize_log_entry(
		{
			"type": "resource_gained",
			"payload": {
				"player_id": 0,
				"resource": "wood",
				"amount": 1,
			},
		},
		state
	)
	test_assert.check("Alice gained 1 Wood" in gain_line, "resource gains should be readable in log entries")


static func _lines_contain(lines: Array, fragment: String) -> bool:
	for line in lines:
		if fragment in str(line):
			return true
	return false
