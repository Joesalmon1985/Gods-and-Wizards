class_name TestPlayerTrade
extends RefCounted


static func run(test_assert: TestAssert) -> void:
	_test_player_trade_illegal_when_partner_lacks_resource(test_assert)
	_test_player_trade_mutates_both_players(test_assert)
	_test_human_session_accepts_legal_player_trade(test_assert)


static func _test_player_trade_illegal_when_partner_lacks_resource(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(1)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 0
	var action := _find_player_trade(state, 1, ResourceType.Type.WOOD, ResourceType.Type.BRICK)
	test_assert.check(action != null, "player trade action should exist")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(not view.legal_mask[action.action_id], "trade illegal when partner lacks brick")


static func _test_player_trade_mutates_both_players(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(2)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[0].resources[ResourceType.Type.BRICK] = 0
	state.players[1].resources[ResourceType.Type.BRICK] = 3
	state.players[1].resources[ResourceType.Type.WOOD] = 0
	var action := _find_player_trade(state, 1, ResourceType.Type.WOOD, ResourceType.Type.BRICK)
	var events := ActionRules.apply(state, action)
	test_assert.check(not events.is_empty(), "legal player trade should apply")
	test_assert.eq(state.players[0].get_resource(ResourceType.Type.WOOD), 1, "active player loses wood")
	test_assert.eq(state.players[0].get_resource(ResourceType.Type.BRICK), 1, "active player gains brick")
	test_assert.eq(state.players[1].get_resource(ResourceType.Type.BRICK), 2, "partner loses brick")
	test_assert.eq(state.players[1].get_resource(ResourceType.Type.WOOD), 1, "partner gains wood")


static func _test_human_session_accepts_legal_player_trade(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(3, 0)
	session.state.players[0].resources[ResourceType.Type.WHEAT] = 1
	session.state.players[1].resources[ResourceType.Type.ORE] = 1
	var trade_action: GameAction = null
	for action in session.get_legal_human_actions():
		if action.kind == ActionKind.Kind.PLAYER_TRADE and action.partner_player_id == 1:
			if action.give_resource == ResourceType.Type.WHEAT and action.receive_resource == ResourceType.Type.ORE:
				trade_action = action
				break
	test_assert.check(trade_action != null, "human should have legal player trade")
	var applied := session.submit_human_action(trade_action)
	test_assert.check(not applied.is_empty(), "session should accept player trade")


static func _find_player_trade(
	state: GameState,
	partner_id: int,
	give: ResourceType.Type,
	receive: ResourceType.Type
) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.PLAYER_TRADE:
			continue
		if action.partner_player_id == partner_id and action.give_resource == give and action.receive_resource == receive:
			return action
	return null
