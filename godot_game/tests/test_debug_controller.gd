class_name TestDebugController
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var result := GameSimulator.run(42, 2)
	var controller := DebugGameController.new()
	controller.load_from_result(result)

	var view := controller.current_view()
	test_assert.check(view.has("players"), "current view should expose players")
	test_assert.check(view.has("events_text"), "current view should expose events text")
	test_assert.check(view.has("board"), "current view should expose board data")

	var city_count: int = result["state"].cities.size()
	controller.step_forward()
	controller.step_forward()
	test_assert.eq(
		result["state"].cities.size(),
		city_count,
		"stepping the controller must not mutate simulation state"
	)

	test_assert.check(controller.current_view()["step"] > 0, "step_forward should advance step index")

	controller.load_from_result(result)
	var replay_at_start := controller.current_view()
	test_assert.eq(
		replay_at_start["players"][0]["resources"].get("wood", -1),
		4,
		"controller should replay starting resources at step 0"
	)
