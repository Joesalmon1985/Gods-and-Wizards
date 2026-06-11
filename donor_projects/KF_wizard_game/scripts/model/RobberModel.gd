extends Resource
class_name RobberModel

@export var axial: Vector2i = Vector2i.ZERO

func _init() -> void:
    print("[RobberModel] created at axial=%s" % axial)
