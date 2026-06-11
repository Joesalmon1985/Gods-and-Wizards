extends Resource
class_name SettlementSpaceModel

@export var key: Vector2i
@export var position: Vector2
@export var adjacent_hexes: Array[Vector2i] = []
@export var occupied_by: int = -1
@export var is_build_legal: bool = true
