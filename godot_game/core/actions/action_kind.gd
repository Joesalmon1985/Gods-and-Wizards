class_name ActionKind
extends RefCounted

enum Kind {
	END_TURN,
	BUILD_CITY,
	BUILD_ROAD,
	MOVE_HERO,
	BUILD_DEVELOPMENT,
	BANK_TRADE,
	PLAYER_TRADE,
}


static func to_key(kind: Kind) -> String:
	match kind:
		Kind.END_TURN:
			return "end_turn"
		Kind.BUILD_CITY:
			return "build_city"
		Kind.BUILD_ROAD:
			return "build_road"
		Kind.MOVE_HERO:
			return "move_hero"
		Kind.BUILD_DEVELOPMENT:
			return "build_development"
		Kind.BANK_TRADE:
			return "bank_trade"
		Kind.PLAYER_TRADE:
			return "player_trade"
		_:
			return "unknown"
