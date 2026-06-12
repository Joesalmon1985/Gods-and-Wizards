class_name TestDraftSession
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_round_end_adds_card_to_hand(test_assert)
	_test_pack_passes_left(test_assert)
	_test_play_from_hand_into_city_slot(test_assert)
	_test_fourth_slot_illegal(test_assert)
	_test_occupied_city_cannot_play(test_assert)


static func _test_round_end_adds_card_to_hand(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	GameStartRules.start_game(state)
	var hand_before := state.players[0].development_hand.size()
	_simulate_round_wrap(state)
	test_assert.check(
		state.players[0].development_hand.size() > hand_before,
		"round end draft should add a card to player hand"
	)


static func _test_pack_passes_left(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(43)
	GameStartRules.start_game(state)
	var player0_pack_before: Array = state.draft_packs_by_player[0].duplicate()
	var player0_pick := DraftBotPolicy.choose_card_id(state, 0)
	var expected_for_player1: Array = player0_pack_before.duplicate()
	expected_for_player1.erase(player0_pick)
	_simulate_round_wrap(state)
	test_assert.eq(
		state.draft_packs_by_player[1],
		expected_for_player1,
		"passed pack should move left to next player after simultaneous pick"
	)


static func _test_play_from_hand_into_city_slot(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(44)
	GameStartRules.start_game(state)
	state.players[0].development_hand.append("lumber_camp_a1")
	SetupRules.grant_resources(state, 0, {
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})
	SetupRules.rebuild_action_space(state)
	var city_vertex := state.cities[0].vertex
	var action := _find_development_action(state, city_vertex, "lumber_camp_a1")
	test_assert.check(action != null, "development play action should exist for hand card")
	var events := ActionRules.apply(state, action)
	test_assert.check(not events.is_empty(), "development play should apply")
	test_assert.check(
		"lumber_camp_a1" in state.cities[0].developments,
		"played card should occupy city development slot"
	)
	test_assert.check(
		"lumber_camp_a1" not in state.players[0].development_hand,
		"played card should leave hand"
	)


static func _test_fourth_slot_illegal(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(45)
	GameStartRules.start_game(state)
	var city: City = state.cities[0]
	city.developments = ["lumber_camp_a1", "brickworks_a1", "pasture_grant_a1"]
	state.players[0].development_hand.append("lumber_camp_a1")
	SetupRules.rebuild_action_space(state)
	test_assert.check(
		not DevelopmentRules.can_build(
			state,
			0,
			city.vertex,
			"lumber_camp_a1"
		),
		"fourth development slot should be illegal"
	)


static func _test_occupied_city_cannot_play(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(46)
	GameStartRules.start_game(state)
	state.players[0].development_hand.append("brickworks_a1")
	SetupRules.set_demon_count(state, state.cities[0].vertex, 1)
	SetupRules.rebuild_action_space(state)
	test_assert.check(
		not DevelopmentRules.can_build(
			state,
			0,
			state.cities[0].vertex,
			"brickworks_a1"
		),
		"demon-occupied city should block development play"
	)


static func _simulate_round_wrap(state: GameState) -> void:
	var end_turn := state.action_space.get_action(0)
	for _i in state.players.size():
		ActionRules.apply(state, end_turn)
	DraftRules.complete_automatic_draft_for_bots(state)


static func _find_development_action(
	state: GameState,
	vertex: BoardNode,
	development_id: String
) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_DEVELOPMENT:
			continue
		if action.vertex.equals(vertex) and action.development_id == development_id:
			return action
	return null
