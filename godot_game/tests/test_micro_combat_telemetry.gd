class_name TestMicroCombatTelemetry
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_schema_columns(test_assert)
	_test_deterministic_export(test_assert)
	_test_step_row_fields(test_assert)
	_test_exporter_headless(test_assert)
	_test_terminal_winner_id(test_assert)
	_test_v2_json_fields_parse(test_assert)


static func _test_schema_columns(test_assert: TestAssert) -> void:
	for column in MicroCombatTelemetrySchema.STEP_COLUMNS:
		test_assert.check(column != "", "schema should define column %s" % column)
	test_assert.eq(MicroCombatTelemetrySchema.SCHEMA_VERSION, "micro_combat_v2", "schema version should match")


static func _test_deterministic_export(test_assert: TestAssert) -> void:
	var rows_a := MicroCombatTelemetryExporter.run_episode(123, 40, "hero_patrol", "demon_breach")
	var rows_b := MicroCombatTelemetryExporter.run_episode(123, 40, "hero_patrol", "demon_breach")
	test_assert.eq(
		MicroCombatTelemetryExporter.render_csv(rows_a),
		MicroCombatTelemetryExporter.render_csv(rows_b),
		"same seed should produce identical micro combat telemetry CSV"
	)


static func _test_step_row_fields(test_assert: TestAssert) -> void:
	var rows := MicroCombatTelemetryExporter.run_episode(11, 10, "hero_patrol", "demon_breach")
	test_assert.check(rows.size() > 0, "should produce step rows")
	var row: Dictionary = rows[0]
	for column in MicroCombatTelemetrySchema.STEP_COLUMNS:
		test_assert.check(row.has(column), "row should include %s" % column)
	test_assert.check(str(row["legal_mask_json"]).begins_with("["), "legal mask should be JSON array")


static func _test_exporter_headless(test_assert: TestAssert) -> void:
	var text := FileAccess.get_file_as_string("res://core/export/micro_combat_telemetry_exporter.gd")
	test_assert.check("GameState" not in text, "micro exporter should not depend on macro GameState")


static func _test_terminal_winner_id(test_assert: TestAssert) -> void:
	var rows := MicroCombatTelemetryExporter.run_episode(123, 120, "hero_patrol", "demon_breach")
	var terminal_row: Dictionary = {}
	for row in rows:
		if str(row.get("terminal", "")) == "true":
			terminal_row = row
	test_assert.check(not terminal_row.is_empty(), "finished duel should include terminal row")
	test_assert.check(str(terminal_row.get("winner_id", "")) != "", "terminal row should include winner_id")


static func _test_v2_json_fields_parse(test_assert: TestAssert) -> void:
	var rows := MicroCombatTelemetryExporter.run_episode(5, 8, "hero_patrol", "demon_breach")
	var row: Dictionary = rows[0]
	var pre_obs = JSON.parse_string(str(row.get("pre_observation_json", "{}")))
	var post_obs = JSON.parse_string(str(row.get("post_observation_json", "{}")))
	var components = JSON.parse_string(str(row.get("reward_components_json", "{}")))
	var timeline = JSON.parse_string(str(row.get("timeline_events_json", "[]")))
	test_assert.check(pre_obs is Dictionary, "pre_observation_json should parse")
	test_assert.check(post_obs is Dictionary, "post_observation_json should parse")
	test_assert.check(components is Dictionary, "reward_components_json should parse")
	test_assert.check(timeline is Array, "timeline_events_json should parse")
