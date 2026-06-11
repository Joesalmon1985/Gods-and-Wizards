extends Node2D

const HEX_SIZE := 18.0

var _board: HexBoard = null
var _cities: Array = []
var _active_player_id: int = -1


func set_board_state(board: HexBoard, cities: Array, active_player_id: int = -1) -> void:
	_board = board
	_cities = cities
	_active_player_id = active_player_id
	queue_redraw()


func _draw() -> void:
	if _board == null:
		return

	for coord in _board.get_all_coords_sorted():
		var tile := _board.get_tile(coord)
		var tint_strength := _production_tint_strength(tile)
		var fill := Color(0.15, 0.25 + tint_strength * 0.35, 0.15, 0.35)
		_draw_hex(_axial_to_pixel(coord), fill)

	for city_data in _cities:
		var vertex_key: String = city_data.get("vertex_key", "")
		var center := _vertex_key_to_pixel(vertex_key)
		var player_id: int = city_data.get("player_id", 0)
		var color := Color.CORAL if player_id == 0 else Color.SKY_BLUE
		var radius := 7.0 if player_id == _active_player_id else 5.0
		draw_circle(center, radius, color)
		if player_id == _active_player_id:
			draw_arc(center, radius + 2.0, 0.0, TAU, 24, Color.WHITE, 1.5)


func _production_tint_strength(tile: HexTile) -> float:
	var peak := 0
	for resource in ResourceType.all():
		peak = maxi(peak, tile.get_production_chance(resource))
	return float(peak) / 9.0


func _axial_to_pixel(coord: HexCoord) -> Vector2:
	var x := HEX_SIZE * sqrt(3.0) * (coord.q + coord.r / 2.0)
	var y := HEX_SIZE * 1.5 * coord.r
	return Vector2(x, y)


func _vertex_key_to_pixel(vertex_key: String) -> Vector2:
	for vertex in _board.get_all_vertices_sorted():
		if vertex.to_key() == vertex_key:
			var hexes := _board.get_hexes_for_vertex(vertex)
			if hexes.is_empty():
				return Vector2.ZERO
			var sum := Vector2.ZERO
			for hex in hexes:
				sum += _axial_to_pixel(hex)
			return sum / float(hexes.size())
	return Vector2.ZERO


func _draw_hex(center: Vector2, fill: Color) -> void:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * HEX_SIZE)
	draw_colored_polygon(points, fill)
