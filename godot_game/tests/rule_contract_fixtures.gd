class_name RuleContractFixtures
extends RefCounted


static func forced_breach_setup(seed: int = 5551) -> Dictionary:
	var state := ScenarioBuilder.build_bot_ready_game(seed)
	GameStartRules.start_game(state)
	var node := pick_infection_target_node(state)
	SetupRules.set_demon_count(state, node, SpreadRules.MAX_DEMONS_PER_NODE)
	state.breach_count = 0
	state.infection_rate = 1
	state.infection_draw_pile = [node.to_key()]
	state.infection_discard_pile.clear()
	return {"state": state, "node": node}


static func pick_infection_target_node(state: GameState) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if state.cities_by_vertex.has(node.to_key()):
			continue
		if state.heroes_by_node.has(node.to_key()):
			continue
		return node
	return state.board.get_all_nodes_sorted()[0]


static func end_turn_action(state: GameState) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.END_TURN:
			return action
	return state.action_space.get_action(0)


static func session_after_forced_breach_end_turn(test_assert: TestAssert, seed: int = 5551) -> BotGameSession:
	var setup := forced_breach_setup(seed)
	var session := BotGameSession.start_one_human_three_bots(seed, 0)
	session.state = setup["state"]
	session.events.clear()
	session.event_log = EventLog.new()
	session.replay_baseline = EventLogReplay.capture_baseline(session.state)
	session.waiting_for_human = true
	session.waiting_for_draft = false
	session.finished = false
	var applied := session.submit_human_action(end_turn_action(session.state))
	test_assert.check(not applied.is_empty(), "human END_TURN should apply through session API")
	return session


static func play_status_line(summary: Dictionary, human_player_id: int = 0) -> String:
	return "Waiting for human (player %d) | phase=%s | infection=%d | breach=%d/%d" % [
		human_player_id,
		summary.get("phase", "?"),
		int(summary.get("infection_rate", 0)),
		int(summary.get("breach_count", 0)),
		int(summary.get("breach_limit", GameConstants.BREACH_LIMIT)),
	]


static func has_breach_event(events: Array) -> bool:
	for event in events:
		if event is BreachEvent:
			return true
	return false


static func find_trade_offer(
	state: GameState,
	partner_id: int,
	give: ResourceType.Type,
	give_amount: int,
	receive: ResourceType.Type,
	request_amount: int
) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.TRADE_OFFER:
			continue
		if (
			action.partner_player_id == partner_id
			and action.give_resource == give
			and action.receive_resource == receive
			and action.give_amount == give_amount
			and action.request_amount == request_amount
		):
			return action
	return null


static func find_trade_accept(state: GameState, offer_id: int) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.TRADE_ACCEPT and action.trade_offer_id == offer_id:
			return action
	return null
