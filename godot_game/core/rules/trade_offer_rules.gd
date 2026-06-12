class_name TradeOfferRules
extends RefCounted

const MIN_AMOUNT := 1
const MAX_AMOUNT := 3
const MAX_OFFER_SLOTS := 32


static func can_offer(
	state: GameState,
	active_player_id: int,
	partner_player_id: int,
	give_resource: ResourceType.Type,
	give_amount: int,
	receive_resource: ResourceType.Type,
	receive_amount: int
) -> bool:
	if give_resource == receive_resource:
		return false
	if partner_player_id < 0 or partner_player_id == active_player_id:
		return false
	if give_amount < MIN_AMOUNT or give_amount > MAX_AMOUNT:
		return false
	if receive_amount < MIN_AMOUNT or receive_amount > MAX_AMOUNT:
		return false
	var active := _player(state, active_player_id)
	if active == null or _player(state, partner_player_id) == null:
		return false
	if active.get_resource(give_resource) < give_amount:
		return false
	var signature := _offer_signature(
		active_player_id,
		partner_player_id,
		give_resource,
		give_amount,
		receive_resource,
		receive_amount
	)
	return signature not in state.trade_offers_made_this_turn


static func apply_offer(
	state: GameState,
	active_player_id: int,
	partner_player_id: int,
	give_resource: ResourceType.Type,
	give_amount: int,
	receive_resource: ResourceType.Type,
	receive_amount: int
) -> Array:
	if not can_offer(
		state,
		active_player_id,
		partner_player_id,
		give_resource,
		give_amount,
		receive_resource,
		receive_amount
	):
		return []

	var offer := TradeOffer.new(
		state.next_trade_offer_id,
		active_player_id,
		partner_player_id,
		give_resource,
		give_amount,
		receive_resource,
		receive_amount
	)
	state.next_trade_offer_id += 1
	state.pending_trade_offers.append(offer)
	state.trade_offers_made_this_turn.append(
		_offer_signature(
			active_player_id,
			partner_player_id,
			give_resource,
			give_amount,
			receive_resource,
			receive_amount
		)
	)
	return [
		TradeOfferMadeEvent.new(
			state.round_number,
			offer.offer_id,
			active_player_id,
			partner_player_id,
			give_resource,
			give_amount,
			receive_resource,
			receive_amount
		),
	]


static func can_accept(state: GameState, active_player_id: int, offer_id: int) -> bool:
	var offer := _find_offer(state, offer_id)
	if offer == null or offer.to_player_id != active_player_id:
		return false
	var acceptor := _player(state, active_player_id)
	var offerer := _player(state, offer.from_player_id)
	if acceptor == null or offerer == null:
		return false
	return (
		acceptor.get_resource(offer.receive_resource) >= offer.receive_amount
		and offerer.get_resource(offer.give_resource) >= offer.give_amount
	)


static func apply_accept(state: GameState, active_player_id: int, offer_id: int) -> Array:
	if not can_accept(state, active_player_id, offer_id):
		return []
	var offer := _find_offer(state, offer_id)
	var acceptor := _player(state, active_player_id)
	var offerer := _player(state, offer.from_player_id)
	offerer.add_resource(offer.give_resource, -offer.give_amount)
	offerer.add_resource(offer.receive_resource, offer.receive_amount)
	acceptor.add_resource(offer.receive_resource, -offer.receive_amount)
	acceptor.add_resource(offer.give_resource, offer.give_amount)
	_remove_offer(state, offer_id)
	return [
		TradeAcceptedEvent.new(
			state.round_number,
			offer.offer_id,
			offer.from_player_id,
			offer.to_player_id,
			offer.give_resource,
			offer.give_amount,
			offer.receive_resource,
			offer.receive_amount
		),
	]


static func can_reject(state: GameState, active_player_id: int, offer_id: int) -> bool:
	var offer := _find_offer(state, offer_id)
	return offer != null and offer.to_player_id == active_player_id


static func apply_reject(state: GameState, active_player_id: int, offer_id: int) -> Array:
	if not can_reject(state, active_player_id, offer_id):
		return []
	var offer := _find_offer(state, offer_id)
	_remove_offer(state, offer_id)
	return [
		TradeRejectedEvent.new(
			state.round_number,
			offer.offer_id,
			offer.from_player_id,
			offer.to_player_id
		),
	]


static func clear_turn_trade_state(state: GameState) -> void:
	state.trade_offers_made_this_turn.clear()


static func _offer_signature(
	from_player_id: int,
	to_player_id: int,
	give_resource: ResourceType.Type,
	give_amount: int,
	receive_resource: ResourceType.Type,
	receive_amount: int
) -> String:
	return "%d->%d|%s:%d|%s:%d" % [
		from_player_id,
		to_player_id,
		ResourceType.to_key(give_resource),
		give_amount,
		ResourceType.to_key(receive_resource),
		receive_amount,
	]


static func _find_offer(state: GameState, offer_id: int) -> TradeOffer:
	for offer in state.pending_trade_offers:
		if offer.offer_id == offer_id:
			return offer
	return null


static func _remove_offer(state: GameState, offer_id: int) -> void:
	for i in range(state.pending_trade_offers.size()):
		var offer: TradeOffer = state.pending_trade_offers[i]
		if offer.offer_id == offer_id:
			state.pending_trade_offers.remove_at(i)
			return


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
