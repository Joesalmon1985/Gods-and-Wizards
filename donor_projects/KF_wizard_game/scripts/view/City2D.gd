extends Node2D
class_name City2D

@export var size := 24.0        # overall icon size
var _color: Color = Color.WHITE

func apply_owner(owner_color: Color) -> void:
	_color = owner_color
	z_index = 10                  # draw on top of spaces
	queue_redraw()

func _draw() -> void:
	# simple “house” icon: square + roof
	var s := size
	var half := s * 0.8
	# body
	draw_rect(Rect2(Vector2(-half, -half * 0.6), Vector2(s, s * 0.8)), _color, true)
	# roof (triangle)
	var roof := PackedVector2Array([Vector2(-half, -half*0.6), Vector2(0, -s), Vector2(half, -half*0.6)])
	draw_polygon(roof, PackedColorArray([_color, _color, _color]))
	# outline
	var k := Color(0,0,0,0.9)
	draw_polyline(roof + PackedVector2Array([roof[0]]), k, 2.0, true)
	draw_rect(Rect2(Vector2(-half, -half * 0.6), Vector2(s, s * 0.8)), k, false, 2.0)
