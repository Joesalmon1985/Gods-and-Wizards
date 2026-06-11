extends Node2D
class_name RoadSpace2D

@export var a_local := Vector2.ZERO
@export var b_local := Vector2(40, 0)
@export var width := 4.0
@export var color := Color(0.85,0.85,0.85, 0.7)

func _draw() -> void:
	z_index = 0
	draw_line(a_local, b_local, color, width, true)
