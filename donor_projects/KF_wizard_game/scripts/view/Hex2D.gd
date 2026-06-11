extends Node2D
class_name Hex2D

@export var label: String = ""
@export var size: float = 64.0
@export var color: Color = Color(0.7,0.7,0.7)

func _ready() -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array(_hex_points(size))
	poly.color = color
	add_child(poly)

	var lbl := Label.new()
	lbl.text = label
	lbl.position = Vector2(-30,-10)
	add_child(lbl)

func _hex_points(s: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in range(6):
		var a := PI/6.0 + i * PI/3.0
		pts.append(Vector2(cos(a), sin(a)) * s)
	return pts

