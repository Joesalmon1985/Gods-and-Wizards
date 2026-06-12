class_name TestRuleContractTrading
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_active_player_can_offer(test_assert)
	_test_non_active_cannot_offer_as_prior_player(test_assert)
	_test_target_accepts_on_their_turn(test_assert)
	_test_non_target_cannot_accept(test_assert)
	_test_offer_dedup_clears_after_end_turn(test_assert)
	_test_pending_offer_expires_at_offerer_end_turn(test_assert)
	_test_expired_offer_cannot_be_accepted(test_assert)
	_test_trade_events_emitted(test_assert)


static func _test_active_player_can_offer(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(10)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	test_assert.check(offer != null, "trade offer action should exist in action space")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(view.legal_mask[offer.action_id], "active player should have legal TRADE_OFFER")
	var events := ActionRules.apply(state, offer)
	test_assert.check(not events.is_empty(), "active player offer should apply")
	test_assert.eq(state.pending_trade_offers.size(), 1, "offer should create pending trade")


static func _test_non_active_cannot_offer_as_prior_player(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(11)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.WOOD] = 2
	var offer_p0 := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	test_assert.check(LegalActionQuery.get_view(state).legal_mask[offer_p0.action_id], "P0 should offer while active")

	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.active_player_index, 1, "turn should pass to player 1")

	var offer_while_p1_active := RuleContractFixtures.find_trade_offer(
		state, 0, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	test_assert.check(offer_while_p1_active != null, "offer slot should exist while P1 active")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		view.legal_mask[offer_while_p1_active.action_id],
		"P1 should be able to offer on their turn"
	)

	var prior_player_offer := RuleContractFixtures.find_trade_offer(
		state, 2, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, prior_player_offer)
	test_assert.check(not state.pending_trade_offers.is_empty(), "P1 offer should bind to active player")
	var latest: TradeOffer = state.pending_trade_offers.back()
	test_assert.eq(latest.from_player_id, 1, "offerer must be active player, not prior player")


static func _test_target_accepts_on_their_turn(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(12)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.active_player_index, 1, "target should become active player")

	var accept := RuleContractFixtures.find_trade_accept(state, 1)
	test_assert.check(accept != null, "accept action should exist for pending offer")
	test_assert.check(
		LegalActionQuery.get_view(state).legal_mask[accept.action_id],
		"target should accept on their turn"
	)
	var events := ActionRules.apply(state, accept)
	test_assert.check(not events.is_empty(), "accept should apply on target turn")
	test_assert.eq(state.pending_trade_offers.size(), 0, "accept should remove pending offer")


static func _test_non_target_cannot_accept(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(13)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)

	for _i in 2:
		ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.active_player_index, 2, "player 2 should be active")

	var accept := RuleContractFixtures.find_trade_accept(state, 1)
	test_assert.check(accept != null, "accept action exists in space")
	test_assert.check(
		not LegalActionQuery.get_view(state).legal_mask[accept.action_id],
		"non-target active player cannot accept offer meant for player 1"
	)


static func _test_offer_dedup_clears_after_end_turn(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(14)
	state.players[0].resources[ResourceType.Type.WOOD] = 3
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)
	test_assert.check(
		not LegalActionQuery.get_view(state).legal_mask[offer.action_id],
		"duplicate offer blocked same turn"
	)
	test_assert.eq(state.trade_offers_made_this_turn.size(), 1, "dedup signature should be recorded")
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(
		state.trade_offers_made_this_turn.size(),
		0,
		"END_TURN should clear offer dedup signatures"
	)

	state.active_player_index = 0
	state.awaiting_draft_step = false
	state.current_phase = TurnPhase.Phase.ACTIVE_PLAYER
	TurnLifecycleRules.on_turn_start(state)
	test_assert.check(
		LegalActionQuery.get_view(state).legal_mask[offer.action_id],
		"same offer signature should be legal again after dedup reset on offerer turn"
	)


static func _test_pending_offer_expires_at_offerer_end_turn(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(15)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)
	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.pending_trade_offers.size(), 1, "offer survives offerer END_TURN same cycle for target accept")
	for _i in TurnRules.player_count(state) - 1:
		ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	test_assert.eq(state.pending_trade_offers.size(), 0, "offer expires when offerer END_TURN after full cycle")


static func _test_expired_offer_cannot_be_accepted(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(17)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	ActionRules.apply(state, offer)
	for _i in TurnRules.player_count(state) - 1:
		ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	var accept := RuleContractFixtures.find_trade_accept(state, 1)
	if accept != null:
		test_assert.check(
			not LegalActionQuery.get_view(state).legal_mask[accept.action_id],
			"expired offer cannot be accepted"
		)


static func _test_trade_events_emitted(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(16)
	state.players[0].resources[ResourceType.Type.WOOD] = 2
	state.players[1].resources[ResourceType.Type.BRICK] = 2
	var offer := RuleContractFixtures.find_trade_offer(
		state, 1, ResourceType.Type.WOOD, 1, ResourceType.Type.BRICK, 1
	)
	var offer_events := ActionRules.apply(state, offer)
	var offer_event_found := false
	for event in offer_events:
		if event is TradeOfferMadeEvent:
			offer_event_found = true
	test_assert.check(offer_event_found, "offer should emit TradeOfferMadeEvent")

	ActionRules.apply(state, RuleContractFixtures.end_turn_action(state))
	var accept := RuleContractFixtures.find_trade_accept(state, 1)
	var accept_events := ActionRules.apply(state, accept)
	var accept_event_found := false
	for event in accept_events:
		if event is TradeAcceptedEvent:
			accept_event_found = true
	test_assert.check(accept_event_found, "accept should emit TradeAcceptedEvent")
