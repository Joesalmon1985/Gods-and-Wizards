class_name TestTradeOfferAccept
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_offer_requires_resources(test_assert)
	_test_accept_transfers_resources(test_assert)
	_test_accept_illegal_without_partner_resources(test_assert)
	_test_duplicate_offer_same_turn_illegal(test_assert)
	_test_reject_leaves_resources(test_assert)
	_test_player_trade_deprecated(test_assert)
	_test_bot_accepts_deterministically(test_assert)


static func _test_offer_requires_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(1)
	state.players[0].resources[ResourceType.Type.WOOD] = 1
	var action := _find_trade_offer(state, 1, ResourceType.Type.WOOD, 2, ResourceType.Type.BRICK, 1)
	test_assert.check(action != null, "trade offer action should exist")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(not view.legal_mask[action.action_id], "offer illegal when active lacks resources")


static func _test_accept_transfers_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(2)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer_action := _find_trade_offer(state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1)
	ActionRules.apply(state, offer_action)
	state.active_player_index = 1
	TurnLifecycleRules.on_turn_start(state)
	var accept_action := _find_trade_accept(state, 1)
	test_assert.check(accept_action != null, "accept action should exist for pending offer")
	var offerer_wood_before := state.players[0].get_resource(ResourceType.Type.WOOD)
	var offerer_brick_before := state.players[0].get_resource(ResourceType.Type.BRICK)
	var acceptor_wood_before := state.players[1].get_resource(ResourceType.Type.WOOD)
	var acceptor_brick_before := state.players[1].get_resource(ResourceType.Type.BRICK)
	var events := ActionRules.apply(state, accept_action)
	test_assert.check(not events.is_empty(), "accept should apply")
	test_assert.eq(
		state.players[0].get_resource(ResourceType.Type.WOOD),
		offerer_wood_before - 1,
		"offerer loses wood on accept"
	)
	test_assert.eq(
		state.players[0].get_resource(ResourceType.Type.BRICK),
		offerer_brick_before + 1,
		"offerer gains brick on accept"
	)
	test_assert.eq(
		state.players[1].get_resource(ResourceType.Type.BRICK),
		acceptor_brick_before - 1,
		"acceptor loses brick"
	)
	test_assert.eq(
		state.players[1].get_resource(ResourceType.Type.WOOD),
		acceptor_wood_before + 1,
		"acceptor gains wood"
	)


static func _test_accept_illegal_without_partner_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(3)
	state.players[0].resources[ResourceType.Type.WHEAT] = 1
	var offer_action := _find_trade_offer(state, 1, ResourceType.Type.WHEAT, 1, ResourceType.Type.ORE, 1)
	ActionRules.apply(state, offer_action)
	state.active_player_index = 1
	TurnLifecycleRules.on_turn_start(state)
	state.players[1].resources[ResourceType.Type.ORE] = 0
	var accept_action := _find_trade_accept(state, 1)
	var view := LegalActionQuery.get_view(state)
	test_assert.check(not view.legal_mask[accept_action.action_id], "accept illegal when target lacks requested resources")


static func _test_duplicate_offer_same_turn_illegal(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(4)
	state.players[0].resources[ResourceType.Type.WOOD] = 3
	var offer_action := _find_trade_offer(state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1)
	ActionRules.apply(state, offer_action)
	var view := LegalActionQuery.get_view(state)
	test_assert.check(not view.legal_mask[offer_action.action_id], "duplicate offer to same target should be illegal")


static func _test_reject_leaves_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(5)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	var offer_action := _find_trade_offer(state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.SHEEP, 1)
	ActionRules.apply(state, offer_action)
	state.active_player_index = 1
	TurnLifecycleRules.on_turn_start(state)
	var wood_before := state.players[0].get_resource(ResourceType.Type.WOOD)
	var reject_action := _find_trade_reject(state, 1)
	ActionRules.apply(state, reject_action)
	test_assert.eq(state.players[0].get_resource(ResourceType.Type.WOOD), wood_before, "reject should not transfer resources")


static func _test_player_trade_deprecated(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(6)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var legacy := _find_legacy_player_trade(state, 1, ResourceType.Type.WOOD, ResourceType.Type.BRICK)
	if legacy != null:
		var view := LegalActionQuery.get_view(state)
		test_assert.check(not view.legal_mask[legacy.action_id], "legacy PLAYER_TRADE should not be legal")


static func _test_bot_accepts_deterministically(test_assert: TestAssert) -> void:
	var state_a := ScenarioBuilder.build_four_player_bot_game(8)
	var state_b := ScenarioBuilder.build_four_player_bot_game(8)
	_setup_accept_scenario(state_a)
	_setup_accept_scenario(state_b)
	state_a.active_player_index = 1
	state_b.active_player_index = 1
	TurnLifecycleRules.on_turn_start(state_a)
	TurnLifecycleRules.on_turn_start(state_b)
	var accept_a := _find_trade_accept(state_a, 1)
	var accept_b := _find_trade_accept(state_b, 1)
	test_assert.check(LegalActionQuery.get_view(state_a).legal_mask[accept_a.action_id], "accept should be legal")
	ActionRules.apply(state_a, accept_a)
	ActionRules.apply(state_b, accept_b)
	test_assert.eq(
		_trade_resource_signature(state_a),
		_trade_resource_signature(state_b),
		"accept transfer should be deterministic"
	)


static func _trade_resource_signature(state: GameState) -> String:
	var parts: Array[String] = []
	for player in state.players:
		for resource in ResourceType.all():
			parts.append("%d:%s=%d" % [player.id, ResourceType.to_key(resource), player.get_resource(resource)])
	return "|".join(parts)


static func _setup_accept_scenario(state: GameState) -> void:
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer_action := _find_trade_offer(state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1)
	ActionRules.apply(state, offer_action)


static func _find_trade_offer(
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


static func _find_trade_accept(state: GameState, offer_id: int) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.TRADE_ACCEPT and action.trade_offer_id == offer_id:
			return action
	return null


static func _find_trade_reject(state: GameState, offer_id: int) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.TRADE_REJECT and action.trade_offer_id == offer_id:
			return action
	return null


static func _find_legacy_player_trade(
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
