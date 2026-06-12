class_name GameStartRules
extends RefCounted

static func start_game(state: GameState) -> Array:
	SpreadRules.initialize_deck(state)
	DraftRules.initialize_for_game(state)
	var events: Array = [RoundStartedEvent.new(state.round_number)]
	TurnLifecycleRules.on_round_start(state)
	events.append_array(ProductionRules.resolve_round_production(state))
	TurnLifecycleRules.begin_game(state)
	return events
