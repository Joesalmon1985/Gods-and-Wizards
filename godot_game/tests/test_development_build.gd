class_name TestDevelopmentBuild
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	SetupRules.grant_resources(state, player.id, {
		ResourceType.Type.WHEAT: 2,
	})

	GameStartRules.start_game(state)
	var card_id := "lumber_camp_a1"
	player.development_hand.append(card_id)
	SetupRules.rebuild_action_space(state)
	var city_vertex := state.cities[0].vertex
	var action := _development_action(state, city_vertex, card_id)
	test_assert.check(action != null, "development action should exist for city")

	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 1, "development build should emit one event")
	test_assert.check(events[0] is DevelopmentBuiltEvent, "should emit DevelopmentBuiltEvent")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.development_id, card_id, "city should store development")


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
