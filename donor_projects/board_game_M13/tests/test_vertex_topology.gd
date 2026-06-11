class_name TestVertexTopology
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var board := _empty_board_radius_3()

	var center_hex := HexCoord.new(0, 0)
	var center_vertices := board.get_vertices_for_hex(center_hex)
	test_assert.eq(center_vertices.size(), 6, "center hex should have 6 vertices")

	var interior_vertex := VertexCoord.from_hex_corner(HexCoord.new(0, 0), 0)
	var interior_hexes := board.get_hexes_for_vertex(interior_vertex)
	test_assert.eq(interior_hexes.size(), 3, "interior vertex should touch 3 hexes")

	var edge_hex := HexCoord.new(3, 0)
	var edge_vertex := VertexCoord.from_hex_corner(edge_hex, 0)
	var edge_hexes := board.get_hexes_for_vertex(edge_vertex)
	test_assert.eq(edge_hexes.size(), 2, "edge vertex should touch 2 hexes")

	var corner_vertices: Array[VertexCoord] = []
	var edge_vertices: Array[VertexCoord] = []
	for vertex in board.get_all_vertices_sorted():
		var touching := board.get_hexes_for_vertex(vertex)
		if touching.size() == 1:
			corner_vertices.append(vertex)
		elif touching.size() == 2:
			edge_vertices.append(vertex)

	test_assert.check(corner_vertices.size() >= 6, "board should have corner vertices touching 1 hex")
	test_assert.check(edge_vertices.size() > 0, "board should have edge vertices touching 2 hexes")

	for coord in board.get_all_coords_sorted():
		for corner in range(6):
			var vertex := VertexCoord.from_hex_corner(coord, corner)
			var from_hex := board.get_vertices_for_hex(coord)
			var found := false
			for listed in from_hex:
				if listed.equals(vertex):
					found = true
					break
			test_assert.check(found, "vertex index should list corners for each hex")

			var touching := board.get_hexes_for_vertex(vertex)
			for touching_hex in touching:
				test_assert.check(
					board.has_hex(touching_hex),
					"vertex hex references should stay on board"
				)


static func _empty_board_radius_3() -> HexBoard:
	var board := HexBoard.new(3)
	for coord in HexBoard.coords_for_radius(3):
		board.add_tile(HexTile.new(coord))
	board.build_vertex_index()
	return board
