class_name TestDebugRunExport
extends RefCounted

const EXPECTED_HEADER := (
	"sequence_id,visual_step_index,round_number,active_player_id,player_id,"
	+ "event_type,action_id,action_kind,resource,amount,victory_points,hex,vertex,"
	+ "produced,production_chance,roll,details_json"
)


static func run(test_assert: TestAssert) -> void:
	var result := GameSimulator.run(42, 3)

	_test_stable_header(test_assert, result)
	_test_deterministic_csv(test_assert, result)
	_test_non_mutation(test_assert, result)
	_test_controller_export(test_assert)


static func _test_stable_header(test_assert: TestAssert, result: Dictionary) -> void:
	var csv := DebugRunExporter.render_csv(DebugRunExporter.build_rows(result))
	var lines := csv.split("\n", false)
	test_assert.check(not lines.is_empty(), "export should produce at least a header row")
	test_assert.eq(lines[0], EXPECTED_HEADER, "CSV header should be stable")


static func _test_deterministic_csv(test_assert: TestAssert, result: Dictionary) -> void:
	var first := DebugRunExporter.render_csv(DebugRunExporter.build_rows(result))
	var second_result := GameSimulator.run(42, 3)
	var second := DebugRunExporter.render_csv(DebugRunExporter.build_rows(second_result))
	test_assert.eq(first, second, "same seed and rounds should produce byte-identical CSV")


static func _test_non_mutation(test_assert: TestAssert, result: Dictionary) -> void:
	var state: GameState = result["state"]
	var log: EventLog = result["event_log"]
	var city_count := state.cities.size()
	var wood := state.players[0].get_resource(ResourceType.Type.WOOD)
	var entry_count := log.entries.size()

	DebugRunExporter.render_csv(DebugRunExporter.build_rows(result))

	test_assert.eq(state.cities.size(), city_count, "export should not mutate city count")
	test_assert.eq(state.players[0].get_resource(ResourceType.Type.WOOD), wood, "export should not mutate resources")
	test_assert.eq(log.entries.size(), entry_count, "export should not mutate event log size")


static func _test_controller_export(test_assert: TestAssert) -> void:
	var controller := DebugGameController.new()
	controller.load_simulation(42, 3)
	var csv := controller.export_csv_content()
	test_assert.check(not csv.is_empty(), "controller export should return CSV text")
	var lines := csv.split("\n", false)
	test_assert.check(lines.size() > 1, "controller export should include data rows")
