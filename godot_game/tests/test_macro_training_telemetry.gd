class_name TestMacroTrainingTelemetry
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_schema_columns(test_assert)
	_test_deterministic_export(test_assert)
	_test_step_row_fields(test_assert)
	_test_fixed_seed_row_count(test_assert)
	_test_no_game_state_mutation_outside_env(test_assert)
	_test_legal_mask_matches_query_step_zero(test_assert)


static func _test_schema_columns(test_assert: TestAssert) -> void:
	for column in MacroTrainingTelemetrySchema.STEP_COLUMNS:
		test_assert.check(column != "", "schema should define non-empty column names")
	test_assert.eq(
		MacroTrainingTelemetrySchema.SCHEMA_VERSION,
		"macro_training_v2",
		"schema version should be macro_training_v2"
	)
	test_assert.check(
		MacroTrainingTelemetrySchema.STEP_COLUMNS.size() > MacroTrainingTelemetrySchema.LEGACY_V1_COLUMN_COUNT,
		"v2 schema should add columns beyond v1"
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
	test_assert.check(row.has("episode_id"), "v2 row should include episode_id")
	test_assert.check(row.has("draft_age"), "v2 row should include draft_age")
	test_assert.check(row.has("development_hand_json"), "v2 row should include development_hand_json")


static func _test_fixed_seed_row_count(test_assert: TestAssert) -> void:
	var max_steps := 12
	var rows := MacroTrainingTelemetryExporter.run_episode(99, max_steps, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.check(rows.size() > 0, "should record steps")
	test_assert.check(rows.size() <= max_steps, "row count should not exceed max steps")


static func _test_legal_mask_matches_query_step_zero(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42, BotTurnResolver.POLICY_HEURISTIC)
	var player_id := env.session.get_active_player_id()
	var view := env.get_legal_action_view(player_id)
	var mask: Array = JSON.parse_string(JSON.stringify(_mask_bits(view)))
	test_assert.check(mask is Array, "mask bits should parse as array")
	for i in range(mini(mask.size(), view.legal_mask.size())):
		var expected := 1 if view.legal_mask[i] else 0
		test_assert.eq(int(mask[i]), expected, "mask bit %d should match LegalActionQuery" % i)
	var end_turn := env.session.state.action_space.get_action(0)
	test_assert.eq(int(mask[end_turn.action_id]), 1, "END_TURN should be legal at step 0")


static func _mask_bits(view: LegalActionView) -> Array:
	var bits: Array = []
	for i in range(view.legal_mask.size()):
		bits.append(1 if view.legal_mask[i] else 0)
	return bits


static func _test_no_game_state_mutation_outside_env(test_assert: TestAssert) -> void:
	var exporter_path := "res://core/export/macro_training_telemetry_exporter.gd"
	var text := FileAccess.get_file_as_string(exporter_path)
	test_assert.check("ActionRules.apply" not in text, "exporter should not apply actions directly")
	test_assert.check("Node2D" not in text and "Node3D" not in text, "exporter should stay headless")
