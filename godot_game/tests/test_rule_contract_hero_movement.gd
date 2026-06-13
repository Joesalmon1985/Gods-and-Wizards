class_name TestRuleContractHeroMovement
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_base_allowance_per_turn(test_assert)
	_test_development_modifier_increases_allowance(test_assert)
	_test_modifier_resets_on_turn_boundary(test_assert)
	_test_cannot_exceed_modified_allowance(test_assert)
	_test_consumes_one_action_per_move(test_assert)
	_test_rejects_unconnected_destination(test_assert)
	_test_allows_connected_destination(test_assert)
	_test_removes_demon_on_encounter(test_assert)
	_test_multiple_demons_all_removed(test_assert)
	_test_demon_removal_logged(test_assert)
	_test_legal_mask_when_exhausted(test_assert)
	_test_deterministic_from_seed(test_assert)
	_test_hero_clash_matches_gd014(test_assert)


static func _test_base_allowance_per_turn(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9001)
	var hero: Hero = state.heroes[0]
	test_assert.eq(
		int(state.hero_actions_remaining.get(hero.id, 0)),
		GameConstants.HERO_ACTIONS_PER_TURN,
		"base hero movement allowance per turn"
	)


static func _test_development_modifier_increases_allowance(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(9002)
	GameStartRules.start_game(state)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	state.cities[0].developments.append("ranger_post_a1")
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	test_assert.eq(
		int(state.hero_actions_remaining.get(hero.id, 0)),
		GameConstants.HERO_ACTIONS_PER_TURN + 1,
		"development modifier increases allowance"
	)


static func _test_modifier_resets_on_turn_boundary(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(9003)
	GameStartRules.start_game(state)
	state.cities[0].developments.append("ranger_post_a1")
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	for _i in 5:
		var action := _first_move(state, hero.id)
		if action != null:
			ActionRules.apply(state, action)
	TestRoundHelpers.apply_full_round_wrap(state)
	test_assert.eq(
		int(state.hero_actions_remaining.get(hero.id, 0)),
		GameConstants.HERO_ACTIONS_PER_TURN + 1,
		"modifier reapplied on new active turn"
	)


static func _test_cannot_exceed_modified_allowance(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(9004)
	GameStartRules.start_game(state)
	state.cities[0].developments.append("ranger_post_a1")
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	var max_moves := GameConstants.HERO_ACTIONS_PER_TURN + 1
	for _i in max_moves:
		var action := _first_move(state, hero.id)
		test_assert.check(action != null, "move within allowance should be legal")
		ActionRules.apply(state, action)
	test_assert.check(_first_move(state, hero.id) == null, "cannot exceed modified allowance")


static func _test_consumes_one_action_per_move(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9005)
	var hero: Hero = state.heroes[0]
	var before := int(state.hero_actions_remaining.get(hero.id, 0))
	var action := _first_move(state, hero.id)
	ActionRules.apply(state, action)
	test_assert.eq(int(state.hero_actions_remaining.get(hero.id, 0)), before - 1, "one action consumed")


static func _test_rejects_unconnected_destination(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9006)
	var hero: Hero = state.heroes[0]
	var far := _non_adjacent_node(state, hero.node)
	test_assert.check(not MoveRules.can_move_hero(state, 0, hero, far), "unconnected destination illegal")


static func _test_allows_connected_destination(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9007)
	var hero: Hero = state.heroes[0]
	var adj := state.board.get_adjacent_nodes(hero.node)[0]
	test_assert.check(MoveRules.can_move_hero(state, 0, hero, adj), "connected destination legal")


static func _test_removes_demon_on_encounter(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9008)
	var hero: Hero = state.heroes[0]
	var target := state.board.get_adjacent_nodes(hero.node)[0]
	SetupRules.set_demon_count(state, target, 2)
	SetupRules.rebuild_action_space(state)
	var action := _move_to(state, hero.id, target)
	ActionRules.apply(state, action)
	test_assert.eq(SetupRules.get_demon_count(state, target), 0, "demons removed on encounter")


static func _test_multiple_demons_all_removed(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9009)
	var hero: Hero = state.heroes[0]
	var target := state.board.get_adjacent_nodes(hero.node)[0]
	SetupRules.set_demon_count(state, target, 3)
	SetupRules.rebuild_action_space(state)
	ActionRules.apply(state, _move_to(state, hero.id, target))
	test_assert.eq(SetupRules.get_demon_count(state, target), 0, "all demons removed per GD-002")


static func _test_demon_removal_logged(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9010)
	var hero: Hero = state.heroes[0]
	var target := state.board.get_adjacent_nodes(hero.node)[0]
	SetupRules.set_demon_count(state, target, 1)
	SetupRules.rebuild_action_space(state)
	var events := ActionRules.apply(state, _move_to(state, hero.id, target))
	var cleared := false
	for event in events:
		if event is DemonsClearedEvent:
			cleared = true
	test_assert.check(cleared, "demon removal should emit DemonsClearedEvent")


static func _test_legal_mask_when_exhausted(test_assert: TestAssert) -> void:
	var state := _hero_turn_state(9011)
	var hero: Hero = state.heroes[0]
	for _i in GameConstants.HERO_ACTIONS_PER_TURN:
		ActionRules.apply(state, _first_move(state, hero.id))
	var mask := LegalActionQuery.get_view(state).legal_mask
	var hero_moves := 0
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero.id and mask[action.action_id]:
			hero_moves += 1
	test_assert.eq(hero_moves, 0, "no legal hero moves when allowance exhausted")


static func _test_deterministic_from_seed(test_assert: TestAssert) -> void:
	var a := _hero_turn_state(9012)
	var b := _hero_turn_state(9012)
	var hero_a: Hero = a.heroes[0]
	var hero_b: Hero = b.heroes[0]
	var action_a := _first_move(a, hero_a.id)
	var action_b := _first_move(b, hero_b.id)
	test_assert.check(action_a != null and action_b != null, "legal move exists")
	test_assert.eq(action_a.action_id, action_b.action_id, "same seed yields same legal move id")


static func _test_hero_clash_matches_gd014(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(9013)
	var node := state.cities[0].vertex
	var hero_a := SetupRules.place_hero(state, 0, node)
	var adjacent := state.board.get_adjacent_nodes(node)[0]
	SetupRules.place_hero(state, 1, adjacent)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	var action := _move_to(state, hero_a.id, adjacent)
	test_assert.check(action != null, "move onto enemy hero should exist")
	var events := ActionRules.apply(state, action)
	var clash := false
	for event in events:
		if event is HeroClashEvent:
			clash = true
	test_assert.check(clash, "hostile hero clash emits HeroClashEvent")
	test_assert.check(state.heroes_by_id.get(hero_a.id) == null, "moving hero removed")


static func _hero_turn_state(seed: int) -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	GameStartRules.start_game(state)
	SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	return state


static func _first_move(state: GameState, hero_id: int) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id:
			return action
	return null


static func _move_to(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id:
			if action.target_node.equals(target):
				return action
	return null


static func _non_adjacent_node(state: GameState, origin: BoardNode) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if node.equals(origin):
			continue
		var is_adjacent := false
		for adj in state.board.get_adjacent_nodes(origin):
			if adj.equals(node):
				is_adjacent = true
				break
		if not is_adjacent:
			return node
	return origin
