class_name TestCityDemonOccupation
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_occupied_city_produces_nothing(test_assert)
	_test_timer_reset_on_demon_clear(test_assert)
	_test_full_round_purge_development(test_assert)
	_test_block_development_while_occupied(test_assert)


static func _test_occupied_city_produces_nothing(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var city := state.cities[0]
	SetupRules.set_demon_count(state, city.vertex, 1)
	state.rng.enqueue_fixed_rolls([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var wood_before := state.players[city.player_id].get_resource(ResourceType.Type.WOOD)
	var events := ProductionRules.resolve_round_production(state)
	var gained_for_city := false
	for event in events:
		if event is ResourceGainedEvent:
			var gain: ResourceGainedEvent = event
			if gain.vertex.equals(city.vertex):
				gained_for_city = true
	test_assert.check(not gained_for_city, "demon-occupied city should not gain resources")
	test_assert.eq(
		state.players[city.player_id].get_resource(ResourceType.Type.WOOD),
		wood_before,
		"occupied city owner resources should be unchanged by production"
	)


static func _test_timer_reset_on_demon_clear(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(43)
	var city := state.cities[0]
	SetupRules.set_demon_count(state, city.vertex, 1)
	test_assert.check(
		state.city_demon_occupied_since_round.has(city.vertex.to_key()),
		"occupation timer should start when demons arrive"
	)
	SetupRules.set_demon_count(state, city.vertex, 0)
	test_assert.check(
		not state.city_demon_occupied_since_round.has(city.vertex.to_key()),
		"occupation timer should reset when demons cleared"
	)


static func _test_full_round_purge_development(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(44)
	var city: City = state.cities[0]
	city.development_id = DevelopmentCatalog.SHRINE_ID
	state.round_number = 2
	SetupRules.set_demon_count(state, city.vertex, 1)
	state.city_demon_occupied_since_round[city.vertex.to_key()] = 1
	ScoreRules.grant_victory_points(state, city.player_id, 1, "test_shrine_setup")
	var vp_before := state.players[city.player_id].victory_points
	var events := CityOccupationRules.evaluate_round_start_purges(state)
	test_assert.eq(city.development_id, "", "full round occupation should purge development")
	var purged := false
	for event in events:
		if event is CityDevelopmentPurgedEvent:
			purged = true
	test_assert.check(purged, "purge should emit CityDevelopmentPurgedEvent")
	test_assert.check(
		state.players[city.player_id].victory_points < vp_before,
		"shrine purge should reduce victory points"
	)


static func _test_block_development_while_occupied(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(45)
	var city := state.cities[0]
	SetupRules.set_demon_count(state, city.vertex, 1)
	SetupRules.grant_resources(state, city.player_id, {
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})
	test_assert.check(
		not DevelopmentRules.can_build(state, city.player_id, city.vertex),
		"cannot build development in demon-occupied city"
	)
