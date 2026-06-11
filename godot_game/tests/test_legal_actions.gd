class_name TestLegalActions
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var standard := TestScenario.build_standard_game(42)
	var bot_ready := TestScenario.build_bot_ready_game(42)

	_test_mask_shape(test_assert, bot_ready)
	_test_end_turn_always_legal(test_assert, bot_ready)
	_test_build_city_rules(test_assert, bot_ready)
	_test_deterministic_mask(test_assert, bot_ready)
	_test_bot_viability(test_assert, bot_ready)
	_test_standard_has_no_build(test_assert, standard)


static func _test_mask_shape(test_assert: TestAssert, state: GameState) -> void:
	var view := LegalActionQuery.get_view(state)
	test_assert.eq(view.legal_mask.size(), state.action_space.size(), "mask should match action space size")
	test_assert.eq(view.action_ids.size(), state.action_space.size(), "action ids should match action space size")


static func _test_end_turn_always_legal(test_assert: TestAssert, state: GameState) -> void:
	var view := LegalActionQuery.get_view(state)
	test_assert.check(view.legal_mask[0], "END_TURN should always be legal for active player")


static func _test_build_city_rules(test_assert: TestAssert, state: GameState) -> void:
	var view := LegalActionQuery.get_view(state)
	var legal_build_count := 0
	var illegal_occupied_found := false

	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_CITY:
			continue
		var is_legal: bool = view.legal_mask[action.action_id]
		var vertex_key := action.vertex.to_key()
		var occupied := state.cities_by_vertex.has(vertex_key)
		if is_legal:
			legal_build_count += 1
			test_assert.check(not occupied, "legal BUILD_CITY vertex should be empty")
			test_assert.check(
				BuildCosts.can_afford(TurnRules.get_active_player(state), BuildCosts.BUILD_CITY),
				"legal BUILD_CITY requires affordable cost"
			)
		elif occupied:
			illegal_occupied_found = true

	test_assert.check(legal_build_count > 0, "bot-ready game should have at least one legal BUILD_CITY")
	test_assert.check(illegal_occupied_found, "occupied vertices should appear as illegal BUILD_CITY slots")


static func _test_deterministic_mask(test_assert: TestAssert, state: GameState) -> void:
	var first := LegalActionQuery.get_view(state).to_dict()
	var second := LegalActionQuery.get_view(state).to_dict()
	test_assert.eq(first, second, "legal mask query should be deterministic")

	var actions := LegalActionQuery.get_legal_actions_sorted(state)
	for i in range(actions.size() - 1):
		test_assert.check(
			actions[i].action_id < actions[i + 1].action_id,
			"legal actions should be sorted by action_id"
		)


static func _test_bot_viability(test_assert: TestAssert, state: GameState) -> void:
	var non_pass_count := 0
	var view := LegalActionQuery.get_view(state)
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.END_TURN:
			continue
		if view.legal_mask[action.action_id]:
			non_pass_count += 1
	test_assert.check(non_pass_count >= 1, "bot-ready scenario should have at least one non-END_TURN legal action")


static func _test_standard_has_no_build(test_assert: TestAssert, state: GameState) -> void:
	var view := LegalActionQuery.get_view(state)
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY and view.legal_mask[action.action_id]:
			test_assert.check(false, "standard scenario without grant should have no legal BUILD_CITY")
			return
