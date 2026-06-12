class_name TurnPhase
extends RefCounted

enum Phase {
	ACTIVE_PLAYER,
	ROUND_START,
	GAME_OVER,
}


static func to_key(phase: Phase) -> String:
	match phase:
		Phase.ACTIVE_PLAYER:
			return "active_player"
		Phase.ROUND_START:
			return "round_start"
		Phase.GAME_OVER:
			return "game_over"
		_:
			return "unknown"
