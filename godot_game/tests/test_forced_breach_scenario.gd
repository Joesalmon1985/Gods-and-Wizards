class_name TestForcedBreachScenario
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_core_end_turn_forced_breach(test_assert)
	_test_session_end_turn_records_breach(test_assert)
	_test_audit_view_model_exposes_breach(test_assert)
	_test_play_summary_shows_breach(test_assert)
	_test_playthrough_breach_row_visible(test_assert)


static func _test_core_end_turn_forced_breach(test_assert: TestAssert) -> void:
	var setup := _forced_breach_setup()
	var state: GameState = setup["state"]
	var node: BoardNode = setup["node"]
	var breach_before := state.breach_count
	var end_turn := _end_turn_action(state)
	var events := ActionRules.apply(state, end_turn)

	test_assert.eq(SetupRules.get_demon_count(state, node), 3, "capped node should stay at 3 demons")
	test_assert.eq(state.breach_count, breach_before + 1, "breach_count should increment by exactly 1")
	test_assert.check(_has_breach_event(events), "END_TURN spread should emit BreachEvent")


static func _test_session_end_turn_records_breach(test_assert: TestAssert) -> void:
	var session := _session_after_forced_breach_end_turn(test_assert)
	test_assert.eq(session.state.breach_count, 1, "session state should reflect breach increment")
	test_assert.check(_events_include_breach(session.events), "session event log should include breach")


static func _test_audit_view_model_exposes_breach(test_assert: TestAssert) -> void:
	var session := _session_after_forced_breach_end_turn(test_assert)
	var model := StrategicAuditViewModel.build(session)
	test_assert.eq(int(model.get("breach_count", -1)), 1, "audit view-model should expose updated breach_count")
	var header: String = str(model.get("header_text", ""))
	test_assert.check(header.contains("Breach: 1"), "audit header should show breach count")


static func _test_play_summary_shows_breach(test_assert: TestAssert) -> void:
	var setup := _forced_breach_setup()
	var state: GameState = setup["state"]
	var end_turn := _end_turn_action(state)
	var events := ActionRules.apply(state, end_turn)
	var lines := EventSummary.summarize_events(events, state)
	test_assert.check(_lines_contain(lines, "underworld breach"), "event summary should describe breach")
	test_assert.check(_lines_contain(lines, "total breaches: 1"), "event summary should show breach total")

	var log_line := EventSummary.summarize_event_entry("breach", {"breach_count": 1}, state)
	test_assert.check(log_line.contains("underworld breach"), "breach log entry should be readable")


static func _test_playthrough_breach_row_visible(test_assert: TestAssert) -> void:
	var session := _session_after_forced_breach_end_turn(test_assert)
	var rows := PlaythroughCsvExporter.build_rows(session)
	var breach_row: Dictionary = {}
	for row in rows:
		if str(row.get("event_type", "")) == "breach":
			breach_row = row
			break

	test_assert.check(not breach_row.is_empty(), "playthrough should include a breach row")
	test_assert.check(
		str(breach_row.get("event_summary", "")).contains("underworld breach"),
		"playthrough breach row should have readable summary"
	)
	test_assert.eq(
		str(breach_row.get("demon_breach_info", "")),
		"breach=1,demons=3",
		"playthrough breach row should show replayed breach and demon totals"
	)


static func _session_after_forced_breach_end_turn(test_assert: TestAssert) -> BotGameSession:
	var setup := _forced_breach_setup()
	var session := BotGameSession.start_one_human_three_bots(5551, 0)
	session.state = setup["state"]
	session.events.clear()
	session.event_log = EventLog.new()
	session.replay_baseline = EventLogReplay.capture_baseline(session.state)
	session.waiting_for_human = true
	session.waiting_for_draft = false
	session.finished = false
	var applied := session.submit_human_action(_end_turn_action(session.state))
	test_assert.check(not applied.is_empty(), "human END_TURN should apply through session API")
	test_assert.check(_events_include_breach(applied), "session should return BreachEvent from END_TURN")
	return session


static func _forced_breach_setup() -> Dictionary:
	var state := ScenarioBuilder.build_bot_ready_game(5551)
	GameStartRules.start_game(state)
	var node := _pick_infection_target_node(state)
	SetupRules.set_demon_count(state, node, 3)
	state.breach_count = 0
	state.infection_rate = 1
	state.infection_draw_pile = [node.to_key()]
	state.infection_discard_pile.clear()
	return {"state": state, "node": node}


static func _pick_infection_target_node(state: GameState) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if state.cities_by_vertex.has(node.to_key()):
			continue
		if state.heroes_by_node.has(node.to_key()):
			continue
		return node
	return state.board.get_all_nodes_sorted()[0]


static func _end_turn_action(state: GameState) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.END_TURN:
			return action
	return state.action_space.get_action(0)


static func _has_breach_event(events: Array) -> bool:
	for event in events:
		if event is BreachEvent:
			return true
	return false


static func _events_include_breach(events: Array) -> bool:
	return _has_breach_event(events)


static func _lines_contain(lines: Array, fragment: String) -> bool:
	for line in lines:
		if fragment in str(line):
			return true
	return false
