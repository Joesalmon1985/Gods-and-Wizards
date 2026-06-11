extends Resource
class_name PortModel

@export var kind: String = "ANY"   # "WOOD", "BRICK", or "ANY"
@export var rate: int = 3
@export var connected_vertices: Array[Vector2i] = []

func _init() -> void:
    print("[PortModel] created kind=%s rate=%s verts=%s" % [kind, rate, connected_vertices])
