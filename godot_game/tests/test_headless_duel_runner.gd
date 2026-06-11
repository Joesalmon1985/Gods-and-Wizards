class_name TestHeadlessDuelRunner
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_deterministic_encounter(test_assert)
	_test_exporter_stable_for_same_result(test_assert)
	_test_summary_fields(test_assert)
	_test_no_game_state_dependency(test_assert)


static func _test_deterministic_encounter(test_assert: TestAssert) -> void:
	var result_a := CombatResolver.run_seeded_smoke_duel(123)
	var result_b := CombatResolver.run_seeded_smoke_duel(123)
	test_assert.eq(
		JSON.stringify(result_a),
		JSON.stringify(result_b),
		"same seed should produce identical smoke duel results in-process"
	)


static func _test_exporter_stable_for_same_result(test_assert: TestAssert) -> void:
	var result := CombatResolver.run_seeded_smoke_duel(7)
	var summary := DuelLogExporter.build_summary_row(7, result, "hero", "demon")
	var rounds := DuelLogExporter.build_round_rows(7, result)
	var csv_a := DuelLogExporter.render_csv(summary, rounds)
	var csv_b := DuelLogExporter.render_csv(summary, rounds)
	test_assert.eq(csv_a, csv_b, "exporter should render identical CSV for same result")


static func _test_summary_fields(test_assert: TestAssert) -> void:
	var result := CombatResolver.run_seeded_smoke_duel(7)
	var row := DuelLogExporter.build_summary_row(7, result, "hero", "demon")
	for column in DuelLogExporter.SUMMARY_COLUMNS:
		test_assert.check(row.has(column), "summary row should include column %s" % column)
	test_assert.check(str(row["winner_id"]) != "", "duel should produce a winner")
	test_assert.check(int(row["rounds_played"]) > 0, "duel should play at least one round")


static func _test_no_game_state_dependency(test_assert: TestAssert) -> void:
	var runner_path := "res://run_modes/run_headless_duel.gd"
	var exporter_path := "res://core/export/duel_log_exporter.gd"
	var resolver_path := "res://core/combat/combat_resolver.gd"
	for path in [runner_path, exporter_path, resolver_path]:
		var text := FileAccess.get_file_as_string(path)
		test_assert.check("GameState" not in text, "%s should not depend on GameState" % path)
		test_assert.check("Node2D" not in text and "Node3D" not in text, "%s should stay headless" % path)

	var temp_path := "user://test_duel_export.csv"
	var result := CombatResolver.run_seeded_smoke_duel(99)
	var written := DuelLogExporter.write_result(99, result, "hero", "demon", temp_path)
	test_assert.check(written != "", "duel CSV should write to disk")
	test_assert.check(FileAccess.file_exists(temp_path), "written duel CSV path should exist")
