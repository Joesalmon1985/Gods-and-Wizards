extends Node2D
class_name SettlementSpace2D

@export var radius := 7.0
@export var legal_color := Color(1,1,1,0.9)
@export var illegal_color := Color(0.6,0.6,0.6,0.35)
@export var outline := Color(0,0,0)
@export var outline_width := 2.0

var _current_color: Color = legal_color

func apply_state(is_legal: bool) -> void:
	_current_color = legal_color if is_legal else illegal_color
	z_index = 0
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _current_color)
	draw_circle(Vector2.ZERO, radius, outline, outline_width)
