class_name TestMacroNeuralTrainer
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_train_completes(test_assert)
	_test_eval_uses_legal_actions(test_assert)
	_test_metrics_csv(test_assert)


static func _test_train_completes(test_assert: TestAssert) -> void:
	var result := MacroNeuralTrainer.train_from_seed(42, 2, 8)
	test_assert.check(int(result.get("sample_count", 0)) > 0, "training should collect samples")
	test_assert.check(result.has("eval"), "training should include eval block")


static func _test_eval_uses_legal_actions(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(
		MacroFeatureFeaturizer.FEATURE_SIZE,
		MacroFeatureFeaturizer.MAX_LEGAL_ACTIONS,
		5
	)
	var eval_result := MacroNeuralTrainer.evaluate_policy(net, 42, 10)
	test_assert.eq(int(eval_result.get("illegal_actions", -1)), 0, "fresh network eval should not pick illegal actions")


static func _test_metrics_csv(test_assert: TestAssert) -> void:
	var result := MacroNeuralTrainer.train_from_seed(7, 1, 4)
	var csv := MacroNeuralTrainer.render_metrics_csv(result)
	test_assert.check(csv.contains("seed,rules_version"), "metrics csv should include header")
