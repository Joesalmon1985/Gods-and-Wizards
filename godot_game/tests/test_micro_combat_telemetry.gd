class_name TestMicroCombatTelemetry
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_schema_columns(test_assert)
	_test_deterministic_export(test_assert)
	_test_step_row_fields(test_assert)
	_test_exporter_headless(test_assert)


static func _test_schema_columns(test_assert: TestAssert) -> void:
	for column in MicroCombatTelemetrySchema.STEP_COLUMNS:
		test_assert.check(column != "", "schema should define column %s" % column)
	test_assert.eq(MicroCombatTelemetrySchema.SCHEMA_VERSION, "micro_combat_v1", "schema version should match")


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
