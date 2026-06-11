class_name TestIntegrationBridge
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	var node := hero.node
	SetupRules.set_demon_count(state, node, 2)

	var sync := SyncController.new(state)
	var positions := sync.get_node_world_positions()
	test_assert.check(positions.has(node.to_key()), "sync should expose node anchors")

	var events := EncounterBridge.submit_hero_vs_demon(
		state,
		hero.id,
		node,
		[&"thrust", &"thrust", &"thrust"],
		[&"swing", &"swing", &"swing"]
	)
	test_assert.check(events.size() >= 1, "bridge should return encounter events")
	test_assert.check(events[0] is EncounterCombatEvent, "bridge should emit EncounterCombatEvent")

	var action := WizardController.new(sync).request_move_action(
		state,
		hero.id,
		state.board.get_adjacent_nodes(node)[0]
	)
	test_assert.check(action != null, "wizard controller should find move actions without mutating state directly")
