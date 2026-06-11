class_name TestEventLogReplay
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var result := GameSimulator.run(42, 2)
	var baseline: Dictionary = result["replay_baseline"]
	var log: EventLog = result["event_log"]
	var final_state: GameState = result["state"]

	_test_step_zero_baseline(test_assert, baseline, log)
	_test_city_built_replay(test_assert, baseline, log, final_state)
	_test_resource_gained_replay(test_assert, baseline, log)
	_test_controller_uses_replay(test_assert, result)


static func _test_step_zero_baseline(test_assert: TestAssert, baseline: Dictionary, log: EventLog) -> void:
	var view := EventLogReplay.build_view_at_step(baseline, log, 0)
	test_assert.eq(view["cities"].size(), 2, "step 0 should show initial city count")
	test_assert.eq(view["players"].size(), 2, "step 0 should show both players")

	var alice_resources: Dictionary = view["players"][0]["resources"]
	test_assert.eq(alice_resources.get("wood", -1), 4, "step 0 should show starting wood")
	test_assert.eq(view["step"], 0, "step 0 should report step index 0")


static func _test_city_built_replay(
	test_assert: TestAssert,
	baseline: Dictionary,
	log: EventLog,
	final_state: GameState
) -> void:
	var final_city_count: int = final_state.cities.size()
	var build_step := -1
	for i in range(log.entries.size()):
		if log.entries[i]["type"] == "city_built":
			build_step = i + 1
			break

	test_assert.check(build_step > 0, "simulation should log at least one city build")

	var before := EventLogReplay.build_view_at_step(baseline, log, build_step - 1)
	var after := EventLogReplay.build_view_at_step(baseline, log, build_step)
	test_assert.eq(
		after["cities"].size(),
		before["cities"].size() + 1,
		"replaying city_built should increase displayed city count"
	)
	test_assert.eq(
		final_state.cities.size(),
		final_city_count,
		"replaying must not mutate core GameState"
	)


static func _test_resource_gained_replay(test_assert: TestAssert, baseline: Dictionary, log: EventLog) -> void:
	var expected_totals := _starting_totals()
	for i in range(log.entries.size()):
		var entry: Dictionary = log.entries[i]
		var entry_type: String = entry["type"]
		var payload: Dictionary = entry.get("payload", {})

		if entry_type == "resource_gained":
			var player_id: int = payload.get("player_id", -1)
			var resource_key: String = payload.get("resource", "")
			var amount: int = payload.get("amount", 0)
			expected_totals[player_id][resource_key] = (
				expected_totals[player_id].get(resource_key, 0) + amount
			)
		elif entry_type == "city_built":
			_deduct_expected(expected_totals, payload.get("player_id", -1), BuildCosts.BUILD_CITY)

		if entry_type == "resource_gained":
			var view := EventLogReplay.build_view_at_step(baseline, log, i + 1)
			var player_id: int = payload.get("player_id", -1)
			var resource_key: String = payload.get("resource", "")
			var player_resources := _resources_for_player(view, player_id)
			test_assert.eq(
				player_resources.get(resource_key, 0),
				expected_totals[player_id].get(resource_key, 0),
				"replayed resources should match cumulative gains"
			)


static func _test_controller_uses_replay(test_assert: TestAssert, result: Dictionary) -> void:
	var controller := DebugGameController.new()
	controller.load_from_result(result)

	var step_zero := controller.current_view()
	test_assert.eq(step_zero["players"][0]["resources"].get("wood", -1), 4, "controller step 0 should use replay baseline")

	var final_wood: int = result["state"].players[0].get_resource(ResourceType.Type.WOOD)
	test_assert.check(
		final_wood != step_zero["players"][0]["resources"].get("wood", -1),
		"final state resources should differ from replayed step 0 when production ran"
	)

	while controller.can_step():
		controller.step_forward()
	var stepped := controller.current_view()
	test_assert.eq(
		stepped["players"][0]["resources"].get("wood", -1),
		final_wood,
		"controller at final step should match cumulative replay"
	)


static func _resources_for_player(view: Dictionary, player_id: int) -> Dictionary:
	for player in view["players"]:
		if player["id"] == player_id:
			return player["resources"]
	return {}


static func _deduct_expected(totals: Dictionary, player_id: int, costs: Dictionary) -> void:
	for resource in costs.keys():
		var key := ResourceType.to_key(resource)
		totals[player_id][key] = totals[player_id].get(key, 0) - costs[resource]


static func _starting_totals() -> Dictionary:
	var totals := {}
	for player_id in [0, 1]:
		totals[player_id] = {}
		for resource in ResourceType.all():
			totals[player_id][ResourceType.to_key(resource)] = ScenarioBuilder.STARTING_RESOURCES.get(resource, 0)
	return totals
