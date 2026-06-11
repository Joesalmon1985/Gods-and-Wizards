class_name BotTurnResolver
extends RefCounted

const POLICY_RANDOM := "random"
const POLICY_HEURISTIC := "heuristic"


static func resolve_player_turn(
	state: GameState,
	event_log: EventLog = null,
	policy_name: String = POLICY_HEURISTIC
) -> Array:
	var events: Array = []

	while true:
		if event_log != null:
			var view := LegalActionQuery.get_view(state)
			event_log.append_legal_mask(
				view,
				state.round_number,
				TurnRules.get_active_player_id(state)
			)

		var choice := _choose_action(state, policy_name)
		var applied := ActionRules.apply(state, choice)
		for event in applied:
			events.append(event)
			if event_log != null:
				event_log.append(event)

		if choice.kind == ActionKind.Kind.END_TURN:
			break

	return events


static func _choose_action(state: GameState, policy_name: String) -> GameAction:
	if policy_name == POLICY_RANDOM:
		return RandomBotPolicy.choose_action(state)
	return HeuristicBotPolicy.choose_action(state)
