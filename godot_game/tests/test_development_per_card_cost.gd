class_name TestDevelopmentPerCardCost
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_catalog_cost_used_for_build(test_assert)
	_test_insufficient_resources_blocked(test_assert)


static func _test_catalog_cost_used_for_build(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	var player := state.players[0]
	player.development_hand.append("lumber_camp_a1")
	SetupRules.grant_resources(state, 0, {ResourceType.Type.WHEAT: 1})
	SetupRules.rebuild_action_space(state)
	test_assert.check(
		DevelopmentRules.can_build(state, 0, state.cities[0].vertex, "lumber_camp_a1"),
		"should afford lumber camp with 1 wheat"
	)


static func _test_insufficient_resources_blocked(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(43)
	GameStartRules.start_game(state)
	state.players[0].development_hand.append("monument_a2")
	SetupRules.grant_resources(state, 0, {
		ResourceType.Type.WOOD: 0,
		ResourceType.Type.BRICK: 0,
		ResourceType.Type.WHEAT: 1,
		ResourceType.Type.SHEEP: 0,
		ResourceType.Type.ORE: 0,
	})
	SetupRules.rebuild_action_space(state)
	test_assert.check(
		not BuildCosts.can_afford(
			state.players[0],
			DevelopmentCatalog.build_cost_as_resources("monument_a2")
		),
		"monument_a2 should cost wheat and sheep"
	)
	test_assert.check(
		not DevelopmentRules.can_build(state, 0, state.cities[0].vertex, "monument_a2"),
		"age II card should require more than 1 wheat"
	)
