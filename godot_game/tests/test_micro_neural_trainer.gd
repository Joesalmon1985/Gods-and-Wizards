class_name TestMicroNeuralTrainer
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_train_completes(test_assert)
	_test_eval_completes_duel(test_assert)
	_test_metrics_csv(test_assert)


static func _test_train_completes(test_assert: TestAssert) -> void:
	var result := MicroNeuralTrainer.train_from_seed(21, 2, 12)
	test_assert.check(int(result.get("sample_count", 0)) > 0, "micro training should collect samples")


static func _test_eval_completes_duel(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(
		MicroCombatFeatureFeaturizer.FEATURE_SIZE,
		MicroCombatFeatureFeaturizer.MAX_SPELL_ACTIONS,
		9
	)
	var eval_result := MicroNeuralTrainer.evaluate_policy(net, 21, 80)
	test_assert.eq(int(eval_result.get("illegal_actions", -1)), 0, "eval should avoid illegal spells")
	test_assert.check(bool(eval_result.get("finished", false)), "eval should finish duel within step budget")


static func _test_metrics_csv(test_assert: TestAssert) -> void:
	var result := MicroNeuralTrainer.train_from_seed(3, 1, 8)
	var csv := MicroNeuralTrainer.render_metrics_csv(result)
	test_assert.check(csv.contains("winner_id"), "micro metrics csv should include winner_id column")
