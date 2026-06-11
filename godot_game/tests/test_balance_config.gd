class_name TestBalanceConfig
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_defaults_match_constants(test_assert)
	_test_custom_max_turns_override(test_assert)
	_test_deterministic_with_same_config(test_assert)
	_test_batch_runner_respects_max_turns(test_assert)


static func _test_defaults_match_constants(test_assert: TestAssert) -> void:
	BalanceConfig.reset_cache()
	var config := BalanceConfig.defaults()
	test_assert.eq(config["vp_to_win"], GameConstants.VP_TO_WIN, "default vp_to_win should match GameConstants")
	test_assert.eq(config["breach_limit"], GameConstants.BREACH_LIMIT, "default breach_limit should match GameConstants")
	test_assert.eq(config["vp_per_city"], GameConstants.VP_PER_CITY, "default vp_per_city should match GameConstants")
	test_assert.eq(
		BalanceConfig.build_city_costs(),
		BuildCosts.BUILD_CITY,
		"default build city costs should match BuildCosts"
	)


static func _test_custom_max_turns_override(test_assert: TestAssert) -> void:
	BalanceConfig.reset_cache()
	BalanceConfig._loaded = BalanceConfig.defaults()
	BalanceConfig._loaded["max_turns_default"] = 3
	test_assert.eq(BalanceConfig.max_turns_default(), 3, "custom config should override max_turns_default")


static func _test_deterministic_with_same_config(test_assert: TestAssert) -> void:
	BalanceConfig.reset_cache()
	var first := BatchSimRunner.render_csv(BatchSimRunner.run_games(2, 11, BalanceConfig.max_turns_default()))
	BalanceConfig.reset_cache()
	var second := BatchSimRunner.render_csv(BatchSimRunner.run_games(2, 11, BalanceConfig.max_turns_default()))
	test_assert.eq(first, second, "same config and seeds should stay deterministic")


static func _test_batch_runner_respects_max_turns(test_assert: TestAssert) -> void:
	var row: Dictionary = BatchSimRunner.run_games(1, 55, 2)[0]
	test_assert.check(int(row["turns_played"]) <= 2, "batch runner should respect low max-turn cap")
