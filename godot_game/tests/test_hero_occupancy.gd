class_name TestHeroOccupancy
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var node := state.cities[0].vertex
	var hero_a := SetupRules.place_hero(state, 0, node)
	test_assert.check(hero_a != null, "first hero should spawn")

	var hero_b := SetupRules.place_hero(state, 1, node)
	test_assert.check(hero_b == null, "second hero should not stack on same node")

	SetupRules.rebuild_action_space(state)
	var adjacent := state.board.get_adjacent_nodes(node)[0]
	var move_action := _move_action(state, hero_a.id, adjacent)
	test_assert.check(move_action != null, "hero move action should exist after rebuild")
	ActionRules.apply(state, move_action)
	var blocked := SetupRules.place_hero(state, 1, adjacent)
	test_assert.check(blocked == null, "occupied node should reject new hero")


static func _move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id and action.target_node.equals(target):
			return action
	return null
