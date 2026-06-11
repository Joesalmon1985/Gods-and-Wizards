class_name TestActionSpaceRoads
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := SetupRules.create_game(42)
	var road_count := 0
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_ROAD:
			road_count += 1
			test_assert.check(action.edge != null, "BUILD_ROAD actions should carry edge payload")

	var edge_count := state.board.get_all_edges_sorted().size()
	test_assert.eq(road_count, edge_count, "each board edge should have one BUILD_ROAD slot")

	var road_ids: Array[int] = []
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_ROAD:
			road_ids.append(action.action_id)
	for i in range(road_ids.size() - 1):
		test_assert.check(
			road_ids[i] < road_ids[i + 1],
			"BUILD_ROAD action_ids should be strictly increasing"
		)
