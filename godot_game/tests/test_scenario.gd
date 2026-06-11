class_name TestScenario
extends RefCounted

static func build_standard_game(game_seed: int) -> GameState:
	return ScenarioBuilder.build_standard_game(game_seed)


static func build_bot_ready_game(game_seed: int) -> GameState:
	return ScenarioBuilder.build_bot_ready_game(game_seed)


static func run_production_rounds(state: GameState, rounds: int) -> Array:
	var all_events: Array = []
	for _i in range(rounds):
		all_events.append_array(ProductionRules.resolve_start_of_turn_production(state))
	return all_events


static func prepare_first_legal_city_build(state: GameState, max_road_builds: int = 20) -> GameAction:
	var player := TurnRules.get_active_player(state)
	SetupRules.grant_resources(state, player.id, {
		ResourceType.Type.WOOD: max_road_builds + BuildCosts.BUILD_CITY[ResourceType.Type.WOOD],
		ResourceType.Type.BRICK: max_road_builds + BuildCosts.BUILD_CITY[ResourceType.Type.BRICK],
		ResourceType.Type.WHEAT: BuildCosts.BUILD_CITY[ResourceType.Type.WHEAT],
	})

	for _attempt in range(max_road_builds):
		for action in LegalActionQuery.get_legal_actions_sorted(state):
			if action.kind == ActionKind.Kind.BUILD_CITY:
				return action
		var built_road := false
		for action in LegalActionQuery.get_legal_actions_sorted(state):
			if action.kind == ActionKind.Kind.BUILD_ROAD:
				ActionRules.apply(state, action)
				built_road = true
				break
		if not built_road:
			return null
	return null
