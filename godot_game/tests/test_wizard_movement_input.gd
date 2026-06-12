class_name TestWizardMovementInput
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_wasd_forward(test_assert)
	_test_qe_yaw(test_assert)


static func _test_wasd_forward(test_assert: TestAssert) -> void:
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	var delta := WizardMovementInput.compute_move_delta(keys, 1.0)
	test_assert.check(delta.z < 0.0, "W should move marker forward (negative Z)")


static func _test_qe_yaw(test_assert: TestAssert) -> void:
	var q_keys := WizardMovementInput.keys_from_pressed(false, false, false, false, true, false)
	var e_keys := WizardMovementInput.keys_from_pressed(false, false, false, false, false, true)
	var q_yaw := WizardMovementInput.compute_yaw_delta(q_keys, 1.0)
	var e_yaw := WizardMovementInput.compute_yaw_delta(e_keys, 1.0)
	test_assert.check(q_yaw > 0.0, "Q should yaw left (positive)")
	test_assert.check(e_yaw < 0.0, "E should yaw right (negative)")
