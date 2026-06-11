class_name BuildCosts
extends RefCounted

const BUILD_CITY := {
	ResourceType.Type.WOOD: 2,
	ResourceType.Type.BRICK: 1,
	ResourceType.Type.WHEAT: 1,
	ResourceType.Type.SHEEP: 0,
	ResourceType.Type.ORE: 0,
}


static func can_afford(player: Player, costs: Dictionary) -> bool:
	if player == null:
		return false
	for resource in costs.keys():
		if player.get_resource(resource) < costs[resource]:
			return false
	return true
