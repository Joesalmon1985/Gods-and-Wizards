class_name TestDevelopmentBuild
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	SetupRules.grant_resources(state, player.id, {
		ResourceType.Type.WOOD: 0,
		ResourceType.Type.BRICK: 0,
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})

	GameStartRules.start_game(state)
	player.development_hand.append(DevelopmentRules.DEFAULT_DEVELOPMENT_ID)
	SetupRules.rebuild_action_space(state)
	var city_vertex := state.cities[0].vertex
	var action := _development_action(state, city_vertex, DevelopmentRules.DEFAULT_DEVELOPMENT_ID)
	test_assert.check(action != null, "development action should exist for city")

	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 1, "development build should emit one event")
	test_assert.check(events[0] is DevelopmentBuiltEvent, "should emit DevelopmentBuiltEvent")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.development_id, DevelopmentRules.DEFAULT_DEVELOPMENT_ID, "city should store development")


static func _development_action(
	state: GameState,
	vertex: BoardNode,
	development_id: String
) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if (
			action.kind == ActionKind.Kind.BUILD_DEVELOPMENT
			and action.vertex.equals(vertex)
			and action.development_id == development_id
		):
			return action
	return null
