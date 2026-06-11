extends Resource
class_name RoadSpaceModel

@export var key: Vector2i
@export var position: Vector2
@export var a: Vector2i
@export var b: Vector2i
@export var adjacent_hexes: Array[Vector2i] = []
@export var occupied_by: int = -1
@export var is_build_legal: bool = true
