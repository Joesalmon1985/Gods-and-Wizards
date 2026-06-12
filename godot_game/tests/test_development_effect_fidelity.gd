class_name TestDevelopmentEffectFidelity
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_trade_bonus_on_accept(test_assert)
	_test_wizard_access_flags(test_assert)
	_test_production_discount_affordability(test_assert)
	_test_draft_bonus_peek_event(test_assert)


static func _test_trade_bonus_on_accept(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(901)
	var city := _city_for_player(state, 1)
	city.developments.append("market_stall_a1")
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	var brick_before := state.players[1].get_resource(ResourceType.Type.WOOD)
	ActionRules.apply(state, RuleContractFixtures.find_trade_accept(state, 1))
	var brick_after := state.players[1].get_resource(ResourceType.Type.WOOD)
	test_assert.check(brick_after > brick_before, "trade bonus should grant acceptor extra resource")


static func _test_wizard_access_flags(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(902)
	var city := state.cities[0]
	state.players[0].development_hand.append("arcane_study_a1")
	for resource_key in DevelopmentCatalog.build_cost_as_resources("arcane_study_a1").keys():
		state.players[0].resources[ResourceType.Type.WOOD] = 5
		state.players[0].resources[ResourceType.Type.BRICK] = 5
		state.players[0].resources[ResourceType.Type.WHEAT] = 5
		state.players[0].resources[ResourceType.Type.SHEEP] = 5
		state.players[0].resources[ResourceType.Type.ORE] = 5
	var events := DevelopmentRules.apply(state, 0, city.vertex, "arcane_study_a1")
	test_assert.check(not events.is_empty(), "wizard access card should build")
	test_assert.check(state.players[0].wizard_encounter_unlock, "wizard encounter flag set")


static func _test_production_discount_affordability(test_assert: TestAssert) -> void:
	var base := {"wood": 2, "brick": 1}
	var discounted := DevelopmentEffectEngine.apply_build_cost_discount(base, 1)
	test_assert.eq(int(discounted["wood"]), 1, "production discount reduces build cost")


static func _test_draft_bonus_peek_event(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(903)
	state.cities[0].developments.append("free_port_a3")
	state.draft_packs_by_player[0] = ["card_a", "card_b"]
	var events := DevelopmentEffectEngine.append_draft_peek_events(state)
	test_assert.check(not events.is_empty(), "draft bonus emits peek event")
	test_assert.check(events[0] is DraftPackPeekEvent, "peek event type")


static func _city_for_player(state: GameState, player_id: int) -> City:
	for city in state.cities:
		if city.player_id == player_id:
			return city
	return state.cities[0]
