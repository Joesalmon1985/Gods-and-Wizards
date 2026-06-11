class_name TestEdgeTopology
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var board := _empty_board_radius_3()
	var edges := board.get_all_edges_sorted()
	test_assert.check(edges.size() > 0, "board should have edges")

	for edge in edges:
		test_assert.check(edge.node_a != null, "edge should have node_a")
		test_assert.check(edge.node_b != null, "edge should have node_b")
		test_assert.check(
			not edge.node_a.equals(edge.node_b),
			"edge endpoints should differ"
		)
		test_assert.check(board.has_edge(edge), "edge should be indexed")

	for node in board.get_all_nodes_sorted():
		var degree := board.node_degree(node)
		test_assert.check(degree >= 1, "interior/coastal nodes should have at least one edge")
		test_assert.check(degree <= 3, "hex corner nodes should have at most 3 edges")


static func _empty_board_radius_3() -> HexBoard:
	var board := HexBoard.new(3)
	for coord in HexBoard.coords_for_radius(3):
		board.add_tile(HexTile.new(coord))
	board.build_vertex_index()
	return board
