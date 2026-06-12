class_name TestTrainingEvaluationHarness
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_macro_eval_deterministic(test_assert)
	_test_micro_eval_deterministic(test_assert)
	_test_metrics_csv_schema(test_assert)
	_test_baseline_respects_legal_macro(test_assert)


static func _test_macro_eval_deterministic(test_assert: TestAssert) -> void:
	var a := TrainingEvaluationHarness.evaluate_macro(MacroBaselinePolicies.POLICY_HEURISTIC, 42, 2, 8)
	var b := TrainingEvaluationHarness.evaluate_macro(MacroBaselinePolicies.POLICY_HEURISTIC, 42, 2, 8)
	test_assert.eq(JSON.stringify(a), JSON.stringify(b), "macro eval should be deterministic")


static func _test_micro_eval_deterministic(test_assert: TestAssert) -> void:
	var a := TrainingEvaluationHarness.evaluate_micro(MicroBaselinePolicies.POLICY_DAMAGE_FIRST, 11, 2, 20)
	var b := TrainingEvaluationHarness.evaluate_micro(MicroBaselinePolicies.POLICY_DAMAGE_FIRST, 11, 2, 20)
	test_assert.eq(JSON.stringify(a), JSON.stringify(b), "micro eval should be deterministic")


static func _test_metrics_csv_schema(test_assert: TestAssert) -> void:
	var csv := TrainingEvaluationHarness.render_metrics_csv([
		TrainingEvaluationHarness.evaluate_macro(MacroBaselinePolicies.POLICY_RANDOM, 1, 1, 4),
	])
	test_assert.check(csv.contains("domain,policy_name"), "metrics csv should include header")


static func _test_baseline_respects_legal_macro(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42)
	var action := MacroBaselinePolicies.choose_action(env, MacroBaselinePolicies.POLICY_RANDOM)
	var legal := env.get_legal_actions(env.session.get_active_player_id())
	var found := false
	for candidate in legal:
		if candidate.action_id == action.action_id:
			found = true
	test_assert.check(found, "random baseline should choose legal action")
