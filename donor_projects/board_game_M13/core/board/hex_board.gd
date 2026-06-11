class_name HexBoard
extends RefCounted

var radius: int = 0
var tiles: Dictionary = {}
var _vertices: Dictionary = {}
var _hex_vertices: Dictionary = {}


func _init(p_radius: int = 0) -> void:
	radius = p_radius


func add_tile(tile: HexTile) -> void:
	tiles[tile.coord.to_key()] = tile


func has_hex(coord: HexCoord) -> bool:
	return tiles.has(coord.to_key())


func get_tile(coord: HexCoord) -> HexTile:
	return tiles[coord.to_key()]


func get_all_coords_sorted() -> Array[HexCoord]:
	var coords: Array[HexCoord] = []
	for key in tiles.keys():
		coords.append(tiles[key].coord)
	coords.sort_custom(func(a: HexCoord, b: HexCoord) -> bool:
		return a.sort_key() < b.sort_key()
	)
	return coords


func build_vertex_index() -> void:
	_vertices.clear()
	_hex_vertices.clear()

	for key in tiles.keys():
		var hex: HexCoord = tiles[key].coord
		var hex_vertex_keys: Array[String] = []

		for corner in range(6):
			var vertex := VertexCoord.from_hex_corner(hex, corner)
			var vertex_key := vertex.to_key()
			hex_vertex_keys.append(vertex_key)

			if not _vertices.has(vertex_key):
				_vertices[vertex_key] = {
					"vertex": vertex,
					"hexes": [],
				}

			var entry: Dictionary = _vertices[vertex_key]
			var hexes: Array = entry["hexes"]
			if not _hex_list_contains(hexes, hex):
				hexes.append(hex)

		_hex_vertices[hex.to_key()] = hex_vertex_keys


func has_vertex(vertex: VertexCoord) -> bool:
	return _vertices.has(vertex.to_key())


func get_vertices_for_hex(coord: HexCoord) -> Array[VertexCoord]:
	var result: Array[VertexCoord] = []
	var hex_key := coord.to_key()
	if not _hex_vertices.has(hex_key):
		return result

	for vertex_key in _hex_vertices[hex_key]:
		result.append(_vertices[vertex_key]["vertex"])
	return result


func get_hexes_for_vertex(vertex: VertexCoord) -> Array[HexCoord]:
	var result: Array[HexCoord] = []
	var vertex_key := vertex.to_key()
	if not _vertices.has(vertex_key):
		return result

	var hexes: Array = _vertices[vertex_key]["hexes"]
	for hex in hexes:
		if has_hex(hex):
			result.append(hex)

	result.sort_custom(func(a: HexCoord, b: HexCoord) -> bool:
		return a.sort_key() < b.sort_key()
	)
	return result


func get_all_vertices_sorted() -> Array[VertexCoord]:
	var vertices: Array[VertexCoord] = []
	for key in _vertices.keys():
		vertices.append(_vertices[key]["vertex"])
	vertices.sort_custom(func(a: VertexCoord, b: VertexCoord) -> bool:
		return a.to_key() < b.to_key()
	)
	return vertices


static func coords_for_radius(board_radius: int) -> Array[HexCoord]:
	var coords: Array[HexCoord] = []
	for q in range(-board_radius, board_radius + 1):
		var r_min := maxi(-board_radius, -q - board_radius)
		var r_max := mini(board_radius, -q + board_radius)
		for r in range(r_min, r_max + 1):
			coords.append(HexCoord.new(q, r))
	coords.sort_custom(func(a: HexCoord, b: HexCoord) -> bool:
		return a.sort_key() < b.sort_key()
	)
	return coords


static func _hex_list_contains(hexes: Array, coord: HexCoord) -> bool:
	for hex in hexes:
		if hex.equals(coord):
			return true
	return false
