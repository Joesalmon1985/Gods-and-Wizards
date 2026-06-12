class_name TestHeroActionBudget
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_four_moves_then_fifth_illegal(test_assert)
	_test_budget_resets_on_end_turn(test_assert)
	_test_independent_hero_budgets(test_assert)
	_test_failed_move_does_not_consume_budget(test_assert)


static func _test_four_moves_then_fifth_illegal(test_assert: TestAssert) -> void:
	var state := _hero_game_with_budget(42)
	var hero: Hero = state.heroes[0]
	var moves := 0
	while moves < 4:
		var action := _first_legal_move(state, hero.id)
		test_assert.check(action != null, "move %d should be legal" % (moves + 1))
		ActionRules.apply(state, action)
		moves += 1
	var fifth := _first_legal_move(state, hero.id)
	test_assert.check(fifth == null, "fifth hero move in same turn should be illegal")


static func _test_budget_resets_on_end_turn(test_assert: TestAssert) -> void:
	var state := _hero_game_with_budget(43)
	var hero: Hero = state.heroes[0]
	for _i in 4:
		var action := _first_legal_move(state, hero.id)
		ActionRules.apply(state, action)
	TestRoundHelpers.apply_full_round_wrap(state)
	test_assert.eq(
		int(state.hero_actions_remaining.get(hero.id, 0)),
		GameConstants.HERO_ACTIONS_PER_TURN,
		"hero budget should reset when active player turn returns"
	)


static func _test_independent_hero_budgets(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(44)
	GameStartRules.start_game(state)
	var hero_a := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	var hero_b := SetupRules.place_hero(state, 0, state.cities[1].vertex if state.cities.size() > 1 else state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	for _i in 4:
		var action := _first_legal_move(state, hero_a.id)
		if action != null:
			ActionRules.apply(state, action)
	test_assert.check(
		_first_legal_move(state, hero_b.id) != null,
		"second hero should still have action budget when first is exhausted"
	)


static func _test_failed_move_does_not_consume_budget(test_assert: TestAssert) -> void:
	var state := _hero_game_with_budget(45)
	var hero: Hero = state.heroes[0]
	var illegal_target := hero.node
	var action := _move_action(state, hero.id, illegal_target)
	if action != null:
		var before := int(state.hero_actions_remaining.get(hero.id, 0))
		ActionRules.apply(state, action)
		var after := int(state.hero_actions_remaining.get(hero.id, 0))
		test_assert.eq(before, after, "illegal move should not consume hero action budget")


static func _hero_game_with_budget(seed: int) -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	GameStartRules.start_game(state)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	return state


static func _first_legal_move(state: GameState, hero_id: int) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id:
			return action
	return null


static func _move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id:
			if action.target_node.equals(target):
				return action
	return null
