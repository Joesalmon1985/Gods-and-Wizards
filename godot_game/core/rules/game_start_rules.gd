class_name GameStartRules
extends RefCounted

static func start_game(state: GameState) -> Array:
	var events: Array = [RoundStartedEvent.new(state.round_number)]
	events.append_array(ProductionRules.resolve_round_production(state))
	return events
