class_name GameOverRules
extends RefCounted

static func evaluate(state: GameState) -> GameOverEvent:
	var checks: Array = [
		VictoryPointsEndCondition.check(state),
		BreachEndCondition.check(state),
	]
	for result in checks:
		if result.get("finished", false):
			return GameOverEvent.new(result["winner_id"], result["reason"])
	return null
