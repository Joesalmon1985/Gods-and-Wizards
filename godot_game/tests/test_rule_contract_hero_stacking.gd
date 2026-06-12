class_name TestRuleContractHeroStacking
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_friendly_stack_blocked(test_assert)
	_test_friendly_stack_not_in_legal_mask(test_assert)
	_test_failed_friendly_move_no_action_consume(test_assert)
	_test_hostile_clash_removes_both(test_assert)
	_test_clash_emits_event(test_assert)


static func _test_friendly_stack_blocked(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(601)
	var node := state.cities[0].vertex
	SetupRules.place_hero(state, 0, node)
	var blocked := SetupRules.place_hero(state, 0, node)
	test_assert.check(blocked == null, "friendly hero cannot stack on friendly hero node")


static func _test_friendly_stack_not_in_legal_mask(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(602)
	var node := state.cities[0].vertex
	var hero := SetupRules.place_hero(state, 0, node)
	SetupRules.place_hero(state, 1, state.board.get_adjacent_nodes(node)[0])
	SetupRules.rebuild_action_space(state)
	var move := _find_move_to_node(state, hero.id, node)
	if move != null:
		test_assert.check(not LegalActionQuery.get_view(state).legal_mask[move.action_id], "friendly stack move excluded from legal mask")


static func _test_failed_friendly_move_no_action_consume(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(603)
	var node := state.cities[0].vertex
	var hero := SetupRules.place_hero(state, 0, node)
	SetupRules.place_hero(state, 1, state.board.get_adjacent_nodes(node)[0])
	SetupRules.rebuild_action_space(state)
	var before := int(state.hero_actions_remaining.get(hero.id, 0))
	var move := _find_move_to_node(state, hero.id, node)
	if move != null:
		ActionRules.apply(state, move)
	var after := int(state.hero_actions_remaining.get(hero.id, 0))
	test_assert.eq(before, after, "failed friendly-stack move should not consume hero action")


static func _test_hostile_clash_removes_both(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(604)
	var node := state.cities[0].vertex
	var hero_a := SetupRules.place_hero(state, 0, node)
	var adjacent := state.board.get_adjacent_nodes(node)[0]
	var hero_b := SetupRules.place_hero(state, 1, adjacent)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	var move := _find_move_to_node(state, hero_a.id, adjacent)
	test_assert.check(move != null, "move onto enemy hero should exist")
	ActionRules.apply(state, move)
	test_assert.check(state.heroes_by_id.get(hero_a.id) == null, "moving hero removed after clash")
	test_assert.check(state.heroes_by_id.get(hero_b.id) == null, "defender hero removed after clash")


static func _test_clash_emits_event(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(605)
	var node := state.cities[0].vertex
	var hero_a := SetupRules.place_hero(state, 0, node)
	var adjacent := state.board.get_adjacent_nodes(node)[0]
	SetupRules.place_hero(state, 1, adjacent)
	SetupRules.rebuild_action_space(state)
	TurnLifecycleRules.on_turn_start(state)
	var events := ActionRules.apply(state, _find_move_to_node(state, hero_a.id, adjacent))
	var found := false
	for event in events:
		if event is HeroClashEvent:
			found = true
	test_assert.check(found, "hostile clash should emit HeroClashEvent")


static func _find_move_to_node(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id and action.target_node.equals(target):
			return action
	return null
