class_name ResourceType
extends RefCounted

enum Type {
	WOOD,
	BRICK,
	WHEAT,
	SHEEP,
	ORE,
}


static func all() -> Array:
	return [
		Type.WOOD,
		Type.BRICK,
		Type.WHEAT,
		Type.SHEEP,
		Type.ORE,
	]


static func to_key(resource: Type) -> String:
	match resource:
		Type.WOOD:
			return "wood"
		Type.BRICK:
			return "brick"
		Type.WHEAT:
			return "wheat"
		Type.SHEEP:
			return "sheep"
		Type.ORE:
			return "ore"
		_:
			return "unknown"
