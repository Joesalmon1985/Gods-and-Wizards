class_name TestRuleContractExport
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_playthrough_includes_breach_trade_draft_dev_events(test_assert)
	_test_macro_export_still_deterministic(test_assert)
	_test_legal_mask_matches_query_fixture_states(test_assert)


static func _test_playthrough_includes_breach_trade_draft_dev_events(test_assert: TestAssert) -> void:
	var session := _build_export_fixture_session(test_assert)
	var rows := PlaythroughCsvExporter.build_rows(session)
	test_assert.check(not rows.is_empty(), "fixture session should produce playthrough rows")

	var event_types := {}
	for row in rows:
		var event_type := str(row.get("event_type", ""))
		if event_type != "":
			event_types[event_type] = true

	test_assert.check(event_types.has("breach"), "playthrough should include breach event row")
	test_assert.check(
		event_types.has("trade_offer_made") or event_types.has("trade_accepted"),
		"playthrough should include trade event row"
	)
	test_assert.check(
		event_types.has("development_built"),
		"playthrough should include development_built event row"
	)


static func _build_export_fixture_session(test_assert: TestAssert) -> BotGameSession:
	var setup := RuleContractFixtures.forced_breach_setup(7001)
	var session := BotGameSession.start_one_human_three_bots(7001, 0)
	session.state = setup["state"]
	session.events.clear()
	session.event_log = EventLog.new()
	session.replay_baseline = EventLogReplay.capture_baseline(session.state)
	session.waiting_for_human = true
	session.waiting_for_draft = false
	session.finished = false

	session.state.players[0].resources[ResourceType.Type.WOOD] = 2
	session.state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		session.state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	var trade_events := session.submit_human_action(offer)
	test_assert.check(not trade_events.is_empty(), "fixture should apply trade offer through session")

	var player_city: City = null
	for city in session.state.cities:
		if city.player_id == 0:
			player_city = city
			break
	test_assert.check(player_city != null, "fixture should have a city for player 0")
	session.state.players[0].development_hand.append("lumber_camp_a1")
	_grant_build_resources(session.state, 0)
	SetupRules.rebuild_action_space(session.state)
	var dev_action := _find_build_development(session.state, player_city.vertex, "lumber_camp_a1")
	test_assert.check(dev_action != null, "fixture should find BUILD_DEVELOPMENT action")
	var dev_events := session.submit_human_action(dev_action)
	test_assert.check(not dev_events.is_empty(), "fixture should build development card through session")

	var breach_events := session.submit_human_action(RuleContractFixtures.end_turn_action(session.state))
	test_assert.check(RuleContractFixtures.has_breach_event(breach_events), "fixture END_TURN should breach")
	return session


static func _test_macro_export_still_deterministic(test_assert: TestAssert) -> void:
	var rows_a := MacroTrainingTelemetryExporter.run_episode(7010, 15, BotTurnResolver.POLICY_HEURISTIC)
	var rows_b := MacroTrainingTelemetryExporter.run_episode(7010, 15, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.eq(
		MacroTrainingTelemetryExporter.render_csv(rows_a),
		MacroTrainingTelemetryExporter.render_csv(rows_b),
		"macro export should remain deterministic after rule-contract additions"
	)


static func _test_legal_mask_matches_query_fixture_states(test_assert: TestAssert) -> void:
	var seeds := [42, 77, 99]
	for seed in seeds:
		var state := ScenarioBuilder.build_bot_ready_game(seed)
		GameStartRules.start_game(state)
		var view := LegalActionQuery.get_view(state)
		for action in state.action_space.all_actions_sorted():
			var expected := view.legal_mask[action.action_id]
			var direct := _direct_legality(state, action)
			test_assert.eq(
				expected,
				direct,
				"seed %d action %d legality should match query view" % [seed, action.action_id]
			)


static func _direct_legality(state: GameState, action: GameAction) -> bool:
	for candidate in LegalActionQuery.get_legal_actions_sorted(state):
		if candidate.action_id == action.action_id:
			return true
	return false


static func _find_build_development(state: GameState, vertex: BoardNode, development_id: String) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind != ActionKind.Kind.BUILD_DEVELOPMENT:
			continue
		if action.development_id != development_id:
			continue
		if action.vertex != null and action.vertex.equals(vertex):
			return action
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_DEVELOPMENT:
			continue
		if action.development_id == development_id and action.vertex.equals(vertex):
			return action
	return null


static func _grant_build_resources(state: GameState, player_id: int) -> void:
	var player := state.players[player_id]
	for resource in ResourceType.all():
		player.resources[resource] = 5
