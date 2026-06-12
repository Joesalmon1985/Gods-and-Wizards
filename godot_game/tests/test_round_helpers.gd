class_name TestRoundHelpers
extends RefCounted

static func apply_full_round_wrap(state: GameState) -> void:
	var end_turn := state.action_space.get_action(0)
	for _i in state.players.size():
		ActionRules.apply(state, end_turn)
	DraftRules.complete_automatic_draft_for_bots(state)
