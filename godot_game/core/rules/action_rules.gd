class_name ActionRules
extends RefCounted

static func apply(state: GameState, action: GameAction) -> Array:
	var view := LegalActionQuery.get_view(state)
	if action.action_id < 0 or action.action_id >= view.legal_mask.size():
		return []
	if not view.legal_mask[action.action_id]:
		return []

	match action.kind:
		ActionKind.Kind.END_TURN:
			return _apply_end_turn(state)
		ActionKind.Kind.BUILD_CITY:
			return _apply_build_city(state, action)
		ActionKind.Kind.BUILD_ROAD:
			return _apply_build_road(state, action)
		ActionKind.Kind.MOVE_HERO:
			return _apply_move_hero(state, action)
		ActionKind.Kind.BUILD_DEVELOPMENT:
			return _apply_build_development(state, action)
		ActionKind.Kind.BANK_TRADE:
			return _apply_bank_trade(state, action)
		ActionKind.Kind.PLAYER_TRADE:
			return []
		ActionKind.Kind.TRADE_OFFER:
			return _apply_trade_offer(state, action)
		ActionKind.Kind.TRADE_ACCEPT:
			return _apply_trade_accept(state, action)
		ActionKind.Kind.TRADE_REJECT:
			return _apply_trade_reject(state, action)
		ActionKind.Kind.DRAFT_PICK:
			return _apply_draft_pick(state, action)
		_:
			return []


static func _apply_draft_pick(state: GameState, action: GameAction) -> Array:
	if not DraftRules.record_draft_pick(state, action.draft_player_id, action.development_id):
		return []
	var events: Array = []
	SetupRules.rebuild_action_space(state)
	if DraftRules.all_picks_received(state):
		events.append_array(DraftRules.finalize_round_after_draft(state))
	return events


static func _apply_build_city(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null or action.vertex == null:
		return []
	if not BuildRules.can_build_city(state, player.id, action.vertex):
		return []
	if not BuildCosts.can_afford(player, BuildCosts.BUILD_CITY):
		return []

	player.pay_cost(BuildCosts.BUILD_CITY)
	var city := SetupRules.place_city(state, player.id, action.vertex)
	if city == null:
		return []

	var events: Array = [CityBuiltEvent.new(state.round_number, player.id, action.vertex)]
	events.append_array(ScoreRules.apply_city_victory_points(state, player.id))
	return events


static func _apply_build_road(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null or action.edge == null:
		return []
	if not BuildRules.can_build_road(state, player.id, action.edge):
		return []
	if not BuildCosts.can_afford(player, BuildCosts.BUILD_ROAD):
		return []

	player.pay_cost(BuildCosts.BUILD_ROAD)
	var road := SetupRules.place_road(state, player.id, action.edge)
	if road == null:
		return []
	return [RoadBuiltEvent.new(state.round_number, player.id, action.edge)]


static func _apply_move_hero(state: GameState, action: GameAction) -> Array:
	var hero := MoveRules.get_hero(state, action.hero_id)
	if hero == null:
		return []
	var target_key := action.target_node.to_key()
	if state.heroes_by_node.has(target_key):
		var occupant: Hero = state.heroes_by_node[target_key]
		if occupant.player_id != hero.player_id:
			return ContactResolutionRules.resolve_hostile_hero_clash(
				state,
				hero,
				occupant,
				action.target_node
			)
	var from_node := hero.node
	state.heroes_by_node.erase(from_node.to_key())
	hero.node = action.target_node
	state.heroes_by_node[target_key] = hero
	var remaining := int(state.hero_actions_remaining.get(hero.id, GameConstants.HERO_ACTIONS_PER_TURN))
	state.hero_actions_remaining[hero.id] = maxi(0, remaining - 1)
	var events: Array = [HeroMovedEvent.new(state.round_number, hero.id, from_node, action.target_node)]
	events.append_array(ContactResolutionRules.resolve_after_hero_enters(state, action.target_node, hero.id))
	return events


static func _apply_build_development(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	return DevelopmentRules.apply(state, player.id, action.vertex, action.development_id)


static func _apply_bank_trade(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return []
	return BankTradeRules.apply(
		state,
		player.id,
		action.give_resource,
		action.receive_resource
	)


static func _apply_trade_offer(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return []
	return TradeOfferRules.apply_offer(
		state,
		player.id,
		action.partner_player_id,
		action.give_resource,
		action.give_amount,
		action.receive_resource,
		action.request_amount
	)


static func _apply_trade_accept(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return []
	return TradeOfferRules.apply_accept(state, player.id, action.trade_offer_id)


static func _apply_trade_reject(state: GameState, action: GameAction) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return []
	return TradeOfferRules.apply_reject(state, player.id, action.trade_offer_id)


static func _apply_end_turn(state: GameState) -> Array:
	var player := TurnRules.get_active_player(state)
	var events: Array = [TurnEndedEvent.new(state.round_number, player.id)]
	TurnLifecycleRules.on_turn_end(state, player.id)
	events.append_array(SpreadRules.resolve_player_turn_end(state))

	state.active_player_index = (state.active_player_index + 1) % TurnRules.player_count(state)
	state.turn_number += 1
	events.append_array(TradeOfferRules.expire_stale_offers(state))

	if state.active_player_index == 0:
		state.round_number += 1
		events.append(RoundStartedEvent.new(state.round_number))
		TurnLifecycleRules.on_round_start(state)
		events.append_array(CityOccupationRules.evaluate_round_start_purges(state))
		DraftRules.begin_draft_step(state)
		SetupRules.rebuild_action_space(state)
		state.current_phase = TurnPhase.Phase.DRAFT_ROUND
	else:
		events.append_array(TurnLifecycleRules.on_turn_start(state))

	return events
