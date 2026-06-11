extends Resource
class_name CityModel

@export var owner_id: int = -1
@export var vertex_key: Vector2i

func _init() -> void:
    print("[CityModel] created with owner=%s vertex=%s" % [owner_id, vertex_key])
