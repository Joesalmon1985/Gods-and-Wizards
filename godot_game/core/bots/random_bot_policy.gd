class_name RandomBotPolicy
extends RefCounted

static func choose_action(state: GameState) -> GameAction:
	var legal := LegalActionQuery.get_legal_actions_sorted(state)
	var non_pass: Array[GameAction] = []
	for action in legal:
		if action.kind != ActionKind.Kind.END_TURN:
			non_pass.append(action)

	if non_pass.is_empty():
		return state.action_space.get_action(0)

	var index := state.rng.randi_range(0, non_pass.size() - 1)
	return non_pass[index]
