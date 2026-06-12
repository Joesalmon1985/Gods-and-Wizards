class_name GameStartRules
extends RefCounted

static func start_game(state: GameState) -> Array:
	SpreadRules.initialize_deck(state)
	DraftRules.initialize_for_game(state)
	var events: Array = [RoundStartedEvent.new(state.round_number)]
	TurnLifecycleRules.on_round_start(state)
	state.turn_number = 1
	state.turn_scope_flags.clear()
	events.append_array(TurnLifecycleRules.on_turn_start(state))
	return events
