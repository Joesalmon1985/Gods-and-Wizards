class_name LegalActionQuery
extends RefCounted

static func get_view(state: GameState) -> LegalActionView:
	var view := LegalActionView.new(state.action_space)
	var active_player := TurnRules.get_active_player(state)

	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.DRAFT_PICK:
			view.legal_mask[action.action_id] = _is_draft_pick_legal(state, action)
		else:
			view.legal_mask[action.action_id] = _is_legal(state, active_player, action)

	return view


static func get_legal_actions_sorted(state: GameState) -> Array[GameAction]:
	var legal: Array[GameAction] = []
	var view := get_view(state)
	for action in state.action_space.all_actions_sorted():
		if view.legal_mask[action.action_id]:
			legal.append(action)
	return legal


static func _is_draft_pick_legal(state: GameState, action: GameAction) -> bool:
	if not state.awaiting_draft_step:
		return false
	if action.draft_player_id < 0:
		return false
	if state.draft_pending_picks.has(action.draft_player_id):
		return false
	return DraftRules._is_legal_pick(state, action.draft_player_id, action.development_id)


static func get_legal_draft_actions_for_player(state: GameState, player_id: int) -> Array[GameAction]:
	var legal: Array[GameAction] = []
	var view := get_view(state)
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.DRAFT_PICK:
			continue
		if action.draft_player_id != player_id:
			continue
		if view.legal_mask[action.action_id]:
			legal.append(action)
	return legal


static func _is_legal(state: GameState, active_player: Player, action: GameAction) -> bool:
	if state.awaiting_draft_step:
		return false
	if active_player == null:
		return false

	match action.kind:
		ActionKind.Kind.END_TURN:
			return true
		ActionKind.Kind.BUILD_CITY:
			if action.vertex == null:
				return false
			if not BuildCosts.can_afford(active_player, BuildCosts.BUILD_CITY):
				return false
			return BuildRules.can_build_city(state, active_player.id, action.vertex)
		ActionKind.Kind.BUILD_ROAD:
			if action.edge == null:
				return false
			if not BuildCosts.can_afford(active_player, BuildCosts.BUILD_ROAD):
				return false
			return BuildRules.can_build_road(state, active_player.id, action.edge)
		ActionKind.Kind.MOVE_HERO:
			var hero := MoveRules.get_hero(state, action.hero_id)
			return MoveRules.can_move_hero(state, active_player.id, hero, action.target_node)
		ActionKind.Kind.BUILD_DEVELOPMENT:
			if action.vertex == null:
				return false
			if not BuildCosts.can_afford(
				active_player,
				DevelopmentCatalog.build_cost_as_resources(action.development_id)
			):
				return false
			return DevelopmentRules.can_build(
				state,
				active_player.id,
				action.vertex,
				action.development_id
			)
		ActionKind.Kind.BANK_TRADE:
			return BankTradeRules.can_trade(
				state,
				active_player.id,
				action.give_resource,
				action.receive_resource
			)
		ActionKind.Kind.PLAYER_TRADE:
			return false
		ActionKind.Kind.TRADE_OFFER:
			return TradeOfferRules.can_offer(
				state,
				active_player.id,
				action.partner_player_id,
				action.give_resource,
				action.give_amount,
				action.receive_resource,
				action.request_amount
			)
		ActionKind.Kind.TRADE_ACCEPT:
			return TradeOfferRules.can_accept(state, active_player.id, action.trade_offer_id)
		ActionKind.Kind.TRADE_REJECT:
			return TradeOfferRules.can_reject(state, active_player.id, action.trade_offer_id)
		_:
			return false
