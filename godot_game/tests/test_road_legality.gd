class_name TestRoadLegality
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	var view := LegalActionQuery.get_view(state)

	var legal_road_count := 0
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_ROAD:
			continue
		if view.legal_mask[action.action_id]:
			legal_road_count += 1
			test_assert.check(
				not state.roads_by_edge.has(action.edge.to_key()),
				"legal road slot should be empty"
			)
			test_assert.check(
				BuildCosts.can_afford(player, BuildCosts.BUILD_ROAD),
				"legal road should be affordable"
			)

	test_assert.check(legal_road_count > 0, "player should have at least one legal road near city")

	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_ROAD:
			continue
		state.roads_by_edge[action.edge.to_key()] = Road.new(99, action.edge)
	var view_after := LegalActionQuery.get_view(state)
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_ROAD:
			test_assert.check(
				not view_after.legal_mask[action.action_id],
				"occupied road edges should be illegal"
			)
