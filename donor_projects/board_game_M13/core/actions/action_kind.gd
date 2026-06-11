class_name ActionKind
extends RefCounted

enum Kind {
	END_TURN,
	BUILD_CITY,
}


static func to_key(kind: Kind) -> String:
	match kind:
		Kind.END_TURN:
			return "end_turn"
		Kind.BUILD_CITY:
			return "build_city"
		_:
			return "unknown"
