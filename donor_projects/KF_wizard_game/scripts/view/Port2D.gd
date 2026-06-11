extends Node2D
class_name Port2D

func _ready() -> void:
    print("[Port2D] ready")

func setup(kind: String, rate: int) -> void:
    print("[Port2D] setup kind=%s rate=%s" % [kind, rate])
