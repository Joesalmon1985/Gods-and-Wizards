class_name TestBoardWorldMapper
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	_test_deterministic_snapshot(test_assert, session.state, session.events)
	_test_valid_core_ids(test_assert, session.state)
	_test_snapshot_updates_after_turn(test_assert)


static func _test_deterministic_snapshot(test_assert: TestAssert, state: GameState, events: Array) -> void:
	var first := JSON.stringify(BoardWorldMapper.build_snapshot(state, events))
	var second := JSON.stringify(BoardWorldMapper.build_snapshot(state, events))
	test_assert.eq(first, second, "board world mapper should be deterministic for same state")


static func _test_valid_core_ids(test_assert: TestAssert, state: GameState) -> void:
	var snapshot := BoardWorldMapper.build_snapshot(state, [])
	var hex_keys := {}
	for coord in state.board.get_all_coords_sorted():
		hex_keys[coord.to_key()] = true
	for entry in snapshot.get("hexes", []):
		test_assert.check(hex_keys.has(entry.get("id", "")), "hex visual id should map to core hex")

	var node_keys := {}
	for node in state.board.get_all_nodes_sorted():
		node_keys[node.to_key()] = true
	for entry in snapshot.get("nodes", []):
		test_assert.check(node_keys.has(entry.get("id", "")), "node visual id should map to core board node")

	var edge_keys := {}
	for edge in state.board.get_all_edges_sorted():
		edge_keys[edge.to_key()] = true
	for entry in snapshot.get("edges", []):
		test_assert.check(edge_keys.has(entry.get("id", "")), "edge visual id should map to core edge")
		test_assert.check(
			node_keys.has(entry.get("node_a_id", "")),
			"edge endpoint A should map to core node"
		)
		test_assert.check(
			node_keys.has(entry.get("node_b_id", "")),
			"edge endpoint B should map to core node"
		)

	for entry in snapshot.get("cities", []):
		var node_id: String = entry.get("node_id", "")
		test_assert.check(state.cities_by_vertex.has(node_id), "city visual should map to core city node")
		if str(entry.get("development_id", "")) != "":
			var city: City = state.cities_by_vertex[node_id]
			test_assert.eq(
				entry.get("development_id", ""),
				city.development_id,
				"snapshot should expose city development_id"
			)

	for entry in snapshot.get("roads", []):
		var edge_id: String = entry.get("edge_id", "")
		test_assert.check(state.roads_by_edge.has(edge_id), "road visual should map to core road edge")

	for entry in snapshot.get("heroes", []):
		var hero_id: int = entry.get("hero_id", -1)
		test_assert.check(state.heroes_by_id.has(hero_id), "hero visual should map to core hero")
		test_assert.check(
			node_keys.has(entry.get("node_id", "")),
			"hero visual node should map to core board node"
		)

	for entry in snapshot.get("demons", []):
		var node_id: String = entry.get("node_id", "")
		test_assert.check(
			int(state.demon_counts_by_node.get(node_id, 0)) > 0,
			"demon visual should map to core demon node count"
		)


static func _test_snapshot_updates_after_turn(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(7)
	var before := JSON.stringify(BoardWorldMapper.build_snapshot(session.state, session.events))
	session.advance_one_player_turn()
	var after := JSON.stringify(BoardWorldMapper.build_snapshot(session.state, session.events))
	test_assert.check(before != after, "snapshot should change after bot turn when events occur")
