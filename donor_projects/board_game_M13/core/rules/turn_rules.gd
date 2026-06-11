class_name TurnRules
extends RefCounted

static func get_active_player_id(state: GameState) -> int:
	return state.active_player_index


static func get_active_player(state: GameState) -> Player:
	if state.players.is_empty():
		return null
	if state.active_player_index < 0 or state.active_player_index >= state.players.size():
		return null
	return state.players[state.active_player_index]


static func player_count(state: GameState) -> int:
	return state.players.size()
