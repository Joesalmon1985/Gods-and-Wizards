extends Node2D
class_name Robber2D

func _ready() -> void:
    print("[Robber2D] ready")

func move_to_axial(axial: Vector2i) -> void:
    print("[Robber2D] move_to_axial %s" % axial)
