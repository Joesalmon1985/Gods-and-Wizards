class_name TestMacroContactResolution
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_hero_clears_one_two_three_demons(test_assert)
	_test_demons_placed_on_hero_node_cleared(test_assert)
	_test_spread_onto_hero_node_cleared(test_assert)
	_test_macro_path_avoids_spell_combat(test_assert)


static func _test_hero_clears_one_two_three_demons(test_assert: TestAssert) -> void:
	for demon_count in [1, 2, 3]:
		var state := _hero_on_adjacent_setup(42 + demon_count)
		var hero: Hero = state.heroes[0]
		var target := _demon_node(state, demon_count)
		SetupRules.set_demon_count(state, target, demon_count)

		var action := _move_action(state, hero.id, target)
		test_assert.check(action != null, "hero should be able to move onto demon node (%d demons)" % demon_count)

		var events := ActionRules.apply(state, action)
		test_assert.eq(
			SetupRules.get_demon_count(state, target),
			0,
			"hero move should clear %d demons" % demon_count
		)
		test_assert.check(hero.node.equals(target), "hero should remain on node after contact")
		var cleared := false
		for event in events:
			if event is DemonsClearedEvent:
				var clear_event: DemonsClearedEvent = event
				test_assert.eq(clear_event.cleared_count, demon_count, "event should report cleared count")
				cleared = true
		test_assert.check(cleared, "hero contact should emit DemonsClearedEvent")


static func _test_demons_placed_on_hero_node_cleared(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(55)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.set_demon_count(state, hero.node, 2)
	var events := ContactResolutionRules.resolve_hero_node_after_demon_placement(state, hero.node)
	test_assert.eq(SetupRules.get_demon_count(state, hero.node), 0, "placement hook should clear demons on hero node")
	test_assert.check(events.size() >= 1, "should emit clearance event")


static func _test_spread_onto_hero_node_cleared(test_assert: TestAssert) -> void:
	var spread_source := FileAccess.get_file_as_string("res://core/rules/spread_rules.gd")
	test_assert.check(
		"ContactResolutionRules.resolve_hero_node_after_demon_placement" in spread_source,
		"spread path should purge demons placed on hero nodes"
	)
	var state := ScenarioBuilder.build_bot_ready_game(66)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.set_demon_count(state, hero.node, 1)
	var events := ContactResolutionRules.resolve_hero_node_after_demon_placement(state, hero.node)
	test_assert.eq(SetupRules.get_demon_count(state, hero.node), 0, "post-placement hook should clear hero node")
	test_assert.check(events.size() >= 1, "post-placement hook should emit events")


static func _test_macro_path_avoids_spell_combat(test_assert: TestAssert) -> void:
	var action_rules_source := FileAccess.get_file_as_string("res://core/rules/action_rules.gd")
	test_assert.check(
		"SpellCombatSession" not in action_rules_source,
		"ActionRules should not reference SpellCombatSession"
	)
	test_assert.check(
		"CombatResolver" not in action_rules_source,
		"ActionRules should not reference CombatResolver"
	)
	var contact_source := FileAccess.get_file_as_string("res://core/rules/contact_resolution_rules.gd")
	test_assert.check(
		"SpellCombatSession" not in contact_source,
		"ContactResolutionRules should not reference SpellCombatSession"
	)


static func _hero_on_adjacent_setup(seed: int) -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	return state


static func _demon_node(state: GameState, offset: int) -> BoardNode:
	var hero: Hero = state.heroes[0]
	var adjacent := state.board.get_adjacent_nodes(hero.node)
	return adjacent[offset % adjacent.size()]


static func _move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.MOVE_HERO:
			continue
		if action.hero_id != hero_id:
			continue
		if action.target_node.equals(target):
			return action
	return null
