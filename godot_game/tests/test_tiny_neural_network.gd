class_name TestTinyNeuralNetwork
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_forward_shape(test_assert)
	_test_deterministic_weights_from_seed(test_assert)
	_test_masked_action_selection(test_assert)
	_test_supervised_training_step(test_assert)


static func _test_forward_shape(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(4, 8, 42)
	var output := net.forward(PackedFloat32Array([1.0, 0.5, 0.0, 0.25]))
	test_assert.eq(output.size(), 8, "forward output size should match output_size")


static func _test_deterministic_weights_from_seed(test_assert: TestAssert) -> void:
	var a := TinyNeuralNetwork.from_seed(4, 8, 99)
	var b := TinyNeuralNetwork.from_seed(4, 8, 99)
	test_assert.eq(JSON.stringify(a.to_dict()), JSON.stringify(b.to_dict()), "same seed should produce identical weights")


static func _test_masked_action_selection(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(4, 4, 7)
	var logits := net.forward(PackedFloat32Array([0.1, 0.2, 0.3, 0.4]))
	var index := net.choose_action_index(logits, [0, 1, 0, 1])
	test_assert.eq(index, 1, "masked selection should pick highest legal index")


static func _test_supervised_training_step(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(4, 4, 3)
	var features := PackedFloat32Array([1.0, 0.0, 0.5, 0.25])
	var before := net.forward(features).duplicate()
	net.train_supervised_step(features, 2, 0.1)
	var after := net.forward(features)
	test_assert.check(JSON.stringify(before) != JSON.stringify(after), "training step should mutate weights")
