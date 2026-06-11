class_name TestBoardNodeTopology
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var board_a := _empty_board_radius_3()
	var board_b := _empty_board_radius_3()

	var node_count := board_a.get_all_nodes_sorted().size()
	test_assert.check(node_count >= 54, "radius-3 board should have at least 54 nodes")
	test_assert.eq(
		board_a.get_all_nodes_sorted().size(),
		board_b.get_all_nodes_sorted().size(),
		"node count should be stable"
	)

	var state_a := SetupRules.create_game(42)
	var state_b := SetupRules.create_game(42)
	test_assert.eq(
		state_a.board.get_all_nodes_sorted().size(),
		state_b.board.get_all_nodes_sorted().size(),
		"generated boards should have stable node counts for same seed"
	)


static func _empty_board_radius_3() -> HexBoard:
	var board := HexBoard.new(3)
	for coord in HexBoard.coords_for_radius(3):
		board.add_tile(HexTile.new(coord))
	board.build_vertex_index()
	return board
