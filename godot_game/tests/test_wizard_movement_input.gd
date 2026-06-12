class_name TestWizardMovementInput
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_yaw_relative_forward_at_zero(test_assert)
	_test_yaw_relative_forward_at_half_pi(test_assert)
	_test_strafe_relative_to_yaw(test_assert)
	_test_qe_yaw(test_assert)
	_test_movement_does_not_mutate_game_state(test_assert)


static func _test_yaw_relative_forward_at_zero(test_assert: TestAssert) -> void:
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	var delta := WizardMovementInput.compute_move_delta(keys, 1.0, 1.0, 0.0)
	var forward := WizardOrientation.forward(0.0)
	test_assert.check(delta.dot(forward) > 0.9, "at yaw 0 W should move along forward vector")


static func _test_yaw_relative_forward_at_half_pi(test_assert: TestAssert) -> void:
	var yaw := PI * 0.5
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	var delta := WizardMovementInput.compute_move_delta(keys, 1.0, 1.0, yaw)
	var forward := WizardOrientation.forward(yaw)
	test_assert.check(delta.dot(forward) > 0.9, "at yaw pi/2 W should move along yaw forward")


static func _test_strafe_relative_to_yaw(test_assert: TestAssert) -> void:
	var yaw := 0.0
	var d_keys := WizardMovementInput.keys_from_pressed(false, false, false, true, false, false)
	var a_keys := WizardMovementInput.keys_from_pressed(false, true, false, false, false, false)
	var d_delta := WizardMovementInput.compute_move_delta(d_keys, 1.0, 1.0, yaw)
	var a_delta := WizardMovementInput.compute_move_delta(a_keys, 1.0, 1.0, yaw)
	var right := WizardOrientation.right(yaw)
	test_assert.check(d_delta.dot(right) > 0.9, "D should strafe along right vector")
	test_assert.check(a_delta.dot(-right) > 0.9, "A should strafe along negative right vector")


static func _test_qe_yaw(test_assert: TestAssert) -> void:
	var q_keys := WizardMovementInput.keys_from_pressed(false, false, false, false, true, false)
	var e_keys := WizardMovementInput.keys_from_pressed(false, false, false, false, false, true)
	var q_yaw := WizardMovementInput.compute_yaw_delta(q_keys, 1.0)
	var e_yaw := WizardMovementInput.compute_yaw_delta(e_keys, 1.0)
	test_assert.check(q_yaw > 0.0, "Q should yaw left (positive)")
	test_assert.check(e_yaw < 0.0, "E should yaw right (negative)")


static func _test_movement_does_not_mutate_game_state(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	var demons_before := _total_demons(session.state)
	var controller := WizardWorldController.new()
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	controller.apply_movement(keys, 0.5)
	test_assert.eq(_total_demons(session.state), demons_before, "wizard movement must not mutate GameState")


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
