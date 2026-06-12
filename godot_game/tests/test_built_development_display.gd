class_name TestBuiltDevelopmentDisplay
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_model_from_session(test_assert)
	_test_display_does_not_mutate_game_state(test_assert)
	_test_empty_city_no_indicators(test_assert)
	_test_built_city_shows_hybrid_indicators(test_assert)
	_test_occupied_city_still_shows_developments(test_assert)


static func _test_model_from_session(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	var state := session.state
	if not state.cities.is_empty():
		state.cities[0].developments.append("lumber_camp_a1")
	var indicators := WizardWorldDevelopmentPresenter.build_from_session(session)
	test_assert.check(indicators.size() >= 1, "built developments should produce indicators")
	var model := StrategicDevelopmentViewModel.build(session, state.cities[0].player_id)
	var node_positions := {}
	for node in BoardWorldMapper.build_snapshot(state, []).get("nodes", []):
		node_positions[node.get("id", "")] = Vector3(
			float(node.get("world", {}).get("x", 0.0)),
			0.0,
			float(node.get("world", {}).get("z", 0.0))
		)
	var from_model := WizardWorldDevelopmentPresenter.build_from_development_model(model, node_positions)
	test_assert.check(from_model.size() >= 1, "indicators should derive from StrategicDevelopmentViewModel city slots")


static func _test_display_does_not_mutate_game_state(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(7)
	var demons_before := _total_demons(session.state)
	var cities_before := session.state.cities.size()
	WizardWorldDevelopmentPresenter.build_from_session(session)
	test_assert.eq(_total_demons(session.state), demons_before, "development display must not mutate demons")
	test_assert.eq(session.state.cities.size(), cities_before, "development display must not mutate cities")


static func _test_empty_city_no_indicators(test_assert: TestAssert) -> void:
	var snapshot := {
		"nodes": [{"id": "n0", "world": {"x": 0.0, "y": 0.0, "z": 0.0}}],
		"cities": [{"node_id": "n0", "development_ids": []}],
	}
	var indicators := WizardWorldDevelopmentPresenter.build_from_snapshot(snapshot)
	test_assert.eq(indicators.size(), 0, "city with no built developments should show no indicators")


static func _test_built_city_shows_hybrid_indicators(test_assert: TestAssert) -> void:
	var snapshot := {
		"nodes": [{"id": "n0", "world": {"x": 0.0, "y": 0.0, "z": 0.0}}],
		"cities": [{"node_id": "n0", "development_ids": ["lumber_camp_a1", "brickworks_a1"]}],
	}
	var indicators := WizardWorldDevelopmentPresenter.build_from_snapshot(snapshot)
	test_assert.eq(indicators.size(), 2, "city with two built developments should show two indicators")
	for entry in indicators:
		test_assert.check(entry.has("icon_id"), "indicator should include icon id")
		test_assert.check(entry.has("uses_generic_fallback"), "indicator should note generic fallback usage")


static func _test_occupied_city_still_shows_developments(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(9)
	var state := session.state
	if state.cities.is_empty():
		test_assert.check(true, "skip occupied-city test when no cities")
		return
	var city: City = state.cities[0]
	city.developments.append("market_stall_a1")
	state.demon_counts_by_node[city.vertex.to_key()] = 2
	var indicators := WizardWorldDevelopmentPresenter.build_from_session(session)
	test_assert.check(indicators.size() >= 1, "occupied city should still show built developments read-only")


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total
