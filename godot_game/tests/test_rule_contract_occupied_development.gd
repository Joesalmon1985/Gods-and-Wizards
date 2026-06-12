class_name TestRuleContractOccupiedDevelopment
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_cannot_build_in_occupied_city(test_assert)
	_test_legal_mask_excludes_occupied_build(test_assert)
	_test_card_stays_in_hand_when_blocked(test_assert)
	_test_existing_dev_remains_until_purge(test_assert)
	_test_full_round_purge(test_assert)


static func _occupied_city_state(seed: int) -> GameState:
	var state := ScenarioBuilder.build_four_player_bot_game(seed)
	var city := state.cities[0]
	SetupRules.set_demon_count(state, city.vertex, 1)
	state.players[0].development_hand.append("market_stall_a1")
	return state


static func _test_cannot_build_in_occupied_city(test_assert: TestAssert) -> void:
	var state := _occupied_city_state(701)
	var city := state.cities[0]
	test_assert.check(
		not DevelopmentRules.can_build(state, 0, city.vertex, "market_stall_a1"),
		"cannot build into demon-occupied city"
	)


static func _test_legal_mask_excludes_occupied_build(test_assert: TestAssert) -> void:
	var state := _occupied_city_state(702)
	SetupRules.rebuild_action_space(state)
	var found_legal := false
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_DEVELOPMENT:
			continue
		if LegalActionQuery.get_view(state).legal_mask[action.action_id]:
			found_legal = true
	test_assert.check(not found_legal, "legal mask should exclude occupied-city development play")


static func _test_card_stays_in_hand_when_blocked(test_assert: TestAssert) -> void:
	var state := _occupied_city_state(703)
	var before := state.players[0].development_hand.duplicate()
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_DEVELOPMENT:
			ActionRules.apply(state, action)
	test_assert.eq(state.players[0].development_hand, before, "blocked build leaves hand unchanged")


static func _test_existing_dev_remains_until_purge(test_assert: TestAssert) -> void:
	var state := _occupied_city_state(704)
	var city := state.cities[0]
	city.developments.append("market_stall_a1")
	SetupRules.set_demon_count(state, city.vertex, 1)
	test_assert.eq(city.developments.size(), 1, "existing development remains while occupied")


static func _test_full_round_purge(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(705)
	var city := state.cities[0]
	city.developments.append("market_stall_a1")
	SetupRules.set_demon_count(state, city.vertex, 2)
	state.city_demon_occupied_since_round[city.vertex.to_key()] = state.round_number - 1
	var events := CityOccupationRules.evaluate_round_start_purges(state)
	test_assert.eq(city.developments.size(), 0, "full-round occupation purges developments")
	var purged := false
	for event in events:
		if event is CityDevelopmentPurgedEvent:
			purged = true
	test_assert.check(purged, "purge emits CityDevelopmentPurgedEvent")
