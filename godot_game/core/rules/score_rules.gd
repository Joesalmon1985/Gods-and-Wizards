class_name ScoreRules
extends RefCounted

static func apply_city_victory_points(state: GameState, player_id: int) -> Array:
	return grant_victory_points(state, player_id, GameConstants.VP_PER_CITY, "city_built")


static func grant_victory_points(
	state: GameState,
	player_id: int,
	amount: int,
	reason: String
) -> Array:
	var player := _get_player(state, player_id)
	if player == null or amount <= 0:
		return []

	player.victory_points += amount
	return [VictoryPointsChangedEvent.new(player_id, amount, player.victory_points, reason)]


static func _get_player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
