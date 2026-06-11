class_name TestBankTrade
extends RefCounted

const TRADE_RATE := 4


static func run(test_assert: TestAssert) -> void:
	_test_bank_trade_illegal_with_insufficient_resources(test_assert)
	_test_bank_trade_legal_and_mutates_resources(test_assert)
	_test_bank_trade_same_resource_not_in_action_space(test_assert)
	_test_bank_trade_event_logged(test_assert)
	_test_bank_trade_in_legal_mask_when_affordable(test_assert)
	_test_human_session_accepts_legal_bank_trade(test_assert)


static func _test_bank_trade_illegal_with_insufficient_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(1)
	var player := state.players[0]
	player.resources[ResourceType.Type.WOOD] = 3
	var action := _find_bank_trade_action(state, ResourceType.Type.WOOD, ResourceType.Type.BRICK)
	test_assert.check(action != null, "bank trade action should exist in action space")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		not view.legal_mask[action.action_id],
		"bank trade should be illegal with only 3 wood"
	)
	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 0, "illegal bank trade should produce no events")
	test_assert.eq(player.get_resource(ResourceType.Type.WOOD), 3, "wood should remain unchanged")


static func _test_bank_trade_legal_and_mutates_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(2)
	var player := state.players[0]
	player.resources[ResourceType.Type.WOOD] = 4
	player.resources[ResourceType.Type.BRICK] = 1
	var action := _find_bank_trade_action(state, ResourceType.Type.WOOD, ResourceType.Type.BRICK)
	test_assert.check(action != null, "bank trade action should exist")
	var events := ActionRules.apply(state, action)
	test_assert.check(not events.is_empty(), "legal bank trade should apply")
	test_assert.eq(player.get_resource(ResourceType.Type.WOOD), 0, "wood should decrease by 4")
	test_assert.eq(player.get_resource(ResourceType.Type.BRICK), 2, "brick should increase by 1")


static func _test_bank_trade_same_resource_not_in_action_space(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(3)
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BANK_TRADE:
			continue
		test_assert.check(
			action.give_resource != action.receive_resource,
			"bank trade should not trade a resource for itself"
		)


static func _test_bank_trade_event_logged(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(4)
	state.players[0].resources[ResourceType.Type.WHEAT] = 4
	var action := _find_bank_trade_action(state, ResourceType.Type.WHEAT, ResourceType.Type.ORE)
	var events := ActionRules.apply(state, action)
	test_assert.eq(events.size(), 1, "bank trade should emit one event")
	test_assert.check(events[0] is BankTradeEvent, "bank trade event type should be BankTradeEvent")


static func _test_bank_trade_in_legal_mask_when_affordable(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(5)
	state.players[0].resources[ResourceType.Type.SHEEP] = 4
	var action := _find_bank_trade_action(state, ResourceType.Type.SHEEP, ResourceType.Type.ORE)
	var view := LegalActionQuery.get_view(state)
	test_assert.check(view.legal_mask[action.action_id], "affordable bank trade should be legal")


static func _test_human_session_accepts_legal_bank_trade(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(6, 0)
	while not session.is_waiting_for_human() and not session.finished:
		session.advance_until_human_or_game_over()
	test_assert.check(session.is_waiting_for_human(), "human session should pause for human")
	session.state.players[0].resources[ResourceType.Type.WOOD] = 4
	var wood_before := session.state.players[0].get_resource(ResourceType.Type.WOOD)
	var trade_action: GameAction = null
	for action in session.get_legal_human_actions():
		if action.kind == ActionKind.Kind.BANK_TRADE and action.give_resource == ResourceType.Type.WOOD and action.receive_resource == ResourceType.Type.BRICK:
			trade_action = action
			break
	test_assert.check(trade_action != null, "human should have legal bank trade action")
	var applied := session.submit_human_action(trade_action)
	test_assert.check(not applied.is_empty(), "human session should accept legal bank trade")
	test_assert.eq(session.state.players[0].get_resource(ResourceType.Type.WOOD), wood_before - TRADE_RATE, "session bank trade should deduct wood")


static func _find_bank_trade_action(
	state: GameState,
	give: ResourceType.Type,
	receive: ResourceType.Type
) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BANK_TRADE:
			continue
		if action.give_resource == give and action.receive_resource == receive:
			return action
	return null
