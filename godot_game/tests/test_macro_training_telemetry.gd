class_name TestMacroTrainingTelemetry
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_schema_columns(test_assert)
	_test_deterministic_export(test_assert)
	_test_step_row_fields(test_assert)
	_test_fixed_seed_row_count(test_assert)
	_test_no_game_state_mutation_outside_env(test_assert)


static func _test_schema_columns(test_assert: TestAssert) -> void:
	for column in MacroTrainingTelemetrySchema.STEP_COLUMNS:
		test_assert.check(column != "", "schema should define non-empty column names")
	test_assert.eq(
		MacroTrainingTelemetrySchema.SCHEMA_VERSION,
		"macro_training_v1",
		"schema version should be macro_training_v1"
	)


static func _test_deterministic_export(test_assert: TestAssert) -> void:
	var rows_a := MacroTrainingTelemetryExporter.run_episode(42, 20, BotTurnResolver.POLICY_HEURISTIC)
	var rows_b := MacroTrainingTelemetryExporter.run_episode(42, 20, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.eq(
		MacroTrainingTelemetryExporter.render_csv(rows_a),
		MacroTrainingTelemetryExporter.render_csv(rows_b),
		"same seed and max steps should produce identical telemetry CSV"
	)


static func _test_step_row_fields(test_assert: TestAssert) -> void:
	var rows := MacroTrainingTelemetryExporter.run_episode(7, 5, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.check(rows.size() > 0, "episode should produce at least one step row")
	var row: Dictionary = rows[0]
	for column in MacroTrainingTelemetrySchema.STEP_COLUMNS:
		test_assert.check(row.has(column), "step row should include column %s" % column)
	test_assert.check(str(row["legal_mask_json"]).begins_with("["), "legal mask should be JSON array")
	test_assert.check(str(row["selected_action_id"]) != "", "selected action id should be recorded")


static func _test_fixed_seed_row_count(test_assert: TestAssert) -> void:
	var max_steps := 12
	var rows := MacroTrainingTelemetryExporter.run_episode(99, max_steps, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.check(rows.size() > 0, "should record steps")
	test_assert.check(rows.size() <= max_steps, "row count should not exceed max steps")


static func _test_no_game_state_mutation_outside_env(test_assert: TestAssert) -> void:
	var exporter_path := "res://core/export/macro_training_telemetry_exporter.gd"
	var text := FileAccess.get_file_as_string(exporter_path)
	test_assert.check("ActionRules.apply" not in text, "exporter should not apply actions directly")
	test_assert.check("Node2D" not in text and "Node3D" not in text, "exporter should stay headless")
