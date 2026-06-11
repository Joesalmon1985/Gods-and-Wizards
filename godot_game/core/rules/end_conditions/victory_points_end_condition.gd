class_name VictoryPointsEndCondition
extends RefCounted

static func check(state: GameState) -> Dictionary:
	for player in state.players:
		if player.victory_points >= GameConstants.VP_TO_WIN:
			return {
				"finished": true,
				"winner_id": player.id,
				"reason": "victory_points",
			}
	return {"finished": false}
