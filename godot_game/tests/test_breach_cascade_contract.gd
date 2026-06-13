class_name TestBreachCascadeContract
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_fourth_demon_increments_counter(test_assert)
	_test_does_not_add_fourth_demon_to_source(test_assert)
	_test_adds_one_demon_to_connected_nodes(test_assert)
	_test_cascade_from_connected_full_node(test_assert)
	_test_three_node_chain_breaches(test_assert)
	_test_cycle_terminates_deterministically(test_assert)
	_test_unconnected_nodes_unaffected(test_assert)
	_test_event_log_records_cascade(test_assert)
	_test_order_is_deterministic(test_assert)
	_test_counter_matches_unique_breaches(test_assert)


static func _test_fourth_demon_increments_counter(test_assert: TestAssert) -> void:
	var setup := _isolated_cap_setup()
	var state: GameState = setup["state"]
	var node: BoardNode = setup["node"]
	SetupRules.set_demon_count(state, node, 3)
	state.breach_count = 0
	var events := SpreadRules.try_add_demon(state, node)
	test_assert.eq(state.breach_count, 1, "4th demon attempt should increment breach")
	test_assert.check(_has_breach_event(events), "should emit BreachEvent")


static func _test_does_not_add_fourth_demon_to_source(test_assert: TestAssert) -> void:
	var setup := _isolated_cap_setup()
	var state: GameState = setup["state"]
	var node: BoardNode = setup["node"]
	SetupRules.set_demon_count(state, node, 3)
	SpreadRules.try_add_demon(state, node)
	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "source should remain at 3 demons")


static func _test_adds_one_demon_to_connected_nodes(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8801)
	var state: GameState = setup["state"]
	var source: BoardNode = setup["source"]
	var neighbor: BoardNode = setup["neighbor"]
	SetupRules.set_demon_count(state, source, 3)
	SetupRules.set_demon_count(state, neighbor, 0)
	state.breach_count = 0
	SpreadRules.try_add_demon(state, source)
	test_assert.eq(SetupRules.get_demon_count(state, neighbor), 1, "connected neighbor should gain 1 demon")
	test_assert.eq(SetupRules.get_demon_count(state, source), 3, "source stays capped")


static func _test_cascade_from_connected_full_node(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8802)
	var state: GameState = setup["state"]
	var source: BoardNode = setup["source"]
	var neighbor: BoardNode = setup["neighbor"]
	SetupRules.set_demon_count(state, source, 3)
	SetupRules.set_demon_count(state, neighbor, 3)
	state.breach_count = 0
	SpreadRules.try_add_demon(state, source)
	test_assert.eq(state.breach_count, 2, "neighbor at cap should cascade second breach")
	test_assert.eq(SetupRules.get_demon_count(state, neighbor), 3, "neighbor stays at 3")


static func _test_node_breaches_once_per_calculation(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8803)
	var state: GameState = setup["state"]
	var source: BoardNode = setup["source"]
	var neighbor: BoardNode = setup["neighbor"]
	SetupRules.set_demon_count(state, source, 3)
	SetupRules.set_demon_count(state, neighbor, 3)
	state.breach_count = 0
	SpreadRules.try_add_demon(state, source)
	test_assert.eq(state.breach_count, 2, "two full connected nodes should breach once each per calculation")


static func _test_three_node_chain_breaches(test_assert: TestAssert) -> void:
	var setup := _triple_setup(8803)
	if setup.is_empty():
		return
	var state: GameState = setup["state"]
	var nodes: Array = setup["nodes"]
	for node in nodes:
		SetupRules.set_demon_count(state, node, 3)
	state.breach_count = 0
	SpreadRules.try_add_demon(state, nodes[0])
	test_assert.eq(state.breach_count, 3, "three-node chain at cap should breach each node once")


static func _test_cycle_terminates_deterministically(test_assert: TestAssert) -> void:
	var setup_a := _triple_setup(8804)
	var setup_b := _triple_setup(8804)
	if setup_a.is_empty():
		return
	var state_a: GameState = setup_a["state"]
	var state_b: GameState = setup_b["state"]
	var nodes_a: Array = setup_a["nodes"]
	var nodes_b: Array = setup_b["nodes"]
	for i in nodes_a.size():
		SetupRules.set_demon_count(state_a, nodes_a[i], 3)
		SetupRules.set_demon_count(state_b, nodes_b[i], 3)
	state_a.breach_count = 0
	state_b.breach_count = 0
	var events_a := SpreadRules.try_add_demon(state_a, nodes_a[0])
	var events_b := SpreadRules.try_add_demon(state_b, nodes_b[0])
	test_assert.eq(state_a.breach_count, state_b.breach_count, "same seed chain should breach same count")
	test_assert.eq(_event_signature(events_a), _event_signature(events_b), "cascade event order should match")


static func _test_unconnected_nodes_unaffected(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8805)
	var state: GameState = setup["state"]
	var source: BoardNode = setup["source"]
	var far := _far_node(state, source, setup["neighbor"])
	var far_before := SetupRules.get_demon_count(state, far)
	SetupRules.set_demon_count(state, source, 3)
	SpreadRules.try_add_demon(state, source)
	test_assert.eq(SetupRules.get_demon_count(state, far), far_before, "unconnected node demons unchanged")


static func _test_event_log_records_cascade(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8806)
	var state: GameState = setup["state"]
	var source: BoardNode = setup["source"]
	SetupRules.set_demon_count(state, source, 3)
	SetupRules.set_demon_count(state, setup["neighbor"], 3)
	var events := SpreadRules.try_add_demon(state, source)
	var cascade_found := false
	for event in events:
		if event is BreachCascadeEvent:
			cascade_found = true
	test_assert.check(cascade_found, "should emit BreachCascadeEvent")


static func _test_order_is_deterministic(test_assert: TestAssert) -> void:
	var a := _pair_setup(8807)
	var b := _pair_setup(8807)
	SetupRules.set_demon_count(a["state"], a["source"], 3)
	SetupRules.set_demon_count(b["state"], b["source"], 3)
	var sig_a := _event_signature(SpreadRules.try_add_demon(a["state"], a["source"]))
	var sig_b := _event_signature(SpreadRules.try_add_demon(b["state"], b["source"]))
	test_assert.eq(sig_a, sig_b, "identical setup should produce identical event sequence")


static func _test_counter_matches_unique_breaches(test_assert: TestAssert) -> void:
	var setup := _pair_setup(8808)
	var state: GameState = setup["state"]
	SetupRules.set_demon_count(state, setup["source"], 3)
	SetupRules.set_demon_count(state, setup["neighbor"], 3)
	state.breach_count = 0
	SpreadRules.try_add_demon(state, setup["source"])
	test_assert.eq(state.breach_count, 2, "breach counter should equal unique breached nodes in pair")


static func _isolated_cap_setup() -> Dictionary:
	var state := ScenarioBuilder.build_bot_ready_game(8700)
	SpreadRules.initialize_deck(state)
	var node := RuleContractFixtures.pick_infection_target_node(state)
	return {"state": state, "node": node}


static func _pair_setup(seed: int) -> Dictionary:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	GameStartRules.start_game(state)
	var nodes := state.board.get_all_nodes_sorted()
	var source: BoardNode = null
	var neighbor: BoardNode = null
	for node in nodes:
		if state.cities_by_vertex.has(node.to_key()) or state.heroes_by_node.has(node.to_key()):
			continue
		var adj := state.board.get_adjacent_nodes(node)
		for other in adj:
			if state.cities_by_vertex.has(other.to_key()) or state.heroes_by_node.has(other.to_key()):
				continue
			source = node
			neighbor = other
			break
		if source != null:
			break
	if source == null:
		source = nodes[0]
		neighbor = state.board.get_adjacent_nodes(source)[0]
	return {"state": state, "source": source, "neighbor": neighbor}


static func _triple_setup(seed: int) -> Dictionary:
	var pair := _pair_setup(seed)
	var state: GameState = pair["state"]
	var n0: BoardNode = pair["source"]
	var n1: BoardNode = pair["neighbor"]
	var n2: BoardNode = null
	for adj in state.board.get_adjacent_nodes(n1):
		if adj.equals(n0):
			continue
		if state.cities_by_vertex.has(adj.to_key()) or state.heroes_by_node.has(adj.to_key()):
			continue
		n2 = adj
		break
	if n2 == null:
		return {}
	return {"state": state, "nodes": [n0, n1, n2]}


static func _far_node(state: GameState, source: BoardNode, neighbor: BoardNode) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if node.equals(source) or node.equals(neighbor):
			continue
		var adjacent_to_source := false
		for adj in state.board.get_adjacent_nodes(source):
			if adj.equals(node):
				adjacent_to_source = true
				break
		if not adjacent_to_source:
			return node
	return state.board.get_all_nodes_sorted()[-1]


static func _nodes_adjacent(state: GameState, a: BoardNode, b: BoardNode) -> bool:
	for adj in state.board.get_adjacent_nodes(a):
		if adj.equals(b):
			return true
	return false


static func _has_breach_event(events: Array) -> bool:
	for event in events:
		if event is BreachEvent:
			return true
	return false


static func _event_signature(events: Array) -> String:
	var parts: Array[String] = []
	for event in events:
		if event is BreachEvent:
			parts.append("breach:%d" % event.breach_count)
		elif event is BreachCascadeEvent:
			parts.append("cascade:%s" % event.breach_source_node.to_key())
		elif event is BreachSpreadSkippedEvent:
			parts.append("skip:%s" % event.skipped_node.to_key())
		elif event is DemonSpreadEvent:
			parts.append("spread:%s->%s" % [event.from_node.to_key(), event.to_node.to_key()])
	return "|".join(parts)
