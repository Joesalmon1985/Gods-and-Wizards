class_name TurnPhase
extends RefCounted

enum Phase {
	PRODUCTION,
	ACTIVE_PLAYER,
	ROUND_START,
	DRAFT_ROUND,
	GAME_OVER,
}


static func to_key(phase: Phase) -> String:
	match phase:
		Phase.PRODUCTION:
			return "production"
		Phase.ACTIVE_PLAYER:
			return "active_player"
		Phase.ROUND_START:
			return "round_start"
		Phase.DRAFT_ROUND:
			return "draft_round"
		Phase.GAME_OVER:
			return "game_over"
		_:
			return "unknown"
