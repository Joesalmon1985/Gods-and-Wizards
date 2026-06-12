class_name TestDevelopmentCatalog
extends RefCounted

const SAMPLE_NO_VP_ID := "lumber_camp_a1"
const SAMPLE_VP_ID := "monument_a1"


static func run(test_assert: TestAssert) -> void:
	_test_catalog_entries(test_assert)
	_test_no_vp_build(test_assert)
	_test_vp_card_grants_victory_point(test_assert)
	_test_unknown_id_falls_back_to_first(test_assert)


static func _test_catalog_entries(test_assert: TestAssert) -> void:
	var ids := DevelopmentCatalog.all_ids_sorted()
	test_assert.eq(ids.size(), 96, "catalog should expose 96 development cards")
	test_assert.check(DevelopmentCatalog.has_id(SAMPLE_NO_VP_ID), "sample production card should exist")
	test_assert.check(DevelopmentCatalog.has_id(SAMPLE_VP_ID), "sample vp card should exist")


static func _test_no_vp_build(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var player := state.players[0]
	_grant_build_resources(state, player.id)
	player.development_hand.append(SAMPLE_NO_VP_ID)
	var city_vertex := state.cities[0].vertex
	var events := DevelopmentRules.apply(state, player.id, city_vertex, SAMPLE_NO_VP_ID)
	test_assert.check(events[0] is DevelopmentBuiltEvent, "build should emit DevelopmentBuiltEvent")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.developments[0], SAMPLE_NO_VP_ID, "city should store built card")
	test_assert.eq(events.size(), 1, "production card should not grant bonus victory points on play")


static func _test_vp_card_grants_victory_point(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(5)
	var player := state.players[0]
	_grant_build_resources(state, player.id)
	var starting_vp := player.victory_points
	player.development_hand.append(SAMPLE_VP_ID)
	var city_vertex := state.cities[0].vertex
	var events := DevelopmentRules.apply(state, player.id, city_vertex, SAMPLE_VP_ID)
	test_assert.check(events.size() >= 2, "vp card build should emit development and scoring events")
	var city: City = state.cities_by_vertex[city_vertex.to_key()]
	test_assert.eq(city.developments[0], SAMPLE_VP_ID, "city should store vp development")
	test_assert.eq(player.victory_points, starting_vp + 1, "monument should grant one victory point")


static func _test_unknown_id_falls_back_to_first(test_assert: TestAssert) -> void:
	var first_id := DevelopmentCatalog.all_ids_sorted()[0]
	test_assert.eq(
		DevelopmentCatalog.resolve_build_id("mystery_card"),
		first_id,
		"unknown development ids should fall back to first catalog id"
	)


static func _grant_build_resources(state: GameState, player_id: int) -> void:
	SetupRules.grant_resources(state, player_id, {
		ResourceType.Type.WHEAT: 2,
		ResourceType.Type.SHEEP: 2,
		ResourceType.Type.ORE: 2,
	})
