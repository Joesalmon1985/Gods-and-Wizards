class_name TestMacroRlTrainer
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_short_episode_rows(test_assert)
	_test_deterministic_episode(test_assert)
	_test_metrics_csv_columns(test_assert)


static func _test_short_episode_rows(test_assert: TestAssert) -> void:
	var result := MacroRlTrainer.run_short_episode(42, 8)
	test_assert.check(int(result.get("step_count", 0)) > 0, "trainer should record steps")
	test_assert.check(int(result.get("step_count", 0)) <= 8, "trainer should respect max steps")


static func _test_deterministic_episode(test_assert: TestAssert) -> void:
	var a := MacroRlTrainer.run_short_episode(77, 6)
	var b := MacroRlTrainer.run_short_episode(77, 6)
	test_assert.eq(JSON.stringify(a), JSON.stringify(b), "same seed should produce identical trainer output")


static func _test_metrics_csv_columns(test_assert: TestAssert) -> void:
	var result := MacroRlTrainer.run_short_episode(5, 3)
	var csv := MacroRlTrainer.render_metrics_csv(result)
	test_assert.check(csv.contains("policy_score"), "metrics csv should include policy_score")
	test_assert.check(csv.contains("rules_version"), "metrics csv should include rules_version")
