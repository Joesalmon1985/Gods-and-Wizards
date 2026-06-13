class_name TestDemonSpread
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_infection_draw_adds_demons(test_assert)
	_test_cap_three_fourth_causes_breach(test_assert)
	_test_deterministic_draw_sequence(test_assert)
	_test_no_adjacent_propagation(test_assert)


static func _test_infection_draw_adds_demons(test_assert: TestAssert) -> void:
	var state := _infection_ready_state(42)
	var before := _total_demons(state)
	var events := SpreadRules.resolve_player_turn_end(state)
	test_assert.check(events.size() >= 1, "infection draw should emit spread events")
	test_assert.check(_total_demons(state) > before, "infection draw should add demons")


static func _test_cap_three_fourth_causes_breach(test_assert: TestAssert) -> void:
	var state := _infection_ready_state(99)
	var node := state.board.get_all_nodes_sorted()[0]
	SetupRules.set_demon_count(state, node, 3)
	state.breach_count = 0
	var events := SpreadRules.try_add_demon(state, node)
	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "fourth demon should not be placed")
	test_assert.eq(state.breach_count, 1, "fourth demon attempt should increment breach")
	var breach_found := false
	for event in events:
		if event is BreachEvent:
			breach_found = true
	test_assert.check(breach_found, "cap breach should emit BreachEvent")


static func _test_deterministic_draw_sequence(test_assert: TestAssert) -> void:
	var first := _infection_signature(_infection_ready_state(77))
	var second := _infection_signature(_infection_ready_state(77))
	test_assert.eq(first, second, "infection spread should be deterministic with fixed seed")


static func _test_no_adjacent_propagation(test_assert: TestAssert) -> void:
	var spread_source := FileAccess.get_file_as_string("res://core/rules/spread_rules.gd")
	var infection_section := spread_source.split("static func resolve_player_turn_end")[1].split("static func surge_chance")[0]
	test_assert.check(
		"get_adjacent_nodes" not in infection_section,
		"infection deck spread should not use adjacent propagation"
	)
	test_assert.check(
		spread_source.find("_breach_node_and_spread") >= 0,
		"breach cascade should propagate to connected nodes when a node is full"
	)


static func _infection_ready_state(seed: int) -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	state.rng.seed(seed)
	SpreadRules.initialize_deck(state)
	return state


static func _infection_signature(state: GameState) -> String:
	var events := SpreadRules.resolve_player_turn_end(state)
	var parts: Array[String] = []
	for event in events:
		if event is DemonSpreadEvent:
			var spread: DemonSpreadEvent = event
			parts.append("%s:%d" % [spread.to_node.to_key(), spread.amount])
		elif event is BreachEvent:
			var breach: BreachEvent = event
			parts.append("breach:%d" % breach.breach_count)
	return "|".join(parts)


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
