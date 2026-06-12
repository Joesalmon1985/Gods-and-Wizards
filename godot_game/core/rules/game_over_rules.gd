class_name GameOverRules
extends RefCounted

static func evaluate(state: GameState) -> GameOverEvent:
	for player in state.players:
		var bonus := DevelopmentEffectEngine.end_game_vp_bonus(state, player.id)
		if bonus > 0:
			ScoreRules.grant_victory_points(state, player.id, bonus, "end_game_development")
	var checks: Array = [
		VictoryPointsEndCondition.check(state),
		BreachEndCondition.check(state),
	]
	for result in checks:
		if result.get("finished", false):
			return GameOverEvent.new(result["winner_id"], result["reason"])
	return null
