class_name TestDevelopmentCatalog
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_catalog_entries(test_assert)
	_test_watchtower_build_unchanged(test_assert)
	_test_shrine_grants_victory_point(test_assert)
	_test_unknown_id_falls_back_to_watchtower(test_assert)


static func _test_catalog_entries(test_assert: TestAssert) -> void:
	var ids := DevelopmentCatalog.all_ids_sorted()
	test_assert.eq(ids.size(), 3, "catalog should expose three development cards")
	test_assert.check(DevelopmentCatalog.has_id("watchtower"), "watchtower should exist")
	test_assert.check(DevelopmentCatalog.has_id("granary"), "granary should exist")
	test_assert.check(DevelopmentCatalog.has_id("shrine"), "shrine should exist")


static func _test_watchtower_build_unchanged(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	SetupRules.grant_resources(state, player.id, {
		ResourceType.Type.WOOD: 0,
		ResourceType.Type.BRICK: 0,
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})

	player.development_hand.append(DevelopmentCatalog.WATCHTOWER_ID)
	var city_vertex := state.cities[0].vertex
	var events := DevelopmentRules.apply(state, player.id, city_vertex, DevelopmentCatalog.WATCHTOWER_ID)
	test_assert.check(events[0] is DevelopmentBuiltEvent, "watchtower build should emit DevelopmentBuiltEvent")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.development_id, DevelopmentCatalog.WATCHTOWER_ID, "default build should remain watchtower")
	test_assert.eq(events.size(), 1, "watchtower should not grant bonus victory points")


static func _test_shrine_grants_victory_point(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(5)
	var player := state.players[0]
	SetupRules.grant_resources(state, player.id, {
		ResourceType.Type.WOOD: 0,
		ResourceType.Type.BRICK: 0,
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})
	var starting_vp := player.victory_points
	player.development_hand.append(DevelopmentCatalog.SHRINE_ID)
	var city_vertex := state.cities[0].vertex
	var events := DevelopmentRules.apply(state, player.id, city_vertex, DevelopmentCatalog.SHRINE_ID)

	test_assert.check(events.size() >= 2, "shrine build should emit development and scoring events")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.development_id, DevelopmentCatalog.SHRINE_ID, "city should store shrine development")
	test_assert.eq(player.victory_points, starting_vp + 1, "shrine should grant one victory point")


static func _test_unknown_id_falls_back_to_watchtower(test_assert: TestAssert) -> void:
	test_assert.eq(
		DevelopmentCatalog.resolve_build_id("mystery_card"),
		DevelopmentCatalog.WATCHTOWER_ID,
		"unknown development ids should fall back to watchtower"
	)
