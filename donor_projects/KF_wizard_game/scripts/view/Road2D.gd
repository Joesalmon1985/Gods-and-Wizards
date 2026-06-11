extends Node2D
class_name Road2D

@export var a_local := Vector2.ZERO
@export var b_local := Vector2(40, 0)
@export var width := 10.0
var _color: Color = Color(1,1,1,0.95)

func apply_owner(owner_color: Color) -> void:
	_color = owner_color
	z_index = 10
	queue_redraw()

func _draw() -> void:
	draw_line(a_local, b_local, _color, width, true)

