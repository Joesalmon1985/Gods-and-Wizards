class_name TestUnderworldPressure
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_pressure_scenario_seeds_demons(test_assert)
	_test_pressure_exceeds_default_start(test_assert)
	_test_deterministic_csv(test_assert)
	_test_csv_header_stable(test_assert)


static func _test_pressure_scenario_seeds_demons(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_underworld_pressure_game(42)
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	test_assert.check(total >= 4, "pressure scenario should seed multiple demons")


static func _test_pressure_exceeds_default_start(test_assert: TestAssert) -> void:
	var default_state := ScenarioBuilder.build_four_player_bot_game(42)
	var pressure_state := ScenarioBuilder.build_underworld_pressure_game(42)
	var default_demons := _total_demons(default_state)
	var pressure_demons := _total_demons(pressure_state)
	test_assert.check(
		pressure_demons > default_demons,
		"pressure scenario should start with more demons than default four-player setup"
	)


static func _test_deterministic_csv(test_assert: TestAssert) -> void:
	var first := UnderworldPressureRunner.render_csv(
		UnderworldPressureRunner.run_games(2, 7, 12)
	)
	var second := UnderworldPressureRunner.render_csv(
		UnderworldPressureRunner.run_games(2, 7, 12)
	)
	test_assert.eq(first, second, "same seed range should produce deterministic pressure CSV")


static func _test_csv_header_stable(test_assert: TestAssert) -> void:
	var csv := UnderworldPressureRunner.render_csv(UnderworldPressureRunner.run_games(1, 1, 8))
	var header := csv.split("\n")[0]
	test_assert.eq(header, ",".join(UnderworldPressureRunner.CSV_COLUMNS), "CSV header should match stable column list")


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
