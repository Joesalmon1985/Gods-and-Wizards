class_name BreachEndCondition
extends RefCounted

static func check(state: GameState) -> Dictionary:
	if state.breach_count >= GameConstants.BREACH_LIMIT:
		return {
			"finished": true,
			"winner_id": -1,
			"reason": "breach",
		}
	return {"finished": false}
