class_name TestStrategicPlayIntegration
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_view_model_includes_v1_fields(test_assert)
	_test_hero_contact_visible_in_snapshot(test_assert)
	_test_legal_actions_include_end_turn(test_assert)


static func _test_view_model_includes_v1_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(42, 0)
	var model := StrategicAuditViewModel.build(session)
	test_assert.check(str(model.get("phase", "")) != "", "view model should expose phase")
	test_assert.check(model.has("infection_rate"), "view model should expose infection rate")
	test_assert.check(model.has("hero_actions_remaining"), "view model should expose hero action budgets")


static func _test_hero_contact_visible_in_snapshot(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(55)
	GameStartRules.start_game(state)
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	SetupRules.rebuild_action_space(state)
	var target := state.board.get_adjacent_nodes(hero.node)[0]
	SetupRules.set_demon_count(state, target, 2)
	var action := _move_action(state, hero.id, target)
	ActionRules.apply(state, action)
	var snapshot := BoardWorldMapper.build_snapshot(state, [])
	var demons_at_target := 0
	for entry in snapshot.get("demons", []):
		if str(entry.get("node_key", "")) == target.to_key():
			demons_at_target = int(entry.get("count", 0))
	test_assert.eq(demons_at_target, 0, "snapshot should show demons cleared after macro contact")


static func _test_legal_actions_include_end_turn(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(7, 0)
	var has_end := false
	for action in session.get_legal_human_actions():
		if action.kind == ActionKind.Kind.END_TURN:
			has_end = true
	test_assert.check(has_end, "human session should expose END_TURN among legal actions")


static func _move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.MOVE_HERO and action.hero_id == hero_id:
			if action.target_node.equals(target):
				return action
	return null
