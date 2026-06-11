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
