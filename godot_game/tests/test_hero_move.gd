class_name TestHeroMove
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	test_assert.check(hero != null, "hero should spawn on city node")

	var adjacent := state.board.get_adjacent_nodes(hero.node)
	test_assert.check(adjacent.size() > 0, "hero should have adjacent nodes")
	var target := adjacent[0]

	var action := _move_action(state, hero.id, target)
	test_assert.check(action != null, "action space should include hero move action")

	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 1, "move should emit one event")
	test_assert.check(events[0] is HeroMovedEvent, "move should emit HeroMovedEvent")
	test_assert.check(hero.node.equals(target), "hero should be on target node")


static func _move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.MOVE_HERO:
			continue
		if action.hero_id != hero_id:
			continue
		if action.target_node.equals(target):
			return action
	return null
