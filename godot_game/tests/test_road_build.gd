class_name TestRoadBuild
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	var city_vertex := state.cities[0].vertex
	var edge := _first_buildable_edge(state, player.id, city_vertex)
	test_assert.check(edge != null, "scenario should expose a buildable road")

	var action := _road_action_for_edge(state, edge)
	test_assert.check(action != null, "action space should contain road action")

	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 1, "road build should emit one event")
	test_assert.check(events[0] is RoadBuiltEvent, "road build should emit RoadBuiltEvent")
	test_assert.check(state.roads_by_edge.has(edge.to_key()), "road should be stored on state")


static func _first_buildable_edge(state: GameState, player_id: int, node: BoardNode) -> EdgeCoord:
	for edge in state.board.get_edges_for_node(node):
		if BuildRules.can_build_road(state, player_id, edge):
			return edge
	return null


static func _road_action_for_edge(state: GameState, edge: EdgeCoord) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_ROAD and action.edge.equals(edge):
			return action
	return null
