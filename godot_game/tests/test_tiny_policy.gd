class_name TestTinyPolicy
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_forward_pass(test_assert)
	_test_deterministic_weights(test_assert)
	_test_choose_legal_index(test_assert)


static func _test_forward_pass(test_assert: TestAssert) -> void:
	var policy := TinyPolicy.default_policy()
	var score := policy.forward({
		"victory_points": 3,
		"city_count": 1,
		"road_count": 2,
		"breach_count": 0,
		"total_demons": 1,
		"round_number": 2,
		"is_active_player": true,
	})
	test_assert.check(score > 0.0, "forward pass should return numeric score")


static func _test_deterministic_weights(test_assert: TestAssert) -> void:
	var a := TinyPolicy.default_policy()
	var b := TinyPolicy.default_policy()
	test_assert.eq(JSON.stringify(a.weights), JSON.stringify(b.weights), "default weights should match")


static func _test_choose_legal_index(test_assert: TestAssert) -> void:
	var policy := TinyPolicy.default_policy()
	var index := policy.choose_action_index([0, 1, 1, 0])
	test_assert.check(index >= 1 and index <= 2, "policy should pick a legal masked index")
