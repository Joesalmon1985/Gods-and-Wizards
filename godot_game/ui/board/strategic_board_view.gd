class_name StrategicBoardView
extends Node2D

## Read-only 2D strategic board view driven by BoardWorldMapper snapshots.

const HEX_SIZE := 16.0

var _snapshot: Dictionary = {}


func sync_from_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	queue_redraw()


func get_snapshot() -> Dictionary:
	return _snapshot


func compute_content_bounds() -> Rect2:
	if _snapshot.is_empty():
		return Rect2()
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	var margin := HEX_SIZE + 10.0
	for entry in _snapshot.get("hexes", []):
		var point := _axial_to_pixel(HexCoord.new(int(entry.get("q", 0)), int(entry.get("r", 0))))
		min_p = min_p.min(point)
		max_p = max_p.max(point)
	for entry in _snapshot.get("nodes", []):
		var point := _world_dict_to_pixel(entry.get("world", {}))
		min_p = min_p.min(point)
		max_p = max_p.max(point)
	if min_p.x == INF:
		return Rect2()
	min_p -= Vector2(margin, margin)
	max_p += Vector2(margin, margin)
	return Rect2(min_p, max_p - min_p)


func fit_to_container(container_size: Vector2, padding: float = 24.0) -> void:
	var bounds := compute_content_bounds()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or container_size.x <= 0.0 or container_size.y <= 0.0:
		scale = Vector2.ONE
		position = Vector2(padding, padding)
		return
	var available := container_size - Vector2(padding * 2.0, padding * 2.0)
	var scale_factor := minf(available.x / bounds.size.x, available.y / bounds.size.y)
	scale = Vector2(scale_factor, scale_factor)
	var scaled_size := bounds.size * scale_factor
	position = Vector2(
		padding + (available.x - scaled_size.x) * 0.5 - bounds.position.x * scale_factor,
		padding + (available.y - scaled_size.y) * 0.5 - bounds.position.y * scale_factor
	)


func _draw() -> void:
	if _snapshot.is_empty():
		return
	_draw_hexes(_snapshot.get("hexes", []))
	_draw_edges(_snapshot.get("edges", []))
	_draw_cities(_snapshot.get("cities", []))
	_draw_heroes(_snapshot.get("heroes", []))
	_draw_demons(_snapshot.get("demons", []))


func _draw_hexes(hexes: Array) -> void:
	for entry in hexes:
		var q: int = entry.get("q", 0)
		var r: int = entry.get("r", 0)
		var center := _axial_to_pixel(HexCoord.new(q, r))
		var chance: int = entry.get("max_production_chance", 0)
		var fill := _hex_fill_for_resource(str(entry.get("dominant_resource", "")), chance)
		_draw_hex_polygon(center, fill)


func _draw_edges(edges: Array) -> void:
	for entry in edges:
		var from_pos := _world_dict_to_pixel(entry.get("world_a", {}))
		var to_pos := _world_dict_to_pixel(entry.get("world_b", {}))
		var has_road: bool = entry.get("has_road", false)
		var owner_id: int = entry.get("road_owner_id", -1)
		var color := BoardWorldMapper.player_color(owner_id) if has_road else Color(0.35, 0.35, 0.35, 0.6)
		var width := 3.0 if has_road else 1.5
		draw_line(from_pos, to_pos, color, width)


func _draw_cities(cities: Array) -> void:
	for entry in cities:
		var node_id: String = entry.get("node_id", "")
		var center := _node_id_to_pixel(node_id)
		if center == Vector2.ZERO and node_id != "":
			continue
		var player_id: int = entry.get("player_id", -1)
		draw_circle(center, 6.0, BoardWorldMapper.player_color(player_id))
		var slot_count: int = int(entry.get("development_count", 0))
		if slot_count <= 0 and entry.get("development_id", "") != "":
			slot_count = 1
		for slot_index in range(slot_count):
			var offset := Vector2(5 + slot_index * 4, -5 - slot_index * 2)
			draw_circle(center + offset, 3.0, Color(0.95, 0.85, 0.25))
		var max_slots: int = int(entry.get("max_development_slots", DevelopmentRules.MAX_DEVELOPMENTS_PER_CITY))
		for free_index in range(slot_count, max_slots):
			var ghost_offset := Vector2(5 + free_index * 4, -5 - free_index * 2)
			draw_arc(center + ghost_offset, 2.5, 0.0, TAU, 12, Color(0.95, 0.85, 0.25, 0.35), 1.0)


func _hex_fill_for_resource(resource_key: String, chance: int) -> Color:
	var intensity := 0.25 + float(chance) / 9.0 * 0.35
	match resource_key:
		"wood":
			return Color(0.12, 0.35 + intensity, 0.12, 0.4)
		"brick":
			return Color(0.45 + intensity * 0.2, 0.18, 0.12, 0.4)
		"wheat":
			return Color(0.55 + intensity * 0.2, 0.5, 0.12, 0.4)
		"sheep":
			return Color(0.2, 0.55 + intensity * 0.2, 0.25, 0.4)
		"ore":
			return Color(0.25, 0.25, 0.35 + intensity * 0.2, 0.4)
		_:
			return Color(0.15, 0.25 + intensity, 0.15, 0.35)


func _draw_heroes(heroes: Array) -> void:
	for entry in heroes:
		var node_id: String = entry.get("node_id", "")
		var center := _node_id_to_pixel(node_id)
		if center == Vector2.ZERO:
			continue
		var player_id: int = entry.get("player_id", -1)
		draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), BoardWorldMapper.player_color(player_id).lightened(0.2))


func _draw_demons(demons: Array) -> void:
	for entry in demons:
		var node_id: String = entry.get("node_id", "")
		var center := _node_id_to_pixel(node_id)
		if center == Vector2.ZERO:
			continue
		var count: int = entry.get("count", 1)
		draw_circle(center + Vector2(-5, -5), 3.0 + float(count) * 0.5, Color(0.55, 0.08, 0.12))


func _node_id_to_pixel(node_id: String) -> Vector2:
	for entry in _snapshot.get("nodes", []):
		if entry.get("id", "") == node_id:
			return _world_dict_to_pixel(entry.get("world", {}))
	return Vector2.ZERO


func _world_dict_to_pixel(world: Dictionary) -> Vector2:
	var x := float(world.get("x", 0.0))
	var z := float(world.get("z", 0.0))
	return Vector2(x * 20.0, z * 20.0)


func _axial_to_pixel(coord: HexCoord) -> Vector2:
	var x := HEX_SIZE * sqrt(3.0) * (coord.q + coord.r / 2.0)
	var y := HEX_SIZE * 1.5 * coord.r
	return Vector2(x, y)


func _draw_hex_polygon(center: Vector2, fill: Color) -> void:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * HEX_SIZE)
	draw_colored_polygon(points, fill)
