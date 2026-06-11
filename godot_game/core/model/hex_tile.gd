class_name HexTile
extends RefCounted

var coord: HexCoord
var production: Dictionary = {}


func _init(p_coord: HexCoord) -> void:
	coord = p_coord
	for resource in ResourceType.all():
		production[resource] = 0


func get_production_chance(resource: ResourceType.Type) -> int:
	return production.get(resource, 0)
