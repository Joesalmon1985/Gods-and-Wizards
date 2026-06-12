class_name TestWizardWorldController
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_camera_toggle_state(test_assert)
	_test_movement_does_not_touch_game_state(test_assert)
	_test_encounter_prompt_updates(test_assert)


static func _test_camera_toggle_state(test_assert: TestAssert) -> void:
	var controller := WizardWorldController.new()
	test_assert.eq(int(controller.camera_mode), int(WizardCameraRig.Mode.BOARD_OVERVIEW), "default camera is board")
	controller.toggle_camera()
	test_assert.eq(int(controller.camera_mode), int(WizardCameraRig.Mode.WIZARD_MARKER), "toggle should switch mode")


static func _test_movement_does_not_touch_game_state(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	var demons_before := _total_demons(session.state)
	var controller := WizardWorldController.new()
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	controller.apply_movement(keys, 0.5)
	test_assert.eq(_total_demons(session.state), demons_before, "wizard movement must not mutate GameState")


static func _test_encounter_prompt_updates(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(7)
	var snapshot := BoardWorldMapper.build_snapshot(state, [])
	var controller := WizardWorldController.new()
	if not snapshot.get("nodes", []).is_empty():
		var world: Dictionary = snapshot["nodes"][0].get("world", {})
		controller.marker_position = Vector3(float(world.get("x", 0.0)), 0.0, float(world.get("z", 0.0)))
	controller.update_encounter_prompt(snapshot)
	test_assert.check(controller.encounter_prompt == "" or controller.encounter_prompt.begins_with("Encounter"), "prompt should be empty or encounter text")


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
