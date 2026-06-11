class_name HexBoard
extends RefCounted

var radius: int = 0
var tiles: Dictionary = {}
var _vertices: Dictionary = {}
var _hex_vertices: Dictionary = {}
var _edges: Dictionary = {}
var _node_edges: Dictionary = {}


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
	_edges.clear()
	_node_edges.clear()

	for key in tiles.keys():
		var hex: HexCoord = tiles[key].coord
		var hex_vertex_keys: Array[String] = []

		for corner in range(6):
			var vertex := BoardNode.from_hex_corner(hex, corner)
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

	_build_edge_index()


func _build_edge_index() -> void:
	for key in tiles.keys():
		var hex: HexCoord = tiles[key].coord
		for corner in range(6):
			var node_a := BoardNode.from_hex_corner(hex, corner)
			var node_b := BoardNode.from_hex_corner(hex, (corner + 1) % 6)
			if not has_vertex(node_a) or not has_vertex(node_b):
				continue
			_register_edge(node_a, node_b)


func _register_edge(node_a: BoardNode, node_b: BoardNode) -> void:
	var edge := EdgeCoord.from_nodes(node_a, node_b)
	var edge_key := edge.to_key()
	if _edges.has(edge_key):
		return
	_edges[edge_key] = edge
	_append_node_edge(node_a.to_key(), edge_key)
	_append_node_edge(node_b.to_key(), edge_key)


func _append_node_edge(node_key: String, edge_key: String) -> void:
	if not _node_edges.has(node_key):
		_node_edges[node_key] = []
	var edge_keys: Array = _node_edges[node_key]
	if edge_key not in edge_keys:
		edge_keys.append(edge_key)


func has_vertex(vertex: BoardNode) -> bool:
	return _vertices.has(vertex.to_key())


func has_node(node: BoardNode) -> bool:
	return has_vertex(node)


func has_edge(edge: EdgeCoord) -> bool:
	return _edges.has(edge.to_key())


func get_vertices_for_hex(coord: HexCoord) -> Array[BoardNode]:
	var result: Array[BoardNode] = []
	var hex_key := coord.to_key()
	if not _hex_vertices.has(hex_key):
		return result

	for vertex_key in _hex_vertices[hex_key]:
		result.append(_vertices[vertex_key]["vertex"])
	return result


func get_hexes_for_vertex(vertex: BoardNode) -> Array[HexCoord]:
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


func get_all_vertices_sorted() -> Array[BoardNode]:
	var vertices: Array[BoardNode] = []
	for key in _vertices.keys():
		vertices.append(_vertices[key]["vertex"])
	vertices.sort_custom(func(a: BoardNode, b: BoardNode) -> bool:
		return a.to_key() < b.to_key()
	)
	return vertices


func get_all_nodes_sorted() -> Array[BoardNode]:
	return get_all_vertices_sorted()


func get_all_edges_sorted() -> Array[EdgeCoord]:
	var edges: Array[EdgeCoord] = []
	for key in _edges.keys():
		edges.append(_edges[key])
	edges.sort_custom(func(a: EdgeCoord, b: EdgeCoord) -> bool:
		return a.to_key() < b.to_key()
	)
	return edges


func get_edges_for_node(node: BoardNode) -> Array[EdgeCoord]:
	var result: Array[EdgeCoord] = []
	var node_key := node.to_key()
	if not _node_edges.has(node_key):
		return result
	for edge_key in _node_edges[node_key]:
		result.append(_edges[edge_key])
	result.sort_custom(func(a: EdgeCoord, b: EdgeCoord) -> bool:
		return a.to_key() < b.to_key()
	)
	return result


func get_adjacent_nodes(node: BoardNode) -> Array[BoardNode]:
	var result: Array[BoardNode] = []
	for edge in get_edges_for_node(node):
		var other := edge.other_node(node)
		if other != null:
			result.append(other)
	result.sort_custom(func(a: BoardNode, b: BoardNode) -> bool:
		return a.to_key() < b.to_key()
	)
	return result


func node_degree(node: BoardNode) -> int:
	return get_edges_for_node(node).size()


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
