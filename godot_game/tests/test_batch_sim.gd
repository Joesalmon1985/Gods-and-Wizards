class_name TestBatchSim
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_n_games_produce_n_rows(test_assert)
	_test_deterministic_output(test_assert)
	_test_csv_header_stable(test_assert)
	_test_row_fields_present(test_assert)


static func _test_n_games_produce_n_rows(test_assert: TestAssert) -> void:
	var rows := BatchSimRunner.run_games(3, 100, 5)
	test_assert.eq(rows.size(), 3, "N games should produce N summary rows")


static func _test_deterministic_output(test_assert: TestAssert) -> void:
	var first := BatchSimRunner.render_csv(BatchSimRunner.run_games(2, 7, 8))
	var second := BatchSimRunner.render_csv(BatchSimRunner.run_games(2, 7, 8))
	test_assert.eq(first, second, "same seed range should produce deterministic CSV")


static func _test_csv_header_stable(test_assert: TestAssert) -> void:
	var csv := BatchSimRunner.render_csv(BatchSimRunner.run_games(1, 1, 3))
	var header := csv.split("\n")[0]
	test_assert.eq(header, ",".join(BatchSimRunner.CSV_COLUMNS), "CSV header should match stable column list")


static func _test_row_fields_present(test_assert: TestAssert) -> void:
	var row: Dictionary = BatchSimRunner.run_games(1, 42, 10)[0]
	for column in BatchSimRunner.CSV_COLUMNS:
		test_assert.check(row.has(column), "row should include column %s" % column)
	test_assert.check(int(row["turns_played"]) >= 0, "turns_played should be non-negative")
